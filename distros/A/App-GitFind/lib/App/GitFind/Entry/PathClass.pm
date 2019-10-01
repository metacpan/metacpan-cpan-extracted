# App::GitFind::Entry::PathClass - App::GitFind::Entry wrapper for an App::GitFind::PathClassMicro::Entity instance
package App::GitFind::Entry::PathClass;

use 5.010;
use strict;
use warnings;
use App::GitFind::Base;
#use Path::Class;
use App::GitFind::PathClassMicro;

our $VERSION = '0.000002';

use parent 'App::GitFind::Entry';

# Fields.  Not all have values.
use Class::Tiny
    'obj';      # An App::GitFind::PathClassMicro::Entity instance.  Required.
use Class::Tiny::Immutable {
    '_lstat' => sub { [$_[0]->obj->lstat()] },

    isdir => sub { $_[0]->obj->is_dir },
    name => sub { $_[0]->obj->basename },
    path => sub { $_[0]->obj->relative($_[0]->searchbase) },

};

# Docs {{{1

=head1 NAME

# App::GitFind::Entry::PathClass - App::GitFind::Entry wrapper for an App::GitFind::PathClassMicro::Entity instance

=head1 SYNOPSIS

This represents a single file or directory being checked against an expression.
This particular concrete class represents a file or directory on disk.
It requires a L<File::Find::Object::Result> instance.  Usage:

    use App::GitFind::PathClassMicro;
    my $obj = App::GitFind::PathClassMicro::File->new('foo.txt');
        # or ...::Dir->new('bar')
    my $entry = App::GitFind::Entry::PathClass->new(-obj => $obj);

=head1 METHODS

=cut

# }}}1

=head2 prune

TODO

=cut

sub prune {
    ...
}

=head2 BUILD

Enforces the requirements on the C<-obj> argument to C<new()>.

=cut

sub BUILD {
    my $self = shift;
    die "Usage: @{[ref $self]}->new(-obj=>...)"
        unless $self->obj;
    die "-obj must be a App::GitFind::PathClassMicro::Entity"
        unless $self->obj->DOES('App::GitFind::PathClassMicro::Entity');
} #BUILD()

1;
