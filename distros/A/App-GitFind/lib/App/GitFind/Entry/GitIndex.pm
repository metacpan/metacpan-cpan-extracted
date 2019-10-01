# App::GitFind::Entry::GitIndex - App::GitFind::Entry wrapper for a Git::Raw::Index::Entry
package App::GitFind::Entry::GitIndex;

use 5.010;
use strict;
use warnings;
use App::GitFind::Base;
#use Path::Class;
use App::GitFind::PathClassMicro;

our $VERSION = '0.000002';

use parent 'App::GitFind::Entry';

# Fields.  Not all have values.
use Class::Tiny _qwc <<'EOT';
    obj     # A Git::Raw::Index::Entry instance.  Required.
    repo    # A Git::Raw::Repository instance.  Required.
EOT

use Class::Tiny::Immutable {
    # Lazy cache of an App::GitFind::PathClassMicro::File instance for this path
    '_pathclass' => sub { App::GitFind::PathClassMicro::File->new($_[0]->repo->workdir, $_[0]->obj->path) },

    '_lstat' => sub { [$_[0]->_pathclass->lstat()] },

    isdir => sub { false },     # Git doesn't store dirs, only files.
    name => sub { $_[0]->_pathclass->basename },
    path => sub { $_[0]->_pathclass->relative($_[0]->searchbase) },
};

# Docs {{{1

=head1 NAME

# App::GitFind::Entry::GitIndex - App::GitFind::Entry wrapper for a Git::Raw::Index::Entry

=head1 SYNOPSIS

This represents a single file or directory being checked against an expression.
This particular concrete class represents a Git index entry.
It requires a L<Git::Raw::Index::Entry> instance.  Usage:

    use Git::Raw 0.83;
    my $index = Git::Raw::Repository->discover('.')->index;
    my @entries = $index->entries;
    my $entry = App::GitFind::Entry::GitIndex->new(-obj => $entries[0]);

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
    die "Usage: @{[ref $self]}->new(-obj=>..., -repo=>...)"
        unless $self->obj;
    die "-obj must be a Git::Raw::Index::Entry"
        unless $self->obj->DOES('Git::Raw::Index::Entry');
    die "Usage: @{[ref $self]}->new(-repo=>..., -obj=>...)"
        unless $self->repo;
    die "-repo must be a Git::Raw::Repository"
        unless $self->repo->DOES('Git::Raw::Repository');
} #BUILD()

1;
