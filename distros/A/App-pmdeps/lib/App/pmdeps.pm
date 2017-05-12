package App::pmdeps;
use strict;
use warnings;
use utf8;
use Carp;
use File::Spec::Functions qw/catfile rel2abs/;
use Furl;
use Getopt::Long qw/:config posix_default no_ignore_case bundling auto_help/;
use JSON;
use Module::CoreList;
use Term::ANSIColor qw/colored/;

our $VERSION = "0.02";

$ENV{ANSI_COLORS_DISABLED} = 1 if $^O eq 'MSWin32';

use constant METACPAN_API_URL => 'http://api.metacpan.org/v0/release/_search';

sub new {
    my ($class) = @_;
    bless { timeout => 10, }, $class;
}

sub run {
    my ( $self, @args ) = @_;

    local @ARGV = @args;
    GetOptions(
        't|timeout=i'      => \$self->{timeout},
        'p|perl-version=f' => \$self->{perl_version},
        'l|local=s',       => \$self->{local},
        'without-phase=s@' => \$self->{without_phase},
        'without-type=s@'  => \$self->{without_type},
        'h|help!'          => \$self->{usage},
        'v|version!'       => \$self->{version},
    ) or $self->show_usage;

    $self->show_version if $self->{version};
    $self->show_usage   if $self->{usage};

    if ($self->{without_phase}) {
        @{$self->{without_phase}} = split( /,/, join(',', @{$self->{without_phase}}) );
    }

    if ($self->{without_type}) {
        @{$self->{without_type}} = split( /,/, join(',', @{$self->{without_type}}) );
    }

    $self->show_short_usage unless ( @ARGV || $self->{local} );

    $self->{perl_version} ||= $];
    $self->show_dependencies(@ARGV);
}

sub show_dependencies {
    my ( $self, @args ) = @_;

    my $deps;
    if ( $self->{local} ) {
        $deps = $self->_fetch_deps_from_metadata( $self->{local} );
    }
    else {
        $deps = $self->_fetch_deps_from_metacpan( { name => $args[0], version => $args[1] } );
    }
    my ( $cores, $non_cores ) = $self->_divide_core_or_not($deps);
    $self->_spew( $cores, $non_cores );
}

sub _spew {
    my ( $self, $cores, $non_cores ) = @_;

    my $core_index     = $self->_make_index( scalar(@$cores) );
    my $non_core_index = $self->_make_index( scalar(@$non_cores), 'non-' );

    print "Target: perl-$self->{perl_version}\n";
    print colored['green'], "$core_index";
    print "\n";
    print "\t$_\n" for (@$cores);
    print colored['yellow'], "$non_core_index";
    print "\n";
    print "\t$_\n" for (@$non_cores);
}

sub _make_index {
    my ( $self, $num, $optional ) = @_;

    $optional ||= '';
    my $index = "Depends on $num " . $optional . "core modules:";
    if ( $num == 1 ) {
        $index =~ s/modules/module/;
    }
    unless ($num) {
        $index = "Depends on no " . $optional . "core module.";
    }

    return $index;
}

sub _fetch_deps_from_metacpan {
    my ( $self, $module ) = @_;

    ( my $module_name  = $module->{name} ) =~ s/::/-/g;
    my $module_version = $module->{version};

    my $version_dscr = '"term": { "release.status": "latest" }';
    if ($module_version) {
        $version_dscr = qq/"term": { "release.version": "$module_version" }/;
    }

    my $furl = Furl->new(
        agent   => 'App-pmdeps',
        timeout => $self->{timeout},
    );

    my $res = $furl->post(
        METACPAN_API_URL,
        [ 'Content-Type' => 'application/json' ],
        sprintf( <<'EOQ', $module_name, $version_dscr ) );
        {
            "query": {
                "match_all": {}
            },
            "fields": [ "dependency" ],
            "filter": {
                "and": [
                    { "term": { "release.distribution": "%s" } },
                    { "term": { "release.maturity": "released" } },
                    { %s }
                ]
            }
        }
EOQ

    my $content = decode_json( $res->{content} );
    my @deps    = @{$content->{hits}->{hits}[0]->{fields}->{dependency}};
    for my $phase (@{$self->{without_phase}}) {
        @deps = grep { $_->{phase} ne $phase } @deps;
    }
    for my $type (@{$self->{without_type}}) {
        @deps = grep { $_->{relationship} ne $type } @deps;
    }

    return \@deps;
}

sub _fetch_deps_from_metadata {
    my ( $self, $path ) = @_;

    $path = rel2abs($path);

    my $meta_json_file   = catfile( $path, 'META.json' );
    my $mymeta_json_file = catfile( $path, 'MYMETA.json' );

    my $using_json_file;
    $using_json_file = $mymeta_json_file if -e $mymeta_json_file;
    $using_json_file = $meta_json_file   if -e $meta_json_file; # <= High priority

    unless ($using_json_file) {
        croak '[ERROR] META.json or MYMETA.json is not found.';
    }

    local $/;
    open my $fh, '<', $using_json_file;
    my $json = decode_json(<$fh>);
    close $fh;

    my @prereqs;
    for my $phase ( keys %{ $json->{prereqs} } ) {
        unless ( grep { $phase eq $_ } @{ $self->{without_phase} } ) {
            push @prereqs, $json->{prereqs}->{$phase};
        }
    }

    for my $prereq (@prereqs) {
        for my $type ( @{ $self->{without_type} } ) {
            delete $prereq->{$type};
        }
    }

    my @requires;
    my @modules = map { keys %$_ } map { values %$_ } @prereqs;
    for my $module ( @modules ) {
        push @requires, { module => $module };
    }
    return \@requires;
}

sub _divide_core_or_not {
    my ( $self, $deps ) = @_;

    my ( @cores, @non_cores );

    for my $dep (@$deps) {
        my $module = $dep->{module};

        next if $module eq 'perl';

        my $core_version = Module::CoreList->first_release($module);
        if ( $core_version && $self->{perl_version} - $core_version > 0 ) {
            push @cores, $module;
            next;
        }
        push @non_cores, $module;
    }

    @cores     = sort { $a cmp $b } $self->_unique(@cores);
    @non_cores = sort { $a cmp $b } $self->_unique(@non_cores);

    return ( \@cores, \@non_cores );
}

sub show_version {
    _print_immediately("pm-deps (App::pmdeps): v$VERSION");
    die "\n";
}

sub show_short_usage {
    _print_immediately(<<EOU);
Usage: pm-deps [options] Module [module_version]

Try `pm-deps --help` to get more information.
EOU
    die "\n";
}

sub show_usage {
    _print_immediately(<<EOU);
Usage:
    pm-deps [options] Module [module_version]

    options:
        -l,--local          Fetch dependencies from the local module
        -p,--perl-version   Set target perl version (default: perl version which you are using)
        -t,--timeout        Set seconds of the threshold for timeout (This application attempts to connect to metacpan)
        -h,--help           Show help messages. It's me!
        -v,--version        Show version of this application
EOU
    die "\n";
}

sub _print_immediately {
    my $msg = shift;
    $| = 1;    # flush
    print $msg;
    $| = 0;    # no flush
}

sub _unique {
    my ( $self, @array ) = @_;
    my %hash = map { $_, 1 } @array;
    return keys %hash;
}
1;
__END__

=encoding utf-8

=head1 NAME

App::pmdeps - Fetch and show dependencies of CPAN module


=head1 DESCRIPTION

Please refer to the L<pm-deps>.


=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 AUTHOR

moznion C<< moznion@gmail.com >>

=cut
