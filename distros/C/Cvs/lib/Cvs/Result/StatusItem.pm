package Cvs::Result::StatusItem;

use strict;
use base qw(Cvs::Result::Base);

=pod

=head1 NAME

Cvs::Result::StatusItem - Result class for cvs status command

=head1 DESCRIPTION

This class handle the cvs status result for one file.

=head1 FIELDS

=head2 exists

Returns a boolean value regarding on the file existence.

=head2 filename

Returns the item's filename.

=head2 basedir

Returns the item's basedir.

=head2 status

Returns the item's status.

=head2 working_revision

Returns the revision of the item you are working on.

=head2 repository_revision

Returns the revision of the item in the remote repository?

=head2 sticky_tag

Returns the sticky tag if any, undef otherwise.

=head2 sticky_date

Returns the sticky date if any, undef otherwise.

=head2 sticky_options

Returns the sticky options if any, undef otherwise.

=cut

Cvs::Result::StatusItem->mk_accessors
(qw(
    exists
    filename
    basedir
    status
    working_revision
    repository_revision
    sticky_tag
    sticky_date
    sticky_options
));

sub push_tag
{
    my($self, $tag, $type) = @_;
    push @{$self->{tags}}, [$tag, $type];
}

=pod

=head2 tags

Returns the list of tags on item.

=cut

sub tags
{
    my($self) = @_;
    return map $_->[0], reverse @{$self->{tags}||[]};
}

=pod

=head2 tag_type

  $status->tag_type($tag);

Returns the type of supplied tag. (revision or branch)

=cut

sub tag_type
{
    my($self, $tag) = @_;
    foreach(@{$self->{tags}})
    {
        if($_->[0] eq $tag)
        {
            $_->[1] =~ /^\((\w+)/;
            return $1;
        }
    }
}

=pod

=head2 tag_revision

  $status->tag_type($tag);

Returns the revision of item binded with supplied tag.

=cut

sub tag_revision
{
    my($self, $tag) = @_;
    foreach(@{$self->{tags}})
    {
        if($_->[0] eq $tag)
        {
            $_->[1] =~ /^\(\w+: (.*?)\)/;
            return $1;
        }
    }
}

=pod

=head1 METHODS

=head2 is_modified

Returns true if item is locally modified.

=cut

sub is_modified
{
    my($self) = @_;
    return defined $self->status &&
      $self->status =~ /Locally Modified|Needs Merge/;
}

=pod

=head2 is_up2date

Returns true if item is up to date.

=cut

sub is_up2date
{
    my($self) = @_;
    return defined $self->status &&
      $self->status =~ /Up-to-date|Locally Modified/;
}

=pod

=head2 is_merge_needed

Returns true if item is locally and remotelly modified.This mean that
a merge will be tried on the next update.

=cut

sub is_merge_needed
{
    my($self) = @_;
    return defined $self->status &&
      $self->status eq 'Needs Merge';
}

1;
=pod

=head1 LICENCE

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1 of the
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

=head1 COPYRIGHT

Copyright (C) 2003 - Olivier Poitrey

