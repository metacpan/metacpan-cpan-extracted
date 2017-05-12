use 5.010;
use strict;
use warnings;

package App::MP4Meta::TV;
{
  $App::MP4Meta::TV::VERSION = '1.153340';
}

# ABSTRACT: Add metadata to a TV Series

use App::MP4Meta::Base;
our @ISA = 'App::MP4Meta::Base';

use File::Spec '3.33';
use AtomicParsley::Command::Tags;

use App::MP4Meta::Source::Data::TVEpisode;

# a list of regexes to try to parse the file
my @file_regexes = (
    qr/^S(?<season>\d)-E(?<episode>\d)\s+-\s+(?<show>.*)$/,
    qr/^S(?<season>\d)-E(?<episode>\d)\s*-\s*E(?<end_episode>\d)\s+-\s+(?<show>.*)$/,
    qr/^(?<show>.*)\s+S(?<season>\d\d)(\s|)E(?<episode>\d\d)$/,
    qr/^(?<show>.*)\s+S(?<season>\d\d)(\s|)E(?<episode>\d\d)\s*-\s*E(?<end_episode>\d\d)$/,
    qr/^(?<show>.*)\.S(?<season>\d\d)E(?<episode>\d\d)/i,
    qr/^(?<show>.*)\.S(?<season>\d\d)E(?<episode>\d\d)\s*-\s*E(?<end_episode>\d\d)/i,
    qr/^(?<show>.*)\s*-?\s*S(?<season>\d\d?)E(?<episode>\d\d?)/i,
    qr/^(?<show>.*)\s*-?\s*S(?<season>\d\d?)E(?<episode>\d\d?)\s*-\s*E(?<end_episode>\d\d)/i,
    qr/^(?<show>.*)-S(?<season>\d\d?)E(?<episode>\d\d?)/,
    qr/^(?<show>.*)-S(?<season>\d\d?)E(?<episode>\d\d?)\s*-\s*E(?<end_episode>\d\d)/,
    qr/^(?<show>.*)-S(?<season>\d\d?)E(?<episode>\d\d?)/i,
    qr/^(?<show>.*)-S(?<season>\d\d?)E(?<episode>\d\d?)\s*-\s*E(?<end_episode>\d\d)/i,
    qr/S(?<season>\d\d?)E(?<episode>\d\d?)/i,
    qr/S(?<season>\d\d?)E(?<episode>\d\d?)\s*-\s*E(?<end_episode>\d\d?)/i,
    qr/^(?<show>.*)\s*-?\s*(?<season>\d\d?)x(?<episode>\d\d?)/,
);

sub new {
    my $class = shift;
    my $args  = shift;

    my $self = $class->SUPER::new($args);

    # args for skipping
    $self->{'continue_without_any'}      = $args->{'continue_without_any'};
    $self->{'continue_without_overview'} = $args->{'continue_without_overview'};
    $self->{'continue_without_genre'}    = $args->{'continue_without_genre'};
    $self->{'continue_without_year'}     = $args->{'continue_without_year'};
    $self->{'continue_without_cover'}    = $args->{'continue_without_cover'};

    # attributes
    $self->{'season'}   = $args->{'season'};
    $self->{'episode'}  = $args->{'episode'};
    $self->{'overview'} = $args->{'overview'};
    $self->{'year'}     = $args->{'year'};
    $self->{'cover'}    = $args->{'cover'};

    # we are a TV Show
    $self->{'media_type'} = 'TV Show';

    return $self;
}

sub apply_meta {
    my ( $self, $path ) = @_;
    my %tags = (
        show_title => $self->{'title'},
        season     => $self->{'season'},
        episode    => $self->{'episode'},
    );

    # get the file name
    my ( $volume, $directories, $file ) = File::Spec->splitpath($path);

    unless ( $tags{show_title} && $tags{season} && $tags{episode} ) {

        # parse the filename for the title, season and episode
        ( $tags{show_title}, $tags{season}, $tags{episode} ) =
          $self->_parse_filename($file, $directories);
        unless ( $tags{show_title} && $tags{season} && $tags{episode} ) {
            return "Error: could not parse the filename for $path";
        }
    }

    my $episode = App::MP4Meta::Source::Data::TVEpisode->new(
        genre    => $self->{'genre'},
        cover    => $self->{'cover'},
        overview => $self->{'overview'},
        year     => $self->{'year'},
    );
    unless ( _episode_is_complete($episode) ) {
        for my $source ( @{ $self->{'sources_objects'} } ) {
            say sprintf( "trying source '%s'", $source->name )
              if $self->{verbose};

            # merge new epiosde into previous
            $episode->merge( $source->get_tv_episode( \%tags ) );

            # last if we have everything
            last
              if ( _episode_is_complete($episode) );
        }
    }

    # check what we have
    unless ( $episode->overview ) {
        if (   $self->{'continue_without_any'}
            || $self->{'continue_without_overview'} )
        {
            say 'no overview found; continuing';
        }
        else {
            return sprintf( 'no overview found for %s, season %d, episode %d',
                $tags{show_title}, $tags{season}, $tags{episode} );
        }
    }

    my $show_title = $episode->show_title // $tags{show_title};
    my $apTags = AtomicParsley::Command::Tags->new(
        artist       => $show_title,
        albumArtist  => $show_title,
        title        => $episode->title,
        album        => sprintf( "%s, Season %s", $show_title, $tags{season} ),
        tracknum     => $tags{episode},
        TVShowName   => $show_title,
        TVEpisode    => $tags{episode},
        TVEpisodeNum => $tags{episode},
        TVSeasonNum  => $tags{season},
        stik         => $self->{'media_type'},
        description  => $episode->overview,
        longdesc     => $episode->overview,
        genre        => $episode->genre,
        year         => $episode->year,
        artwork      => $episode->cover
    );

    say 'writing tags' if $self->{verbose};
    my $error = $self->_write_tags( $path, $apTags );
    return $error if $error;

    return $self->_add_to_itunes( File::Spec->rel2abs($path) );
}

# Parse the filename in order to get the series title the and season and episode number.
sub _parse_filename {
    my ( $self, $file, $directories ) = @_;

    my $show = '';
    my $season = '';
    my $episode = '';

    # strip suffix
    $file = $self->_strip_suffix($file);

    # see if we have a regex that matches
    for my $r (@file_regexes) {
        if ( $file =~ $r ) {
            $show       = $self->{title}   // $+{show};
            $season  = $self->{season}  // $+{season};
            $episode = $self->{episode} // $+{episode};

            if ( $show && $season && $episode ) {

                return ( $self->_clean_title($show), int $season,
                    int $episode );
            }
        }
    }

    if ( $directories )
    {
        #-- remove Season N
        $directories =~ s{/season\s+(\d+)$/?}{}i;
        my @parts = (split /\//, $directories);
        $show = $parts[$#parts];
    }
    
    if ( $show && $season && $episode ) {
        return ( $self->_clean_title($show), int $season, int $episode );
    }
    return;
}

# true if we have all we need in an episode
sub _episode_is_complete {
    my $episode = shift;
    return ( $episode->overview
          && $episode->genre
          && $episode->year
          && $episode->cover );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MP4Meta::TV - Add metadata to a TV Series

=head1 VERSION

version 1.153340

=head1 SYNOPSIS

  my $tv = App::MP4Meta::TV->new({ genre => 'Comedy' });
  $tv->apply_meta( '/path/to/THE_MIGHTY_BOOSH_S1E1.m4v' );

=head1 METHODS

=head2 apply_meta( $path )

Apply metadata to the file at this path.

Returns undef if success; string if error.

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
