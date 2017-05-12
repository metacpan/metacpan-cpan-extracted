package Acme::MetaSyntactic::any;
use strict;
use List::Util 'shuffle';
use Acme::MetaSyntactic ();
our $VERSION = '1.000';

our $Theme = 'any';

sub import {
    # export the metaany function
    my $callpkg = caller;
    my $meta    = Acme::MetaSyntactic::any->new();
    no strict 'refs';
    *{"$callpkg\::metaany"} = sub { $meta->name( @_ ) };
}

sub name {
    my $self  = shift;
    my $theme =
      ( shuffle( grep { !/^(?:any|random)$/ } Acme::MetaSyntactic->themes() ) )[0];
    $self->{meta}->name( $theme, @_ );
}

sub new {
    my $class = shift;

    # we need a full Acme::MetaSyntactic object, to support AMS::Locale
    return bless { meta => Acme::MetaSyntactic->new( @_ ) }, $class;
}

sub theme { $Theme };

sub has_remotelist { };

1;

=encoding iso-8859-1

=head1 NAME

Acme::MetaSyntactic::any - Items from any theme

=head1 DESCRIPTION

This theme simply selects a theme at random from all available
themes, and returns names from it.

The selection is done in such a manner that you'll see no repetition
in the items returned from a given theme, until all items from the
theme have been seen.

=head1 METHODS

=over 4

=item new( @args )

Create a new instance.

The parameters will be used to create the underlying Acme::MetaSyntactic
object, and will be passed to the randomly chosen theme. This can be
useful for themes deriving from Acme::MetaSyntactic::Locale.

=item name( $count )

Implement the name() method for this class.

=item theme()

Return the theme name (C<any>).

=item has_remotelist()

Always return false.

=back

=head1 CONTRIBUTOR

Philippe Bruhat, upon request of Sébastien Aperghis-Tramoni.

Introduced in Acme-MetaSyntactic version 0.12, published on March 7, 2005.

Updated to conform with interface changes required by
C<Acme::MetaSyntactic::Updatable> in version 0.49, published
on November 21, 2005.

Received its own version number for Acme-MetaSyntactic version 1.000,
published on May 7, 2012.

=head1 SEE ALSO

L<Acme::MetaSyntactic>.

=cut

