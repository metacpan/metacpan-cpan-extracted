package App::migrate;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;
## no critic (RequireCarping)

our $VERSION = 'v0.2.6';

use List::Util qw( first );
use File::Temp qw( tempfile ); # don't use Path::Tiny to have temp files in error $SHELL

use constant KW_DEFINE      => { map {$_=>1} qw( DEFINE DEFINE2 DEFINE4     ) };
use constant KW_VERSION     => { map {$_=>1} qw( VERSION                    ) };
use constant KW_UP          => { map {$_=>1} qw( before_upgrade upgrade     ) };
use constant KW_DOWN        => { map {$_=>1} qw( downgrade after_downgrade  ) };
use constant KW_RESTORE     => { map {$_=>1} qw( RESTORE                    ) };
use constant KW             => { %{&KW_UP}, %{&KW_DOWN}, %{&KW_DEFINE}, %{&KW_RESTORE}, %{&KW_VERSION} };
use constant DEFINE_TOKENS  => 1;
use constant DEFINE2_TOKENS => 2;
use constant DEFINE4_TOKENS => 4;


# cleanup temp files
$SIG{HUP} = $SIG{HUP}     // sub { exit 129 }; ## no critic (RequireLocalizedPunctuationVars ProhibitMagicNumbers)
$SIG{INT} = $SIG{INT}     // sub { exit 130 }; ## no critic (RequireLocalizedPunctuationVars ProhibitMagicNumbers)
$SIG{QUIT}= $SIG{QUIT}    // sub { exit 131 }; ## no critic (RequireLocalizedPunctuationVars ProhibitMagicNumbers)
$SIG{TERM}= $SIG{TERM}    // sub { exit 143 }; ## no critic (RequireLocalizedPunctuationVars ProhibitMagicNumbers)


sub new {
    my ($class) = @_;
    my $self = bless {
        paths   => {},  # {prev_version}{next_version} = \@steps
        on      => {
            BACKUP  => \&_on_backup,
            RESTORE => \&_on_restore,
            VERSION => \&_on_version,
            error   => \&_on_error,
        },
    }, ref $class || $class;
    return $self;
}

sub find_paths {
    my ($self, $from, $to) = @_;
    return $self->_find_paths($to, $from);
}

