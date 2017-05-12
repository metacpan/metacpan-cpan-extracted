# Data::Object::Prototype Package Class
package Data::Object::Prototype::Package;

use 5.10.0;

use strict;
use warnings;

require Moo;
require Moo::Role;

use Data::Object::Class;
use Data::Object::Signatures;

use Data::Object::Library -types;

our $VERSION = '0.06'; # VERSION

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

method attribute (@args) {
    my $class = $self->name;

    $class->can('has')->(@args);

    return;
}

method mixin_base (Str $name) {
    my $class = $self->name;

    "Moo"->_set_superclasses($class, $name);
    "Moo"->_maybe_reset_handlemoose($class);

    return;
}

method mixin_role (Str $name) {
    my $class = $self->name;

    "Moo::Role"->apply_roles_to_package($class, $name);
    "Moo"->_maybe_reset_handlemoose($class);

    return;
}

method method (Str $name, CodeRef $routine) {
    my $class = $self->name;

    {
        no strict 'refs';
        no warnings 'redefine';
        *{"${class}::$name"} = $routine;
    }

    return;
}

method install_method_before (Str $name, CodeRef $routine) {
    my $class = $self->name;

    $class->can('before')->($name, $routine);

    return;

}

method install_method_after (Str $name, CodeRef $routine) {
    my $class = $self->name;

    $class->can('after')->($name, $routine);

    return;

}

method install_method_around (Str $name, CodeRef $routine) {
    my $class = $self->name;

    $class->can('around')->($name, $routine);

    return;

}

1;

