use 5.010;
use strict;
use warnings;

package App::MP4Meta::MusicVideo;
{
  $App::MP4Meta::MusicVideo::VERSION = '1.153340';
}

# ABSTRACT: Add metadata to a music video

use App::MP4Meta::Base;
our @ISA = 'App::MP4Meta::Base';

use File::Spec '3.33';
use AtomicParsley::Command::Tags;

sub new {
    my $class = shift;
    my $args  = shift;

    my $self = $class->SUPER::new($args);

    $self->{'media_type'} = 'Music Video';

    return $self;
}

sub apply_meta {
    my ( $self, $path ) = @_;

    # get the file name
    my ( $volume, $directories, $file ) = File::Spec->splitpath($path);

    # parse the filename for the film title and optional year
    my ( $artist, $title ) = $self->_parse_filename($file);

    # TODO: check we have a title and artist

    my $tags = AtomicParsley::Command::Tags->new(
        artist      => $artist,
        albumArtist => $artist,
        title       => $self->{'title'} // $title,
        stik        => $self->{'media_type'},
        genre       => $self->{'genre'},
        artwork     => $self->{'coverfile'}
    );

    my $error = $self->_write_tags( $path, $tags );
    return $error if $error;

    return $self->_add_to_itunes( File::Spec->rel2abs($path) );
}

# Parse the filename and returns the videos artist and title.
sub _parse_filename {
    my ( $self, $file ) = @_;

    # strip suffix
    $file = $self->_strip_suffix($file);

    if ( $file =~ /^(.*) - (.*)$/ ) {
        return ( $self->_clean_title($1), $self->_clean_title($2) );
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MP4Meta::MusicVideo - Add metadata to a music video

=head1 VERSION

version 1.153340

=head1 SYNOPSIS

  my $film = App::MP4Meta::MusicVideo->new;
  $film->apply_meta( '/path/to/Michael Jackson vs Prodigy - Bille Girl' );

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
