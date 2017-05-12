use 5.010;
use strict;
use warnings;

package App::MP4Meta::Source::OMDB;
{
  $App::MP4Meta::Source::OMDB::VERSION = '1.153340';
}

# ABSTRACT: Fetches film data from the OMDB.

use App::MP4Meta::Source::Base;
our @ISA = 'App::MP4Meta::Source::Base';

use App::MP4Meta::Source::Data::Film;

use WebService::OMDB;
use File::Temp  ();
use LWP::Simple ();

use constant NAME     => 'OMDB';
use constant PLOT     => 'short';
use constant RESPONSE => 'json';

sub new {
    my $class = shift;
    my $args  = shift;
    my $self  = $class->SUPER::new($args);

    return $self;
}

sub name {
    return NAME;
}

sub get_film {
    my ( $self, $args ) = @_;

    $self->SUPER::get_film($args);

    my $result = WebService::OMDB::title(
        $args->{title},
        {
            year => $args->{year},
            plot => PLOT,
            r    => RESPONSE
        }
    );

    # get cover file
    # FIXME: never set
    my $cover_file;
    unless ($cover_file) {

        my $poster = $result->{Poster};
        $cover_file = $self->_get_cover_file($poster);
    }

    # FIXME: poster could be null.

    return App::MP4Meta::Source::Data::Film->new(
        overview => $result->{Plot},
        title    => $result->{Title},
        genre    => $result->{Genre},
        cover    => $cover_file,
        year     => $result->{Year},
    );
}

# gets the cover file for the season and returns the filename
# also stores in cache
sub _get_cover_file {
    my ( $self, $url ) = @_;

    my $temp = File::Temp->new( SUFFIX => '.jpg' );
    push @{ $self->{tempfiles} }, $temp;
    if (
        LWP::Simple::is_success(
            LWP::Simple::getstore( $url, $temp->filename )
        )
      )
    {
        return $temp->filename;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MP4Meta::Source::OMDB - Fetches film data from the OMDB.

=head1 VERSION

version 1.153340

=head1 METHODS

=head2 name()

Returns the name of this source.

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
