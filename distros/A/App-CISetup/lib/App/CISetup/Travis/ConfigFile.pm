package App::CISetup::Travis::ConfigFile;

use strict;
use warnings;
use namespace::autoclean;
use autodie qw( :all );

our $VERSION = '0.17';

use App::CISetup::Types qw( Bool File Str );
use File::pushd;
use File::Which qw( which );
use IPC::Run3 qw( run3 );
use List::AllUtils qw( first first_index uniq );
use Path::Iterator::Rule;
use Try::Tiny;
use YAML qw( Dump );

use Moose;
use MooseX::StrictConstructor;

has email_address => (
    is        => 'ro',
    isa       => Str,                   # todo, better type
    predicate => 'has_email_address',
);

has force_threaded_perls => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has perl_caching => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

has github_user => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_github_user',
);

has slack_key => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_slack_key',
);

with 'App::CISetup::Role::ConfigFile';

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _create_config {
    my $self = shift;

    return $self->_update_config( { language => 'perl' }, 1 );
}

sub _update_config {
    my $self   = shift;
    my $travis = shift;
    my $create = shift;

    $self->_maybe_update_travis_perl_usage( $travis, $create );
    $self->_maybe_remove_sudo($travis);
    $self->_update_packages($travis);
    $self->_update_coverity_email($travis);
    $self->_update_notifications($travis);

    return $travis;
}
## use critic

sub _maybe_update_travis_perl_usage {
    my $self   = shift;
    my $travis = shift;
    my $create = shift;

    return
        unless $create
        || ( $travis->{before_install}
        && grep {/perl-travis-helper|travis-perl/}
        @{ $travis->{before_install} } );

    $self->_maybe_add_cache_block($travis);
    $self->_fixup_helpers_usage($travis);
    $self->_rewrite_perl_block($travis);
    $self->_update_perl_matrix($travis);
    $self->_update_env_vars($travis);

    return;
}

sub _maybe_add_cache_block {
    my $self   = shift;
    my $travis = shift;

    return unless $self->perl_caching;
    return if exists $travis->{cache};

    $travis->{cache} = { directories => ['$HOME/perl5'] };

    return;
}

