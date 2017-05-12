use warnings;
use strict;

=head1 NAME

Data::SExpression::Cons -- Representation of a Lisp cons read by
Data::SExpression.

=head1 DESCRIPTION

=cut

package Data::SExpression::Cons;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(car cdr));

=head2 new CAR CDR

Construct a new C<Cons> with the given C<car> and C<cdr>

=cut

sub new {
    my $class = shift;
    my ($car, $cdr) = @_;

    my $self = {car => $car, cdr => $cdr};
    return bless($self, $class);
}

=head2 car, cdr

Returns the C<car> or C<cdr> of this C<Cons>.

=head2 set_car CAR, set_cdr CDR

Set the C<car> or C<cdr> of this C<Cons> object.

=cut

sub mutator_name_for {
    my $self = shift;
    my $name = shift;
    return "set_$name";
}

=head1 SEE ALSO

L<Data::Sexpression>

=head1 AUTHOR

Nelson Elhage <nelhage@mit.edu> 

=cut

1;
