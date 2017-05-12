# Bubblegum Prototype Package Base Class
package Bubblegum::Prototype::Package;

use Bubblegum::Class;
use Bubblegum::Constraints -typesof;

use Moo ();
use Moo::Role ();

has name => (
    is       => 'ro',
    isa      => typeof_string,
    required => 1
);

{
    no warnings 'redefine';

    sub after {
        my $self  = shift;
        my $class = $self->name;
        $class->isa_classname;
        $class->can('after')->(@_);
        return;
    }

    sub around {
        my $self = shift;
        my $class = $self->name;
        $class->isa_classname;
        $class->can('around')->(@_);
        return;
    }

    sub before {
        my $self = shift;
        my $class = $self->name;
        $class->isa_classname;
        $class->can('before')->(@_);
        return;
    }

    use warnings 'redefine';
}

sub make {
    my $self = shift;
    my $name = shift;
    my $code = shift;

    my $class = $self->name;
    $class->isa_classname;

    $name->isa_string;
    $code->isa_coderef;

    no strict 'refs';
    return *{"${class}::$name"} = $code;
}

sub mixin {
    my ($self, %args) = @_;

    my $class = $self->name;
    $class->isa_classname;

    if (my $mixin = $args{class}) {
        $mixin->isa_classname;
        Moo->_set_superclasses($class, $mixin);
        Moo->_maybe_reset_handlemoose($class);
    }

    if (my $role = $args{role}) {
        $role->isa_classname;
        Moo::Role->apply_roles_to_package($class, $role);
        Moo->_maybe_reset_handlemoose($class);
    }

    return;
}

1;
