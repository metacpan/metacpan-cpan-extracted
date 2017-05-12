# ABSTRACT: Command line scrobbling app
package App::Scrobble;

use Moose;
use namespace::autoclean;
with 'MooseX::Getopt::Dashes',
     'MooseX::SimpleConfig';

our $VERSION = '0.03'; # VERSION

use Module::PluginFinder;
use Net::LastFM::Submission;
use File::HomeDir;
use Data::Dump qw( pp );

has 'username' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    documentation => 'Your last.fm username',
);

has 'password' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    documentation => 'Your last.fm password',
);

has 'url' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    documentation => 'The URL of the thing you\'d like to scrobble',
);

has '+configfile' => (
    is => 'rw',
    default => sub {
        return File::HomeDir->my_home . "/.scrobble.yaml";
    },
);

has 'dry_run' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    documentation => 'Show what would have been scrobbled but doesn\'t actually scrobble',
);

has 'verbose' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    documentation => 'Prints out information about progress',
);

has 'debug' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    documentation => 'Print out extra diagnostics, useful if things do not seem to be working',
);

has 'finder' => (
    is => 'rw',
    lazy_build => 1,
    traits => [ 'NoGetopt' ],
);

sub _build_finder {
    my $self = shift;

    return Module::PluginFinder->new(
       search_path => 'App::Scrobble::Service',

       filter => sub {
          my ( $module, $searchkey ) = @_;

          return 0 unless $module->can( "is_plugin_for" );
          return $module->is_plugin_for( $searchkey );
       },
    );
}

sub scrobble {
    my $self = shift;

    my $service = $self->finder->construct( $self->url, { url => $self->url } );

    my $tracks = $service->get_tracks;

    $self->_scrobble_tracks( $tracks );
}

sub _scrobble_tracks {
    my $self = shift;
    my $tracks = shift;

    my $lastfm = Net::LastFM::Submission->new(
        ua       => LWP::UserAgent->new('timeout' => 10, 'env_proxy' => 1),
        user     => $self->username,
        password => $self->password,
    );

    my $ret = $lastfm->handshake;
    print pp $ret if $self->debug;

    # Any errors?
    if ( exists $ret->{error} ) {
        warn "There was a problem authenticating with last.fm: "
            . $ret->{reason}||$ret->{error};
        exit(1);
    }

    my $time = time;
    my $count = 0;

    foreach my $track ( @{ $tracks } ) {

        my $artist = $track->{artist};
        my $track  = $track->{title};

        # XXX use open binmode to correctly encode/decode the output
        print "Scrobbling track: $track artist: $artist \n" if $self->verbose;

        ## no critic
        my $ret = $lastfm->submit({
            artist => $artist,
            title  => $track,
            time   => $time - ( $count *  3 * 60 ),
        }) unless $self->dry_run;
        print pp $ret if $self->debug;

        $count++;
    }
}

__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

App::Scrobble - Command line scrobbling app

=head1 VERSION

version 0.03

=head1 DESCRIPTION

Main functionality of L<App::Scrobble>. Takes the command line arguments and
instantiates the correct plugin, if one supports the URL to scrobble.

Instructs the plugin to grab the track data and then submits each track to
L<LastFM|http://www.last.fm>. Makes some vaguely sensible made-up submission times
so all the tracks aren't submitted at exactly the same time.

Works behind a proxy if you set the C<http_proxy> env var.

=head1 METHODS

=head2 C<scrobble>

Main sub called by the script.

=head1 SEE ALSO

L<App::scrobble>

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

