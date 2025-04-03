#! perl

use strict;
use warnings;

package Comics::Fetcher::GoComics;

use parent qw(Comics::Fetcher::Cascade);

=head1 NAME

Comics::Fetcher::GoComics -- Fetcher for GoComics.

=head1 SYNOPSIS

  package Comics::Plugin::Garfield;
  use parent qw(Comics::Fetcher::GoComics);

  our $name    = "Garfield";
  our $url     = "https://www.comics.com/garfield";

  # Return the package name.
  __PACKAGE__;

=head1 DESCRIPTION

The C<GoComics> Fetcher handles comics that are on the GoComics
websites (comics.com, gocomics.com).

The Fetcher requires the common arguments:

=over 8

=item name

The full name of this comic, e.g. "Garfield".

=item url

The base url of this comic.

=back

Fetcher specific arguments:

=over 8

=item None as yet.

=back

=cut

our $VERSION = "1.04";

# Page contents changed, january 10, 2017.
# Page contents changed, april 5, 2018.
# Page contents changed, april 1, 2025.

sub register {
    my ( $pkg, $init ) = @_;

    # Leave the rest to SUPER.
    my $self = $pkg->SUPER::register($init);

    if ( ! $self->{url} && $self->{tag} ) {
	$self->{url} = "https?://www.gocomics.com/" . $self->{tag} . "/";
    }

    # Add the standard pattern for GoComics comics.
    $self->{patterns} =
      [
       qr{ <link \s+
	   rel="preload" \s+
	   as="image" \s+
	   imageSrcSet="
	     (?<url>https://featureassets.gocomics.com/assets/
	       (?<image>[0-9a-f]+))
         }x,
       ];

    return $self;
}

1;
