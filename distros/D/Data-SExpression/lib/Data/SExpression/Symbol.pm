use warnings;
use strict;

=head1 NAME

Data::SExpression::Symbol -- A Lisp symbol read by Data::SExpression

=head1 DESCRIPTION

A Data::SExpression::Symbol represents a lisp symbol. Symbols are
usually used as opaque objects that can be compared with each other,
but are not intended to be used for other operations.

There are two kinds of symbols, C<interned>, and C<uninterned>. Most
symbols are C<interned>. There is only ever one C<interned> instance
of the C<Symbol> class for a given name.

=head1 STRINGIFICATION AND COMPARISON

Interned symbols stringify to their ->name. Uninterned symbols
stringify to "#:$name", after the Common Lisp convention.

Interned symbols are eq to their name. Uninterned symbols are not eq
to anything except themself.

=cut

package Data::SExpression::Symbol;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_ro_accessors(qw(interned name));

use Scalar::Util qw(blessed refaddr);

use overload q{""}    => \&stringify,
             eq       => \&equal,
             ne       => \&not_equal,
             fallback => 1;

our %INTERN;

=head2 new NAME

Returns a new interned symbol with the given NAME

=cut

sub new {
    my $class = shift;
    my $name = shift;
    return $INTERN{$name} if $INTERN{$name};
    my $self = {
       interned => 1,
       name => $name
      };

    bless($self, $class);
    $INTERN{$name} = $self;
    return $self;
}

=head2 uninterned NAME

Returns a new uninterned symbol with the given NAME

=cut

sub uninterned {
    my $class = shift;
    my $name = shift;
    return bless({interned => 0, name => $name}, $class);
}

=head2 name

Returns the symbol's name, as passed to C<new> or C<uninterned>.

=head2 interned

Returned true iff the symbol is interned

=cut

sub stringify {
    my $self = shift;
    return ($self->interned ? "" : "#:") . $self->name;
}

sub equal {
    my $self = shift;
    my $other = shift;
    if(!$self->interned) {
        return blessed($other) && refaddr($self) == refaddr($other);
    } else {
        if(!ref($other)) {
            return $self->name eq $other;
        } elsif(blessed($other)) {
            if($other->isa(__PACKAGE__)) {
                return $other->interned && ($self->name eq $other->name);
            }
        }
    }
    return;
}

sub not_equal {
    my $self = shift;
    my $other = shift;
    return !$self->equal($other);
}

=head1 SEE ALSO

L<Data::SExpression>

=head1 AUTHOR

Nelson Elhage <nelhage@mit.edu> 

=cut

1;
