package Brickyard::Role::PluginBundle;

use 5.010;
use warnings;
use strict;

use Role::Basic allow => 'Brickyard::Accessor';
use Brickyard::Accessor new => 1, rw => [qw(brickyard)];
requires 'bundle_config';

sub _exp {
    my ($self, $package) = @_;
    $self->brickyard->expand_package($package);
}
1;

=head1 NAME

Brickyard::Role::PluginBundle - Role to use for plugin bundles

=head1 SYNOPSIS

    package My::App::PluginBundle::Foo;
    use Role::Basic 'with';
    with qw(Brickyard Role::Plugin);

    sub bundle_config {
        [
            [ '@Default/Uppercase', $_[0]->_exp('Uppercase'), {} ],
            [ '@Default/Repeat',    $_[0]->_exp('Repeat'), { times => 3 } ]
        ];
    }

=head1 METHODS

=head2 new

Constructs a new object. Takes an optional hash of arguments to initialize the
object.

=head2 brickyard

Read-write accessor for the L<Brickyard> object that created this object.

=head2 _exp

Takes a package name and delegates to the brickyard's C<expand_package()>
method.
