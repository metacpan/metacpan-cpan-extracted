package AI::MicroStructure::any;
use strict;
use List::Util 'shuffle';
use AI::MicroStructure ();
our $VERSION = '1.000';

our $Theme = 'any';

sub import {
    # export the metaany function
    my $callpkg = caller;
    my $meta    = AI::MicroStructure::any->new();
    no strict 'refs';
    *{"$callpkg\::metaany"} = sub { $meta->name( @_ ) };
}

sub name {
    my $self  = shift;
    my $structure =
      ( shuffle( grep { !/^(?:any|random)$/ } AI::MicroStructure->structures() ) )[0];
    $self->{meta}->name( $structure, @_ );
}

sub new {
    my $class = shift;

    # we need a full AI::MicroStructure object, to support AMS::Locale
    return bless { meta => AI::MicroStructure->new( @_ ) }, $class;
}

sub structure { $Theme };

sub has_remotelist { };

1;

=encoding iso-8859-1

=head1 NAME

AI::MicroStructure::any - Items from any structure

=head1 DESCRIPTION

This structure simply selects a theme at random from all available
structures, and returns names from it.

The selection is done in such a manner that you'll see no repetition
in the items returned from a given structure, until all items from the
structure have been seen.

=head1 METHODS

=over 4

=item new( @args )

Create a new instance.

The parameters will be used to create the underlying AI::MicroStructure
object, and will be passed to the randomly chosen structure. This can be
useful for structures deriving from AI::MicroStructure::Locale.

=item name( $count )

Implement the name() method for this class.

=item structure()

Return the structure name (C<any>).

=item has_remotelist()

Always return false.

=back

=head1 CONTRIBUTOR

Philippe Bruhat, upon request of Sébastien Aperghis-Tramoni.

Introduced in Acme-MetaSyntactic version 0.12, published on March 7, 2005.

Updated to conform with interface changes required by
C<AI::MicroStructure::Updatable> in version 0.49, published
on November 21, 2005.

Received its own version number for Acme-MetaSyntactic version 1.000,
published on May 7, 2012.

=head1 SEE ALSO

L<AI::MicroStructure>.

=cut

