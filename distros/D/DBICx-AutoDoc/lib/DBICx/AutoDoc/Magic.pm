package DBICx::AutoDoc::Magic;
use strict;
use warnings;
our $VERSION = '0.08';
use DBIx::Class::Relationship::Helpers;
use base qw( DBIx::Class );

__PACKAGE__->mk_group_accessors( inherited => qw( _autodoc ) );

my $func_body = <<'END';
    my $self = shift;
    $self->_autodoc_record_relationship( @_ );
    $self->maybe::next::method( @_ );
END

eval "sub $_ { $func_body }" for qw(
    has_many has_one might_have belongs_to many_to_many
);

# This needs to go after the stuff above, so Class::C3 can figure out the
# methods in this class
DBIx::Class::Relationship::Helpers->load_components( '+DBICx::AutoDoc::Magic' );

sub _autodoc_record_relationship {
    my $self = shift;

    my ( $method ) = ( caller( 1 ) )[3];
    $method =~ s/^.*:://;

    my $class = ref( $self ) || $self;
    if ( ! $class->_autodoc ) { $class->_autodoc( {} ) }

    push( @{ $class->_autodoc->{ 'relationships' } }, [ $method, @_ ] );
}

1;

__END__

=head1 NAME

DBICx::AutoDoc::Magic - Capture some otherwise unobtainable information about a DBIx::Class subclass

=head1 SYNOPSIS

See L<dbicx-autodoc> and L<DBICx::AutoDoc>.

=head1 DESCRIPTION

C<DBICx::AutoDoc::Magic> is a L<DBIx::Class> component used by
L<DBICx::AutoDoc> to capture some information that cannot be
reverse-engineered out of a compiled L<DBIx::Class> subclass.

=head1 METHODS

This class has only two methods of it's own...

=head2 _autodoc

This is simply an accessor (a L<Class::Accessor::Grouped> accessor, of type
'inherited' to be precise) that provides each of the subclasses with a
suitable location to store the information this module collects for them.

=head2 _autodoc_record_relationship

This method is called by each of the overloaded methods, and merely records
their arguments in the hashref stored in L</_autodoc>, and then forwards the
call on to the real method.

=head1 OVERLOADED METHODS

This module overloads the following L<DBIx::Class> methods.  They are
overloaded merely to call L</_autodoc_record_relationship> and then they
call the original method.

=head2 belongs_to

=head2 has_many

=head2 might_have

=head2 has_one

=head2 many_to_many

=head1 SEE ALSO

L<DBICx::AutoDoc>, L<dbicx-autodoc>, L<DBIx::Class>,
L<DBIx::Class::Relationship>

=head1 AUTHOR

Jason Kohles, E<lt>email@jasonkohles.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Jason Kohles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

