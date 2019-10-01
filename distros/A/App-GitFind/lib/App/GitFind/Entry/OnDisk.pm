# App::GitFind::Entry::OnDisk - a file or directory on disk
package App::GitFind::Entry::OnDisk;

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
    'obj',      # A File::Find::Object::Result instance.  Required.
    'findbase'; # Where the search started from

use Class::Tiny::Immutable {
    _lstat => sub { $_[0]->obj->stat_ret },

    # Lazy App::GitFind::PathClassMicro;
    _pathclass => sub {
        ($_[0]->isdir   ? 'App::GitFind::PathClassMicro::Dir'
                        : 'App::GitFind::PathClassMicro::File'
        )->new(
            $_[0]->findbase, @{$_[0]->obj->full_components}
        )
    },

    isdir => sub { $_[0]->obj->is_dir },
    name => sub {   # basename, whether it's a file or directory
        my @x = $_[0]->obj->full_components;
        $x[$#x]
    },

    path => sub { $_[0]->_pathclass->relative($_[0]->searchbase) },
};

# Docs {{{1

=head1 NAME

# App::GitFind::Entry::OnDisk - an App::GitFind::Entry representing a file or directory on disk

=head1 SYNOPSIS

This represents a single file or directory being checked against an expression.
This particular concrete class represents a file or directory on disk.
It requires a L<File::Find::Object::Result> instance.  Usage:

    my $obj = File::Find::Object->new(...)->next_obj;
    my $entry = App::GitFind::Entry::OnDisk->new(-obj => $obj);

=head1 METHODS

=cut

# }}}1

=head2 prune

If this entry represents a directory, mark its children as not to be traversed.

If this entry represents a file, no effect.

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
    die "-obj must be a File::Find::Object::Result"
        unless $self->obj->DOES('File::Find::Object::Result');
} #BUILD()

1;
