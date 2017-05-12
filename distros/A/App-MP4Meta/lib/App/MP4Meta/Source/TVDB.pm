use 5.010;
use strict;
use warnings;

package App::MP4Meta::Source::TVDB;
{
  $App::MP4Meta::Source::TVDB::VERSION = '1.153340';
}

# ABSTRACT: Searches http://thetvbd.com for TV data.

use App::MP4Meta::Source::Base;
our @ISA = 'App::MP4Meta::Source::Base';

use App::MP4Meta::Source::Data::TVEpisode;

use WebService::TVDB 1.122800;
use File::Temp  ();
use LWP::Simple ();

use constant NAME => 'theTVDB.com';

sub new {
    my $class = shift;
    my $args  = shift;
    my $self  = $class->SUPER::new($args);

    # TODO: specify language
    # TODO: API key?
    $self->{tvdb} = WebService::TVDB->new();

    return $self;
}

sub name {
    return NAME;
}

sub get_tv_episode {
    my ( $self, $args ) = @_;

    $self->SUPER::get_tv_episode($args);

    my $series_list = $self->{tvdb}->search( $args->{show_title} );

    die 'no series found' unless @$series_list;

    # TODO: ability to search results i.e. by year
    my $series = @{$series_list}[0];
    my $cover_file;

    if ( $self->{cache}->{ $series->id } ) {
        $series = $self->{cache}->{ $series->id };
    }
    else {

        # fetches full series data and cache
        $series->fetch();
        $series = $self->{cache}->{ $series->id } = $series;
    }

    # get banner file and cache
    if ( $self->{banner_cache}->{ $series->id . '-S' . $args->{season} } ) {
        $cover_file =
          $self->{banner_cache}->{ $series->id . '-S' . $args->{season} };
    }
    else {

        $cover_file =
          $self->{banner_cache}->{ $series->id . '-S' . $args->{season} } =
          $self->_get_cover_file( $series, $args->{season} );
    }

    # get episode
    my $episode = $series->get_episode( $args->{season}, $args->{episode} );

    return App::MP4Meta::Source::Data::TVEpisode->new(
        overview   => $episode->Overview,
        title      => $episode->EpisodeName,
        show_title => $series->SeriesName,
        genre      => $series->Genre->[0],
        cover      => $cover_file,
        year       => $episode->year,
    );
}

# gets the cover file for the season and returns the filename
# also stores in cache
sub _get_cover_file {
    my ( $self, $series, $season ) = @_;

    for my $banner ( @{ $series->banners } ) {
        if ( $banner->BannerType2 eq 'season' ) {
            if ( $banner->Season eq $season ) {
                my $temp = File::Temp->new( SUFFIX => '.jpg' );
                push @{ $self->{tempfiles} }, $temp;
                if (
                    LWP::Simple::is_success(
                        LWP::Simple::getstore( $banner->url, $temp->filename )
                    )
                  )
                {
                    return $temp->filename;
                }
            }
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MP4Meta::Source::TVDB - Searches http://thetvbd.com for TV data.

=head1 VERSION

version 1.153340

=head1 METHODS

=head2 new()

Create a new object. Takes no arguments

=head2 name()

Returns the name of this source.

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
