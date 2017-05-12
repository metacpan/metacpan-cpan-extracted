package Brickyard::Role::Plugin;

use 5.010;
use warnings;
use strict;

use Role::Basic 0.12 allow => 'Brickyard::Accessor';
use Brickyard::Accessor new => 1, rw => [qw(brickyard name)];

sub plugins_with {
    my ($self, $role) = @_;
    $self->brickyard->plugins_with($role);
}

sub normalize_param {
    my ($self, $param) = @_;
    return [] unless defined $param;
    if (wantarray) {
        return ref $param eq 'ARRAY' ? @$param : $param;
    } else {
        return ref $param eq 'ARRAY' ? $param : [ $param ];
    }
}

1;

=head1 NAME

Brickyard::Role::Plugin - Role to use for plugins

=head1 SYNOPSIS

    package My::App::Plugin::Foo;
    use Role::Basic 'with';
    with qw(Brickyard Role::Plugin);

=head1 METHODS

=head2 new

Constructs a new object. Takes an optional hash of arguments to initialize the
object.

=head2 brickyard

Read-write accessor for the L<Brickyard> object that created this plugin.

=head2 name

Read-write accessor for the plugin's name.

=head2 plugins_with

Delegates to the brickyard object's C<plugins_with()> method.

=head2 normalize_param

Utility method to get a parameter value. It returns the parameter with
the given name so it's ready to be used as a list. It's returned as a
list in list context and as a reference to a list in scalar context.
