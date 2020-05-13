package Beam::Make::Recipe;
our $VERSION = '0.001';
# ABSTRACT: The base class for Beam::Make recipes

#pod =head1 SYNOPSIS
#pod
#pod     package My::Recipe;
#pod     use v5.20;
#pod     use Moo;
#pod     use experimental qw( signatures );
#pod     extends 'Beam::Make::Recipe';
#pod
#pod     # Make the recipe
#pod     sub make( $self ) {
#pod         ...;
#pod     }
#pod
#pod     # Return a Time::Piece object for when this recipe was last
#pod     # performed, or 0 if it can't be determined.
#pod     sub last_modified( $self ) {
#pod         ...;
#pod     }
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is the base L<Beam::Make> recipe class. Extend this to build your
#pod own recipe components.
#pod
#pod =head1 REQUIRED METHODS
#pod
#pod =head2 make
#pod
#pod This method performs the work of the recipe. There is no return value.
#pod
#pod =head2 last_modified
#pod
#pod This method returns a L<Time::Piece> object for when this recipe was last
#pod performed, or C<0> otherwise. This method could use the L</cache> object
#pod to read a cached date. See L<Beam::Make::Cache> for more information.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Beam::Make>
#pod
#pod =cut

use v5.20;
use warnings;
use Moo;
use Time::Piece;
use experimental qw( signatures postderef );

#pod =attr name
#pod
#pod The name of the recipe. This is the key in the C<Beamfile> used to refer
#pod to this recipe.
#pod
#pod =cut

has name => ( is => 'ro', required => 1 );

#pod =attr requires
#pod
#pod An array of recipe names that this recipe depends on.
#pod
#pod =cut

has requires => ( is => 'ro', default => sub { [] } );

#pod =attr cache
#pod
#pod A L<Beam::Make::Cache> object. This is used to store content hashes and
#pod modified dates for later use.
#pod
#pod =cut

has cache => ( is => 'ro', required => 1 );

1;

__END__

=pod

=head1 NAME

Beam::Make::Recipe - The base class for Beam::Make recipes

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    package My::Recipe;
    use v5.20;
    use Moo;
    use experimental qw( signatures );
    extends 'Beam::Make::Recipe';

    # Make the recipe
    sub make( $self ) {
        ...;
    }

    # Return a Time::Piece object for when this recipe was last
    # performed, or 0 if it can't be determined.
    sub last_modified( $self ) {
        ...;
    }

=head1 DESCRIPTION

This is the base L<Beam::Make> recipe class. Extend this to build your
own recipe components.

=head1 ATTRIBUTES

=head2 name

The name of the recipe. This is the key in the C<Beamfile> used to refer
to this recipe.

=head2 requires

An array of recipe names that this recipe depends on.

=head2 cache

A L<Beam::Make::Cache> object. This is used to store content hashes and
modified dates for later use.

=head1 REQUIRED METHODS

=head2 make

This method performs the work of the recipe. There is no return value.

=head2 last_modified

This method returns a L<Time::Piece> object for when this recipe was last
performed, or C<0> otherwise. This method could use the L</cache> object
to read a cached date. See L<Beam::Make::Cache> for more information.

=head1 SEE ALSO

L<Beam::Make>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