sub get_steps {
    my ($self, $path) = @_;
    my @path = @{ $path // [] };
    croak 'Path must contain at least 2 versions' if 2 > @path;
    my @all_steps;
    for (; 2 <= @path; shift @path) {
        my ($prev, $next) = @path;
        croak "Unknown version '$prev'" if !$self->{paths}{$prev};
        croak "No one-step migration from '$prev' to '$next'" if !$self->{paths}{$prev}{$next};
        push @all_steps, @{ $self->{paths}{$prev}{$next} };
    }
    return @all_steps;
}

sub load {
    my ($self, $file) = @_;

    open my $fh, '<:encoding(UTF-8)', $file or croak "open($file): $!";
    croak "'$file' is not a plain file" if !-f $file;
    my @op = _preprocess(_tokenize($fh, { file => $file, line => 0 }));
    close $fh or croak "close($file): $!";

    my ($prev_version, $next_version, @steps) = (q{}, q{});
    while (@op) {
        my $op = shift @op;
        if (KW_VERSION->{$op->{op}}) {
            $next_version = $op->{args}[0];
            if ($prev_version ne q{}) {
                $self->{paths}{ $prev_version }{ $next_version } ||= [
                    (grep { $_->{type} eq 'before_upgrade'  } @steps),
                    (grep { $_->{type} eq 'upgrade'         } @steps),
                    {
                        type            => 'VERSION',
                        version         => $next_version,
                    },
                ];
                my $restore = first { KW_RESTORE->{$_->{type}} } @steps;
                $self->{paths}{ $next_version }{ $prev_version } ||= [
                  $restore ? (
                    $restore,
                  ) : (
                    (grep { $_->{type} eq 'downgrade'       } reverse @steps),
                    (grep { $_->{type} eq 'after_downgrade' } reverse @steps),
                  ),
                    {
                        type            => 'VERSION',
                        version         => $prev_version,
                    },
                ];
                for (@{ $self->{paths}{ $prev_version }{ $next_version } }) {
                    $_->{prev_version} = $prev_version;
                    $_->{next_version} = $next_version;
                }
                for (@{ $self->{paths}{ $next_version }{ $prev_version } }) {
                    $_->{prev_version} = $next_version;
                    $_->{next_version} = $prev_version;
                }
            }
            ($prev_version, $next_version, @steps) = ($next_version, q{});
        }
        elsif (KW_UP->{$op->{op}}) {
            die _e($op, "Need 'VERSION' before '$op->{op}'") if $prev_version eq q{};
            my ($cmd1, @args1) = @{ $op->{args} };
            push @steps, {
                type            => $op->{op},
                cmd             => $cmd1,
                args            => \@args1,
            };
            die _e($op, "Need 'RESTORE' or 'downgrade' or 'after_downgrade' after '$op->{op}'")
                if !( @op && (KW_DOWN->{$op[0]{op}} || KW_RESTORE->{$op[0]{op}}) );
            my $op2 = shift @op;
            if (KW_RESTORE->{$op2->{op}}) {
                push @steps, {
                    type            => 'RESTORE',
                    version         => $prev_version,
                };
            }
            else {
                my ($cmd2, @args2) = @{ $op2->{args} };
                push @steps, {
                    type            => $op2->{op},
                    cmd             => $cmd2,
                    args            => \@args2,
                };
            }
        }
        else {
            die _e($op, "Need 'before_upgrade' or 'upgrade' before '$op->{op}'");
        }
    }

    return $self;
}

sub on {
    my ($self, $e, $code) = @_;
    croak "Unknown event $e" if !$self->{on}{$e};
    $self->{on}{$e} = $code;
    return $self;
}

sub run {
    my ($self, $path) = @_;
    $self->get_steps($path);  # validate full @path before starting
    my @path = @{ $path };
    my $from;
    eval {
        my $just_restored = 0;
        for (; 2 <= @path; shift @path) {
            my ($prev, $next) = @path;
            if (!$just_restored) {
                $self->_do({
                    type            => 'BACKUP',    # internal step type
                    version         => $prev,
                    prev_version    => $prev,
                    next_version    => $next,
                });
            }
            $just_restored = 0;
            $from = $prev;
            for my $step ($self->get_steps([$prev, $next])) {
                $self->_do($step);
                if ($step->{type} eq 'RESTORE') {
                    $just_restored = 1;
                }
            }
        }
        1;
    }
    or do {
        my $err = $@;
        if ($from) {
            eval {
                $self->_do({
                    type            => 'RESTORE',   # internal step type
                    version         => $from,
                    prev_version    => $from,
                    next_version    => $path[-1],
                }, 1);
                warn "Successfully undone interrupted migration by RESTORE $from\n";
                1;
            } or warn "Failed to RESTORE $from: $@";
        }
        die $err;
    };
    return;
}

sub _data2arg {
    my ($data) = @_;

    return if $data eq q{};

    my ($fh, $file) = tempfile('migrate.XXXXXX', TMPDIR=>1, UNLINK=>1);
    print {$fh} $data;
    close $fh or croak "close($file): $!";

    return $file;
}

sub _do {
    my ($self, $step, $is_fatal) = @_;
    local $ENV{MIGRATE_PREV_VERSION} = $step->{prev_version};
    local $ENV{MIGRATE_NEXT_VERSION} = $step->{next_version};
    eval {
        if ($step->{type} eq 'BACKUP' or $step->{type} eq 'RESTORE' or $step->{type} eq 'VERSION') {
            $self->{on}{ $step->{type} }->($step);
        }
        else {
            my $cmd = $step->{cmd};
            if ($cmd =~ /\A#!/ms) {
                $cmd = _data2arg($cmd);
                chmod 0700, $cmd or croak "chmod($cmd): $!";    ## no critic (ProhibitMagicNumbers)
            }
            system($cmd, @{ $step->{args} }) == 0 or die "'$step->{type}' failed: $cmd @{ $step->{args} }\n";
            print "\n";
        }
        1;
    }
    or do {
        die $@ if $is_fatal;
        warn $@;
        $self->{on}{error}->($step);
    };
    return;
}

sub _e {
    my ($t, $msg, $near) = @_;
    return "parse error: $msg at $t->{loc}{file}:$t->{loc}{line}"
      . (length $near ? " near '$near'\n" : "\n");
}

sub _find_paths {
    my ($self, $to, @from) = @_;
    my $p = $self->{paths}{ $from[-1] } || {};
    return [@from, $to] if $p->{$to};
    my %seen = map {$_=>1} @from;
    return map {$self->_find_paths($to,@from,$_)} grep {!$seen{$_}} keys %{$p};
}

sub _on_backup {
    croak 'You need to define how to make BACKUP';
}

sub _on_restore {
    croak 'You need to define how to RESTORE from backup';
}

sub _on_version {
    # do nothing
}

sub _on_error {
    warn <<'ERROR';

YOU NEED TO MANUALLY FIX THIS ISSUE RIGHT NOW
When done, use:
   exit        to continue migration
   exit 1      to interrupt migration and RESTORE from backup

ERROR
    system($ENV{SHELL} // '/bin/sh') == 0 or die "Migration interrupted\n";
    return;
}

sub _preprocess { ## no critic (ProhibitExcessComplexity)
    my @tokens = @_;
    my @op;
    my %macro;
    while (@tokens) {
        my $t = shift @tokens;
        if ($t->{op} =~ /\ADEFINE[24]?\z/ms) {
            die _e($t, "'$t->{op}' must have one param", "@{$t->{args}}") if 1 != @{$t->{args}};
            die _e($t, "Bad name for '$t->{op}'", $t->{args}[0]) if $t->{args}[0] !~ /\A(?!#)\S+\z/ms;
            die _e($t, "No data allowed for '$t->{op}'", $t->{data}) if $t->{data} ne q{};
            my $name = $t->{args}[0];
            die _e($t, "Can't redefine keyword '$name'") if KW->{$name};
            die _e($t, "'$name' is already defined") if $macro{$name};
            if ($t->{op} eq 'DEFINE') {
                die _e($t, q{Need operation after 'DEFINE'}) if @tokens < DEFINE_TOKENS;
                my $t1 = shift @tokens;
                die _e($t1, q{First operation after 'DEFINE' must be 'before_upgrade' or 'upgrade' or 'downgrade' or 'after_downgrade'}, $t1->{op}) if !( KW_UP->{$t1->{op}} || KW_DOWN->{$t1->{op}} );
                $macro{$name} = [ $t1 ];
            }
            elsif ($t->{op} eq 'DEFINE2') {
                die _e($t, q{Need two operations after 'DEFINE2'}) if @tokens < DEFINE2_TOKENS;
                my $t1 = shift @tokens;
                my $t2 = shift @tokens;
                die _e($t1,  q{First operation after 'DEFINE2' must be 'before_upgrade' or 'upgrade'},      $t1->{op}) if !KW_UP->{$t1->{op}};
                die _e($t2, q{Second operation after 'DEFINE2' must be 'downgrade' or 'after_downgrade'},   $t2->{op}) if !KW_DOWN->{$t2->{op}};
                $macro{$name} = [ $t1, $t2 ];
            }
            elsif ($t->{op} eq 'DEFINE4') {
                die _e($t, q{Need four operations after 'DEFINE4'}) if @tokens < DEFINE4_TOKENS;
                my $t1 = shift @tokens;
                my $t2 = shift @tokens;
                my $t3 = shift @tokens;
                my $t4 = shift @tokens;
                die _e($t1,  q{First operation after 'DEFINE4' must be 'before_upgrade'},  $t1->{op}) if $t1->{op} ne 'before_upgrade';
                die _e($t2, q{Second operation after 'DEFINE4' must be 'upgrade'},         $t2->{op}) if $t2->{op} ne 'upgrade';
                die _e($t3,  q{Third operation after 'DEFINE4' must be 'downgrade'},       $t3->{op}) if $t3->{op} ne 'downgrade';
                die _e($t4, q{Fourth operation after 'DEFINE4' must be 'after_downgrade'}, $t4->{op}) if $t4->{op} ne 'after_downgrade';
                $macro{$name} = [ $t1, $t4, $t2, $t3 ];
            }
        }
        elsif (KW_VERSION->{$t->{op}}) {
            die _e($t, q{'VERSION' must have one param}, "@{$t->{args}}") if 1 != @{$t->{args}};
            die _e($t, q{Bad value for 'VERSION'}, $t->{args}[0])
                if $t->{args}[0] !~ /\A\S+\z/ms || $t->{args}[0] =~ /[\x00-\x1F\x7F \/?*`"'\\]/ms;
            die _e($t, q{No data allowed for 'VERSION'}, $t->{data}) if $t->{data} ne q{};
            push @op, {
                loc     => $t->{loc},
                op      => $t->{op},
                args    => [ $t->{args}[0] ],
            };
        }
        elsif (KW_RESTORE->{$t->{op}}) {
            die _e($t, q{'RESTORE' must have no params}, "@{$t->{args}}") if 0 != @{$t->{args}};
            die _e($t, q{No data allowed for 'RESTORE'}, $t->{data}) if $t->{data} ne q{};
            push @op, {
                loc     => $t->{loc},
                op      => $t->{op},
                args    => [],
            };
        }
        elsif (KW_UP->{$t->{op}} || KW_DOWN->{$t->{op}}) {
            die _e($t, "'$t->{op}' require command or data") if !@{$t->{args}} && $t->{data} !~ /\S/ms;
            push @op, {
                loc     => $t->{loc},
                op      => $t->{op},
                args    => [
                    @{$t->{args}}           ? (@{$t->{args}}, _data2arg($t->{data}))
                  :                           _shebang($t->{data})
                ],
            };
        }
        elsif ($macro{ $t->{op} }) {
            for (@{ $macro{ $t->{op} } }) {
                my @args
                  = @{$_->{args}}           ? (@{$_->{args}}, _data2arg($_->{data}))
                  : $_->{data} =~ /\S/ms    ? _shebang($_->{data})
                  :                           ()
                  ;
                @args
                  = @args                   ? (@args, @{$t->{args}}, _data2arg($t->{data}))
                  : @{$t->{args}}           ? (@{$t->{args}}, _data2arg($t->{data}))
                  : $t->{data} =~ /\S/ms    ? _shebang($t->{data})
                  :                           ()
                  ;
                die _e($t, "'$t->{op}' require command or data") if !@args;
                push @op, {
                    loc     => $t->{loc},
                    op      => $_->{op},
                    args    => \@args,
                };
            }
        }
        else {
            die _e($t, "Unknown operation '$t->{op}'");
        }
    }
    return @op;
}

sub _shebang {
    my ($script) = @_;
    state $bin = (grep { -x "$_/bash" } split /:/ms, $ENV{PATH})[0] or die 'bash not found';
    return $script =~ /\A#!/ms ? $script : "#!$bin/bash -ex\n$script";
}

sub _tokenize {
    my ($fh, $loc) = @_;
    state $QUOTED = {
        q{\\}   => q{\\},
        q{"}    => q{\"},
        'n'     => "\n",
        'r'     => "\r",
        't'     => "\t",
    };
    my @tokens;
    while (<$fh>) {
        $loc->{line}++;
        if (/\A#/ms) {
            # skip comments
        }
        elsif (/\A(\S+)\s*(.*)\z/ms) {
            # parse token's op and args
            my ($op, $args) = ($1, $2);
            my @args;
            while ($args =~ /\G([^\s"\\]+|"[^"\\]*(?:\\[\\"nrt][^"\\]*)*")(?:\s+|\z)/msgc) {
                my $param = $1;
                if ($param =~ s/\A"(.*)"\z/$1/ms) {
                    $param =~ s/\\([\\"nrt])/$QUOTED->{$1}/msg;
                }
                push @args, $param;
            }
            die _e({loc=>$loc}, 'Bad operation param', $1) if $args =~ /\G(.+)\z/msgc; ## no critic (ProhibitCaptureWithoutTest)
            push @tokens, {
                loc => {%{ $loc }},
                op  => $op,
                args=> \@args,
                data=> q{},
            };
        }
        elsif (/\A(?:\r?\n|[ ][ ].*)\z/ms) {
            if (@tokens) {
                $tokens[-1]{data} .= $_;
            }
            elsif (/\S/ms) {
                die _e({loc=>$loc}, 'Data before operation', $_);
            }
            else {
                # skip /^\s*$/ before first token
            }
        }
        else {
            die _e({loc=>$loc}, 'Bad token', $_);
        }
    }
    # post-process data
    for (@tokens) {
        $_->{data} =~ s/(\A(?:.*?\n)??)(?:\r?\n)*\z/$1/ms;
        $_->{data} =~ s/^[ ][ ]//msg;
    }
    return @tokens;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=begin markdown

[![Build Status](https://travis-ci.org/powerman/migrate.svg?branch=master)](https://travis-ci.org/powerman/migrate)
[![Coverage Status](https://coveralls.io/repos/powerman/migrate/badge.svg?branch=master)](https://coveralls.io/r/powerman/migrate?branch=master)
[![Docker Automated Build](https://img.shields.io/docker/automated/powerman/migrate.svg)](https://github.com/powerman/migrate)
[![Docker Build Status](https://img.shields.io/docker/build/powerman/migrate.svg)](https://hub.docker.com/r/powerman/migrate/)

=end markdown

=head1 NAME

App::migrate - upgrade / downgrade project


=head1 VERSION

This document describes App::migrate version v0.2.6


=head1 SYNOPSIS

    use App::migrate;

    my $migrate = App::migrate->new()
    $migrate = $migrate->load($file)

    @paths   = $migrate->find_paths($v_from => $v_to)
    say "versions: @{$_}" for @paths;

    @steps   = $migrate->get_steps($paths[0])
    for (@steps) {
      say "$_->{prev_version} ... $_->{next_version}";
      if ($_->{type} eq 'VERSION' or $_->{type} eq 'RESTORE') {
          say "$_->{type} $_->{version}";
      } else {
          say "$_->{type} $_->{cmd} @{$_->{args}}";
      }
    }

    $migrate = $migrate->on(BACKUP  => sub{ my $step=shift; return or die });
    $migrate = $migrate->on(RESTORE => sub{ my $step=shift; return or die });
    $migrate = $migrate->on(VERSION => sub{ my $step=shift; return or die });
    $migrate = $migrate->on(error   => sub{ my $step=shift; return or die });
    $migrate->run($paths[0]);


=head1 DESCRIPTION

If you're looking for command-line tool - see L<migrate>. This module is
actual implementation of that tool's functionality and you'll need it only
if you're developing similar tool (like L<narada-install>) to implement
specifics of your project in single perl script instead of using several
external scripts.

This module implements file format (see L</"SYNTAX">) to describe sequence
of upgrade and downgrade operations needed to migrate I<something> between
different versions, and API to analyse and run these operations.

The I<something> mentioned above is usually some project, but it can be
literally anything - OS configuration in /etc, or overall OS setup
including installed packages, etc. - anything what has versions and need
complex operations to upgrade/downgrade between these versions.
For example, to migrate source code you can use VCS like Git or Mercurial,
but they didn't support empty directories, file permissions (except
executable), non-plain file types (FIFO, UNIX socket, etc.), xattr, ACL,
configuration files which must differ on each site, and databases. So, if
you need to migrate anything isn't supported by VCS - you can try this
module/tool.

Sometimes it isn't possible to really downgrade because some data was lost
while upgrade - to handle these situations you should provide a ways to
create complete backup of your project and restore any project's version
from these backups while downgrade (of course, restoring backups will
result in losing new changes, so whenever possible it's better to do some
extra work to provide a way to downgrade without losing any data).

=head2 Example

Here is example how to run migration from version '1.1.8' to '1.2.3' of
some project which uses even minor versions '1.0.x' and '1.2.x' for stable
releases and odd minor versions '1.1.x' for unstable releases. The nearest
common version between '1.1.8' and '1.2.3' is '1.0.42', which was the
parent for both '1.1.x' and '1.2.x' branches, so we need to downgrade
project from '1.1.8' to '1.0.42' first, and then upgrade from '1.0.42' to
'1.2.3'. You'll need two C<*.migrate> files, one which describe migrations
from '1.0.42' (or earlier version) to '1.1.8', and another with migrations
from '1.0.42' (or earlier) to '1.2.3'. For brevity let's not make any
backups while migration.

    my $migrate = App::migrate
        ->new
        ->load('1.1.8.migrate')
        ->load('1.2.3.migrate');
    $migrate
        ->on(BACKUP => sub {})
        ->run( $migrate->find_paths('1.1.8' => '1.2.3') );


=head1 INTERFACE

=head2 new

    $migrate = App::migrate->new;

Create and return new App::migrate object.

=head2 load

    $migrate->load('path/to/migrate');

Load migration commands into C<$migrate> object.

You should load at least one file with migration commands before you can
use L</"find_paths">, L</"get_steps"> or L</"run">.

When loading multiple files, if they contain two adjoining 'VERSION'
operations with same version values then migration commands between these
two version values will be used from first loaded file containing these
version values.

Will throw if given file's contents don't conform to L</"Specification"> -
this may be used to check file's syntax.

=head2 find_paths

    @paths = $migrate->find_paths($from_version => $to_version);

Find and return all possible paths to migrate between given versions.

If no paths found - return empty list. This may happens because you didn't
loaded migrate files which contain required migrations or because there is
no way to migrate between these versions (for example, if one of given
versions is incorrect).

Multiple paths can be found, for example, when your project had some
branches which was later merged.

Each found path returned as single ARRAYREF element in returned list.
This ARRAYREF contains list of all intermediate versions, one by one,
starting from C<$from_version> and ending with C<$to_version>.

For example, if our project have this version history:

        1.0.0
          |
        1.0.42
         / \
    1.1.0   1.2.0
      |       |
    1.1.8   1.2.3
      | \     |
      |  \----|
    1.1.9   1.2.4
      |       |
    1.1.10  1.2.5

then you'll probably have these migrate files:

    1.1.10.migrate          1.0.0->…->1.0.42->1.1.0->…->1.1.10
    1.2.5.migrate           1.0.0->…->1.0.42->1.2.0->…->1.2.3->1.2.4->1.2.5
    1.1.8-1.2.4.migrate     1.0.0->…->1.0.42->1.1.0->…->1.1.8->1.2.4

If you L</"load"> files C<1.2.5.migrate> and C<1.1.8-1.2.4.migrate> and
then call C<< find_paths('1.0.42' => '1.2.5') >>, then it will return
this list with two paths (in any order):

    (
        ['1.0.42', '1.1.0', …, '1.1.8', '1.2.4', '1.2.5'],
        ['1.0.42', '1.2.0', …, '1.2.3', '1.2.4', '1.2.5'],
    )

=head2 get_steps

    @steps = $migrate->get_steps( \@versions );

Return list of all migration operations needed to migrate on path given in
C<@versions>.

For example, to get steps for first path returned by L</"find_paths">:

    @steps = $migrate->get_steps( $migrate->find_paths($from=>$to) );

Steps returned in order they'll be executed while L</"run"> for this path.
Each element in C<@steps> is a HASHREF with these keys:

    type    => one of these values:
                'VERSION', 'before_upgrade', 'upgrade',
                'downgrade', 'after_downgrade', 'RESTORE'

    # these keys exists only if value of type key is one of:
    #   VERSION, RESTORE
    version => version number

    # these keys exists only if value of type key is one of:
    #   before_upgrade, upgrade, downgrade, after_downgrade
    cmd     => command to run
    args    => ARRAYREF of params for that command

Will throw if unable to return requested steps.

=head2 on

    $migrate = $migrate->on(BACKUP  => \&your_handler);
    $migrate = $migrate->on(RESTORE => \&your_handler);
    $migrate = $migrate->on(VERSION => \&your_handler);
    $migrate = $migrate->on(error   => \&your_handler);

Set handler for given event.

All handlers will be called only by L</"run">; they will get single
parameter - step HASHREF (BACKUP handler will get step in same format as
RESTORE), see L</"get_steps"> for details of that HASHREF contents.
Also these handlers may use C<$ENV{MIGRATE_PREV_VERSION}> and
C<$ENV{MIGRATE_NEXT_VERSION}> - see L</"run"> for more details.

=over

=item 'BACKUP' event

Handler will be executed when project backup should be created: before
starting any new migration, except next one after RESTORE.

If handler throws then 'error' handler will be executed.

Default handler will throw (because it doesn't know how to backup your
project).

NOTE: If you'll use handler which doesn't really create and keep backups
for all versions then it will be impossible to do RESTORE operation.

=item 'RESTORE' event

Handler will be executed when project should be restored from backup: when
downgrading between versions which contain RESTORE operation or when
migration fails.

If handler throws then 'error' handler will be executed.

Default handler will throw (because it doesn't know how to restore your
project).

=item 'VERSION' event

Handler will be executed after each successful migration.

If handler throws then 'error' handler will be executed.

Default handler does nothing.

=item 'error' event

Handler will be executed when one of commands executed while migration
fails or when BACKUP, RESTORE or VERSION handlers throw.

If handler throws then try to restore version-before-migration (without
calling error handler again if it throws too).

Default handler will run $SHELL (to let you manually fix errors) and throw
if you $SHELL exit status != 0 (to let you choose what to do next -
continue migration if you fixed error or interrupt migration to restore
version-before-migration from backup).

=back

=head2 run

    $migrate->run( \@versions );

Will use L</"get_steps"> to get steps for path given in C<@versions> and
execute them in order. Will also call handlers as described in L</"on">.

Before executing each step will set C<$ENV{MIGRATE_PREV_VERSION}> to
current version (which it will migrate from) and
C<$ENV{MIGRATE_NEXT_VERSION}> to version it is trying to migrate to.


=head1 SYNTAX

=head2 Goals

Syntax of this file was designed to accomplish several goals:

=over

=item *

Be able to automatically make sure each 'upgrade' operation has
corresponding 'downgrade' operation (so it won't be forget - but, of
course, it's impossible to automatically check is 'downgrade' operation
will correctly undo effect of 'upgrade' operation).

I<Thus custom file format is needed.>

=item *

Make it easier to manually analyse is 'downgrade' operation looks correct
for corresponding 'upgrade' operation.

I<Thus related 'upgrade' and 'downgrade' operations must go one right
after another.>

=item *

Make it obvious some version can't be downgraded and have to be restored
from backup.

I<Thus RESTORE operation is named in upper case.>

=item *

Given all these requirements try to make it simple and obvious to define
migrate operations, without needs to write downgrade code for typical
cases.

I<Thus it's possible to define macro to turn combination of
upgrade/downgrade operations into one user-defined operation (no worries
here: these macro doesn't support recursion, it isn't possible to redefine
them, and they have lexical scope - from definition to the end of this
file - so they won't really add complexity).>

=back

=head2 Example

    VERSION 0.0.0
    # To upgrade from 0.0.0 to 0.1.0 we need to create new empty file and
    # empty directory.
    upgrade     touch   empty_file
    downgrade   rm      empty_file
    upgrade     mkdir   empty_dir
    downgrade   rmdir   empty_dir
    VERSION 0.1.0
    # To upgrade from 0.1.0 to 0.2.0 we need to drop old database. This
    # change can't be undone, so only way to downgrade from 0.2.0 is to
    # restore 0.1.0 from backup.
    upgrade     rm      useless.db
    RESTORE
    VERSION 0.2.0
    # To upgrade from 0.2.0 to 1.0.0 we need to run several commands,
    # and after downgrading we need to kill some background service.
    before_upgrade
      patch    <0.2.0.patch >/dev/null
      chmod +x some_daemon
    downgrade
      patch -R <0.2.0.patch >/dev/null
    upgrade
      ./some_daemon &
    after_downgrade
      killall -9 some_daemon
    VERSION 1.0.0

    # Let's define some lazy helpers:
    DEFINE2 only_upgrade
    upgrade
    downgrade true

    DEFINE2 mkdir
    upgrade
      mkdir "$@"
    downgrade
      rm -rf "$@"

    # ... and use it:
    only_upgrade
      echo "Just upgraded to $MIGRATE_NEXT_VERSION"

    VERSION 1.0.1

    # another lazy macro (must be defined above in same file)
    mkdir dir1 dir2

    VERSION 1.1.0

=head2 Specification

Recommended name for file with upgrade/downgrade operations is either
C<migrate> or C<< <version>.migrate >>.

Each line in migrate file must be one of these:

=over

=item * line start with symbol "#"

For comments. Line is ignored.

=item * line start with any non-space symbol, except "#"

Contain one or more elements separated by one or more space symbols:
operation name (case-sensitive), zero or more params (any param may be
quoted, params which contain one of 5 symbols "\\\"\t\r\n" must be
quoted).

Quoted params must be surrounded by double-quote symbol, and any of
mentioned above 5 symbols must be escaped like shown above.

=item * line start with two spaces

Zero or more such lines after line with operation name form one more,
multiline, extra param for that operation (first two spaces will be
removed from start of each line before providing this param to operation).

Not all operations may have such multiline param.

=item * empty line

If this line is between operations then it's ignored.

If this line is inside operation's multiline param - then that multiline
param will include this empty line.

If you will need to include empty line at end of multiline param then
you'll have to use line with two spaces instead.

=back

While executing any commands two environment variables will be set:
C<$MIGRATE_PREV_VERSION> and C<$MIGRATE_NEXT_VERSION> (first is always
version we're migrating from, and second is always version we're migrating
to - i.e. while downgrading C<$MIGRATE_NEXT_VERSION> will be lower/older
version than C<$MIGRATE_PREV_VERSION>)

All executed commands must complete without error, otherwise emergency
shell will be started and user should either fix the error and C<exit>
from shell to continue migration, or C<exit 1> from shell to interrupt
migration and restore previous-before-this-migration version from backup.

=head2 Supported operations

=head3 VERSION

Must have exactly one param (version number). Some symbols are not allowed
in version numbers: special (0x00-0x1F,0x7F), both slash, all three
quotes, ?, * and space.

Multiline param not supported.

This is delimiter between sequences of migrate operations.

Each file must contain 'VERSION' operation before any migrate operations
(i.e. before first 'VERSION' operation only 'DEFINE', 'DEFINE2' and
'DEFINE4' operations are allowed).

All operations after last 'VERSION' operation will be ignored.

=head3 before_upgrade

=head3 upgrade

=head3 downgrade

=head3 after_downgrade

These operations must be always used in pairs: first must be one of
'before_upgrade' or 'upgrade' operation, second must be one of 'downgrade'
or 'after_downgrade' or 'RESTORE' operations.

These four operations may have zero or more params and optional multiline
param. If they won't have any params at all they'll be processed like they
have one (empty) multiline param.

Their params will be executed as a single shell command at different
stages of migration process and in different order:

=over

=item *

On each migration only commands between two nearest VERSION operations
will be processed.

=item *

On upgrading (migrate forward from previous VERSION to next VERSION) will
be executed all 'before_upgrade' operations in forward order then all
'upgrade' operations in forward order.

=item *

On downgrading (migrate backward from next VERSION to previous) will be
executed all 'downgrade' operations in backward order, then all
'after_downgrade' operations in backward order.

=back

Shell command to use will be:

=over

=item *

If operation has one or more params - first param will become executed
command name, other params will become command params.

If operation also has multiline param then it content will be saved into
temporary file and name of that file will be added at end of command's
params.

=item *

Else multiline param will be saved into temporary file (after shebang
C<#!/path/to/bash -ex> if first line of multiline param doesn't start with
C<#!>), which will be made executable and run without any params.

=back

=head3 RESTORE

Doesn't support any params, neither usual nor multiline.

Can be used only after 'before_upgrade' or 'upgrade' operations.

When one or more 'RESTORE' operations are used between some 'VERSION'
operations then all 'downgrade' and 'after_downgrade' operations between
same 'VERSION' operations will be ignored and on downgrading previous
version will be restored from backup.

=head3 DEFINE

This operation must have only one non-multiline param - name of defined
macro. This name must not be same as one of existing operation names, both
documented here or created by one of previous 'DEFINE' or 'DEFINE2' or
'DEFINE4' operations.

Next operation must be one of 'before_upgrade', 'upgrade', 'downgrade' or
'after_downgrade' - it will be substituted in place of all next operations
matching name of this macro.

When substituting macro it may happens what both this macro definition
have some normal params and multiline param, and substituted operation
also have some it's own normal params and multiline param. All these
params will be combined into single command and it params in this way:

=over

=item *

If macro definition doesn't have any params - params of substituted
operation will be handled as usually for 'upgrade' etc. operations.

=item *

If macro definition have some params - they will be handled as usually for
'upgrade' etc. operations, so we'll always get some command and optional
params for it.

Next, all normal params of substituted command (if any) will be appended
to that command params.

Next, if substituted command have multiline param then it will be saved to
temporary file and name of that file will be appended to that command
params.

=back

=head3 DEFINE2

Work similar to DEFINE, but require two next operations after it: first
must be one of 'before_upgrade' or 'upgrade', and second must be one of
'downgrade' or 'after_downgrade'.

Params of both operations will be combined with params of substituted
operation as explained above.

=head3 DEFINE4

Work similar to DEFINE, but require four next operations after it: first
must be 'before_upgrade', second - 'upgrade', third - 'downgrade', fourth
- 'after_downgrade'.

Params of all four operations will be combined with params of substituted
operation as explained above.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/migrate/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/migrate>

    git clone https://github.com/powerman/migrate.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=App-migrate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/App-migrate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-migrate>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=App-migrate>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/App-migrate>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
