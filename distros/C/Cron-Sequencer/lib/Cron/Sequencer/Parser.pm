#!perl

use v5.20.0;
use warnings;

# The parts of this that we use have been stable and unchanged since v5.20.0:
use feature qw(postderef);
no warnings 'experimental::postderef';

package Cron::Sequencer::Parser;

our $VERSION = '0.02';

use Carp qw(croak confess);

require Algorithm::Cron;
use Try::Tiny;

my %aliases = (
    yearly => '0 0 1 1 *',
    annually => '0 0 1 1 *',
    monthly => '0 0 1 * *',
    weekly => '0 0 * * 0',
    daily => '0 0 * * *',
    midnight => '0 0 * * *',
    hourly => '0 * * * *',
);

# scalar -> filename
# ref to scalar -> contents
# hashref -> fancy

sub new {
    my ($class, $arg) = @_;
    confess('new() called as an instance method')
        if ref $class;

    my ($source, $crontab, $env, $ignore);
    if (!defined $arg) {
        croak(__PACKAGE__ . '->new($class, $arg)');
    } elsif (ref $arg eq 'SCALAR') {
        $source = "";
        $crontab = $arg;
    } elsif (ref $arg eq 'HASH') {
        $source = $arg->{source};
        $crontab = \$arg->{crontab}
            if exists $arg->{crontab};
        if (exists $arg->{env}) {
            for my $pair ($arg->{env}->@*) {
                # vixie crontab permits empty env variable names, so we should
                # too we don't need it *here*, but we could implement "unset"
                # syntax as FOO (ie no = sign)
                my ($name, $value) = $pair =~ /\A([^=]*)=(.*)\z/;
                croak("invalid environment variable assignment: '$pair'")
                    unless defined $value;
                $env->{$name} = $value;
            }
        }
        if (exists $arg->{ignore}) {
            for my $val (map {
                # Want to reach the croak if passed an empty string, so can't
                # just call split, as that returns an empty list for that input
                length $_ ? split /,/, $_ : $_
            } $arg->{ignore}->@*) {
                if ($val =~ /\A([1-9][0-9]*)-([1-9][0-9]*)\z/ && $2 >= $1) {
                    ++$ignore->{$_}
                        for $1 .. $2;
                } elsif ($val =~ /\A[1-9][0-9]*\z/) {
                    ++$ignore->{$val};
                } else {
                    croak("'ignore' must be a positive integer, not '$val'");
                }
            }
        }
    } elsif (ref $arg) {
        confess(sprintf 'Unsupported %s reference passed to new()', ref $arg);
    } elsif ($arg eq "") {
        croak("empty string is not a valid filename");
    } else {
        $source = $arg;
    }

    if (!$crontab) {
        croak("you must provide a source filename or crontab contents")
            unless length $source;
        open my $fh, '<', $source
            or croak("Can't open $source: $!");
        local $/;
        my $contents = <$fh>;
        unless(defined $contents && close $fh) {
            croak("Can't read $source: $!");
        }
        $crontab = \$contents;
    }

    # vixie crontab refuses a crontab where the last line is missing a newline
    # (but handles an empty file)
    unless ($$crontab =~ /(?:\A|\n)\z/) {
        $source = length $source ? " $source" : "";
        croak("crontab$source doesn't end with newline");
    }

    return bless _parser($crontab, $source, $env, $ignore), $class;
}

sub _parser {
    my ($crontab, $source, $default_env, $ignore) = @_;
    my $diag = length $source ? " of $source" : "";
    my ($lineno, %env, @actions);
    for my $line (split "\n", $$crontab) {
        ++$lineno;

        next
            if $ignore->{$lineno};

        # vixie crontab ignores leading tabs and spaces
        # See skip_comments() in misc.c
        # However the rest of the env parser uses isspace(), so will skip more
        # whitespace characters. I guess this is because the parser was
        # rewritten for version 4, and the more modern code can assume ANSI C.
        $line =~ s/\A[ \t]+//;

        next
            if $line =~ /\A(?:#|\z)/;

        # load_env() is attempted first
        # Its parser has some quirks, which I have attempted to faithfully copy:
        if ($line =~ /\A
                      (?:
                          # If ' opens, a second *must* be found to close
                          ' (*COMMIT) (?<name>[^=']*) '
                      |
                          " (*COMMIT) (?<name>[^="]*) "
                      |
                          # The C parser accepts empty variable names
                          (?<name>[^=\s\013]*)
                      )
                      [\s\013]* = [\s\013]*
                      (?:
                          # If ' opens, a second *must* be found to close
                          # *and* only trailing whitespace is permitted
                          ' (*COMMIT) (?<value>[^']*) '
                      |
                          " (*COMMIT) (?<value>[^"]*) "
                      |
                          # The C parser does not accept empty values
                          (?<value>.+?)
                      )
                      [\s\013]*
                      \z
                     /x) {
            $env{$+{name}} = $+{value};
        }
        # else it gets passed load_entry()
        elsif ($line =~ /\A\@reboot[\t ]/) {
            # We can't handle this, as we don't know when a reboot is
            next;
        } else {
            my ($time, $truetime, $command);
            if ($line =~ /\A\@([^\t ]+)[\t ]+(.*)\z/) {
                $command = $2;
                $time = '@' . $1;
                $truetime = $aliases{$1};
                croak("Unknown special string \@$1 at line $lineno$diag")
                    unless $truetime;
            } elsif ($line =~ /\A
                                (
                                    [*0-9]\S* [\t ]+
                                    [*0-9]\S* [\t ]+
                                    [*0-9]\S* [\t ]+
                                    \S+ [\t ]+
                                    \S+
                                )
                                [\t ]+
                                (
                                    # vixie cron explicitly forbids * here:
                                    [^*].*
                                )
                                \z
                              /x) {
                $command = $2;
                $time = $truetime = $1;
            } else {
                croak("Can't parse '$line' at line $lineno$diag");
            }

            my $whenever = try {
                 Algorithm::Cron->new(
                     base => 'utc',
                     crontab => $truetime,
                 );
             } catch {
                 croak("Can't parse time '$truetime' at line $lineno$diag: $_");
             };

            my %entry = (
                file => $source,
                lineno => $lineno,
                when => $time,
                command => $command,
                whenever => $whenever,
            );

            my (@unset, %set);
            for my $key (keys %$default_env) {
                push @unset, $key
                    unless defined $env{$key};
            }
            for my $key (keys %env) {
                $set{$key} = $env{$key}
                    unless defined $default_env->{$key} && $default_env->{$key} eq $env{$key};
            }
            $entry{unset} = [sort @unset]
                if @unset;
            $entry{env} = \%set
                if %set;

            push @actions, \%entry;
        }
    }
    return \@actions;
}