sub _fixup_helpers_usage {
    my $self   = shift;
    my $travis = shift;

    if (
        ( @{ $travis->{script} // [] } && @{ $travis->{script} } > 3 )
        || (
            $travis->{install}
            && ( grep { !/cpan-install/ } @{ $travis->{install} }
                || @{ $travis->{install} } > 2 )
        )
    ) {

        my $i = (
            first_index {/travis-perl|haarg/}
            @{ $travis->{before_install} }
        ) // 0;
        $travis->{before_install}->[$i]
            = 'git clone git://github.com/travis-perl/helpers ~/travis-perl-helpers';
        $travis->{before_install}->[ $i + 1 ]
            = 'source ~/travis-perl-helpers/init';
    }
    else {
        delete $travis->{install};
        delete $travis->{script};

        $travis->{before_install} //= [];
        my $i = first_index {/travis-perl|haarg/}
        @{ $travis->{before_install} };
        $i = 0 if $i < 0;

        my $auto = 'eval $(curl https://travis-perl.github.io/init) --auto';
        $auto .= ' --always-upgrade-modules' if $self->perl_caching;

        $travis->{before_install}[$i] = $auto;
        splice( @{ $travis->{before_install} }, $i + 1, 0 )
            if @{ $travis->{before_install} } > 1;
    }

    return;
}

my @Perls = qw(
    blead
    dev
    5.28
    5.26
    5.24
    5.22
    5.20
    5.18
    5.16
    5.14
    5.12
    5.10
    5.8
);

# XXX - if a build is intentionally excluding Perls besides 5.8 this will add
# those Perls back. Not sure how best to deal with this. We want to test on
# all Perls for most modules, and any manually generated file might forget to
# include some of them.
sub _rewrite_perl_block {
    my $self   = shift;
    my $travis = shift;

    my @perls = @Perls;
    for my $perl (qw( 5.8 5.10 5.12 )) {
        pop @perls
            unless grep {/\Q$perl/} @{ $travis->{perl} };
    }

    my $has_xs
        = defined Path::Iterator::Rule->new->file->name(qr/\.xs/)
        ->iter( $self->file->parent )->();

    if ( $self->force_threaded_perls || $has_xs ) {
        $travis->{perl} = [ map { ( $_, $_ . '-thr' ) } @perls ];
    }
    else {
        $travis->{perl} = \@perls;
    }

    return;
}

sub _update_perl_matrix {
    my $self   = shift;
    my $travis = shift;

    my @bleads = 'blead';
    push @bleads, 'blead-thr'
        if grep { $_ eq 'blead-thr' } @{ $travis->{perl} };

    my $latest  = first {/^5/} @Perls;
    my @include = @{ $travis->{matrix}{include} // [] };
    push @include, {
        perl => $latest,
        env  => 'COVERAGE=1',
        }
        unless grep { $_->{perl} eq $latest && $_->{env} eq 'COVERAGE=1' }
        @include;

    my @allow_failures = @{ $travis->{matrix}{allow_failures} // [] };
    for my $blead (@bleads) {
        push @allow_failures, { perl => $blead }
            unless grep { $_->{perl} eq $blead } @allow_failures;
    }

    $travis->{matrix} = {
        fast_finish    => 1,
        include        => \@include,
        allow_failures => \@allow_failures,
    };

    return;
}

sub _update_env_vars {
    my $self   = shift;
    my $travis = shift;

    $travis->{env} //= {};
    $travis->{env}{global} = [
        uniq(
            sort @{ $travis->{env}{global} // [] },
            qw(
                RELEASE_TESTING=1
                AUTHOR_TESTING=1
                ),
        )
    ];

    return;
}

sub _maybe_remove_sudo {
    my $self   = shift;
    my $travis = shift;

    delete $travis->{sudo};

    return;
}

sub _update_packages {
    my $self   = shift;
    my $travis = shift;

    my @addons
        = $travis->{addons}
        && $travis->{addons}{apt} && $travis->{addons}{apt}{packages}
        ? @{ $travis->{addons}{apt}{packages} }
        : ();
    push @addons, qw( aspell aspell-en )
        if $travis->{perl};
    $travis->{addons}{apt}{packages} = [ sort { $a cmp $b } uniq(@addons) ]
        if @addons;

    return;
}

sub _update_coverity_email {
    my $self   = shift;
    my $travis = shift;

    return unless $self->has_email_address;
    return unless $travis->{addons} && $travis->{addons}{coverity_scan};
    $travis->{addons}{coverity_scan}{notification_email}
        = $self->email_address;
}

sub _update_notifications {
    my $self   = shift;
    my $travis = shift;

    if ( $self->has_email_address ) {
        $travis->{notifications}{email} = {
            recipients => [ $self->email_address ],
            on_success => 'change',
            on_failure => 'always',
        };
    }

    if ( $self->has_slack_key && $self->has_github_user ) {
        my $slack = $travis->{notifications}{slack}{rooms}{secure};

        # travis encrypt will make a new encrypted version every time it's given
        # the same input so we don't want to run it unless we have to, otherwise
        # we end up with pointless updates.
        unless ($slack) {
            my $pushed = pushd( $self->file->parent );
            my $stdout;
            my $stderr;

            my $exe = which('travis')
                or die 'Cannot find a travis command in the PATH';
            $self->_run3(
                [
                    $exe, 'encrypt', '--no-interactive',
                    '-R',
                    $self->github_user . '/' . $self->file->parent->basename,
                    $self->slack_key
                ],
                \undef,
                \$stdout,
                \$stderr,
            );
            die $stderr if $stderr;
            $slack = $stdout =~ s/^\"|\"$//gr;
        }

        $travis->{notifications}{slack} = {
            rooms => { secure => $slack },
        };
    }

    return;
}

# This is broken out so we can replace it in test code.
sub _run3 {
    shift;
    run3(@_);
    return;
}

my @BlocksOrder = qw(
    sudo
    dist
    addons
    language
    compiler
    go
    jdk
    perl
    php
    python
    cache
    solution
    matrix
    fast_finish
    env
    branches
    services
    before_install
    install
    before_script
    script
    after_script
    after_success
    after_failure
    notifications
);

my %KnownBlocks = map { $_ => 1 } @BlocksOrder;

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _fix_up_yaml {
    my $self = shift;
    my $yaml = shift;

    $yaml =~ s/sudo: 0/sudo: false/g;

    return $self->_reorder_yaml_blocks( $yaml, \@BlocksOrder );
}

sub _reorder_addons_block {
    my $self  = shift;
    my $block = shift;

    return $block unless $block =~ /coverity_scan:\n(.+)(?=\S|\z)/ms;

    my %chunks;
    for my $line ( split /\n/, $1 ) {
        my ($name) = $line =~ / +([^:]+):/;
        $chunks{$name} = $line;
    }

    my $reordered = join q{}, map {"$chunks{$_}\n"}
        grep { $chunks{$_} }
        qw(
        project
        description
        name
        notification_email
        build_command_prepend
        build_command
        branch_pattern
    );

    return $block
        =~ s/coverity_scan:\n.+(?=\S|\z)/coverity_scan:\n$reordered/msr;
}

sub _cisetup_flags {
    my $self = shift;

    my %flags = (
        force_threaded_perls => $self->force_threaded_perls ? 1 : 0,
        perl_caching         => $self->perl_caching         ? 1 : 0,
    );

    $flags{email_address} = $self->email_address
        if $self->has_email_address;
    $flags{github_user} = $self->github_user
        if $self->has_github_user;

    return \%flags;
}
## use critic

__PACKAGE__->meta->make_immutable;

1;