# "actions", "entries", "events"?
# Vixie crontab parses these with load_entry() and %ENV setting with load_env(),
# so we're refer to them as entries:
sub entries {
    my $self = shift;
    return @$self;
}

=head1 NAME

Cron::Sequencer::Parser

=head1 SYNOPSIS

    my $crontab = Cron::Sequencer::Parser->new("/path/to/crontab");

=head1 DESCRIPTION

This class parses a single crontab and converts it to a form that
C<Cron::Sequencer> can use.

=head1 METHODS

=head2 new

C<new> takes a single argument representing a crontab file to parse. Various
formats are supported:

=over 4

=item plain scalar

A file on disk

=item reference to a scalar

The contents of the crontab (as a single string of multiple lines)

=item reference to a hash

=over 4

=item crontab

The contents of a crontab, as a single string of multiple lines.
(Not a reference to a scalar containing this)

=item source

A file on disk. If both C<crontab> and C<source> are provided, then C<source>
is only used as the name of the crontab in output (and errors). No attempt is
made to read the file from disk.

=item env

Default values for environment variables set in the crontab, as a reference to
an array of strings in the form C<KEY=VALUE>. See below for examples.

=item ignore

Lines in the crontab to completely ignore, as an array of integers. These are
processed as the first step in the parser, so it's possible to ignore all of

=over 4

=item *

command entries (particularly "chatty" entries such as C<* * * * *>)

=item *

setting environment variables

=item *

lines with syntax errors that otherwise would abort the parse

=back

=back

This is the most flexible format. At least one of C<source> or C<crontab> must
be specified.

=back

The only way to provide C<env> or C<ignore> options is to pass a hashref.

=head2 entries

Returns a list of the crontab's command entries as data structures. Used
internally by C<Cron::Sequencer> and subject to change.

=head1 EXAMPLES

For this input

    POETS=Friday
    30 12 * * * lunch!

with default constructor options this code:

    use Cron::Sequencer;
    use Data::Dump;
    
    my $crontab = Cron::Sequencer->new({source => "reminder"});
    dd([$crontab->sequence(45000, 131400)]);

would generate this output:

    [
      [
        {
          command => "lunch!",
          env     => { POETS => "Friday" },
          file    => "reminder",
          lineno  => 2,
          time    => 45000,
          unset   => ["HUMP"],
          when    => "30 12 * * *",
        },
      ],
    ]

If we specify two environment variables:

    my $crontab = Cron::Sequencer->new({source => "reminder",
                                        env    => [
                                               "POETS=Friday",
                                               "HUMP=Wednesday"
                                           ]});

the output is:

    [
      [
        {
          command => "lunch!",
          env     => undef,
          file    => "reminder",
          lineno  => 2,
          time    => 45000,
          unset   => ["HUMP"],
          when    => "30 12 * * *",
        },
      ],
    ]

(because C<POETS> matches the default, but C<HUMP> was never set in the crontab)

If we ignore the first line:

    my $crontab = Cron::Sequencer->new({source => "reminder",
                                        ignore => [1]});

    [
      [
        {
          command => "lunch!",
          env     => undef,
          file    => "reminder",
          lineno  => 2,
          time    => 45000,
          unset   => undef,
          when    => "30 12 * * *",
        },
      ],
    ]

we ignore the line in the crontab that sets the environment variable.

For completeness, if we ignore the line that declares an event:

    my $crontab = Cron::Sequencer->new({source => "reminder",
                                        ignore => [2]});


there's nothing to output:

    []

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/cron-sequencer

=head1 AUTHOR

Nicholas Clark - C<nick@ccl4.org>

=cut

1;
