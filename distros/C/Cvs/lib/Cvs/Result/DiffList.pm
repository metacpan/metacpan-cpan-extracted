package Cvs::Result::DiffList;

use strict;
use base qw(Cvs::Result::Base);

=pod

=head1 NAME

Cvs::Result::DiffList - Result list for cvs diff command

=head1 DESCRIPTION

Iterator class for Cvs::Result::DiffItem classes.

=cut

sub init
{
    my $self = shift->SUPER::init(@_);
    $self->{items} = [];
    $self->{index} = -1;
    $self->{last} = -1;
    return $self;
}

sub push
{
    my($self, $item) = @_;
    push(@{$self->{items}}, $item);
    return ++$self->{last};
}

=pod

=head1 METHODS

=head2 as_next

=cut

sub as_next
{
    my($self) = @_;
    return $self->{index} < $self->{last};
}

=pod

=head1 next

=cut

sub next
{
    my($self) = @_;
    return $self->{items}->[++$self->{index}];
}

=pod

=head1 as_prev

=cut

sub as_prev
{
    my($self) = @_;
    return $self->index > 0;
}

=pod

=head1 prev

=cut

sub prev
{
    my($self) = @_;
    return unless $self->as_prev;
    $self->{items}->[--$self->{index}];
}

=pod

=head1 current

=cut

sub current
{
    my($self) = @_;
    $self->{items}->[$self->{index}];
}

=pod

=head1 last

=cut

sub last
{
    my($self) = @_;
    $self->{items}->[$self->{last}];
}

=pod

=head1 count

=cut

sub count
{
    my($self) = @_;
    return scalar @{$self->{items}};
}


=pod

=head1 first

=cut

sub first
{
    my($self) = @_;
    $self->{items}->[0];
}

=pod

=head1 index

=cut

sub index {shift->{index}}

=pod

=head1 rewind

=cut

sub rewind {shift->{index} = -1}

=pod

=head1 get_added

Returns the list of items which were added

=cut

sub get_added
{
    my($self) = @_;
    return grep($_->is_added(), @{$self->{items}})
}

=pod

=head1 get_removed

Returns the list of items which were removed

=cut

sub get_removed
{
    my($self) = @_;
    return grep($_->is_removed(), @{$self->{items}})
}

=pod

=head1 get_modified

Returns the list of items which were modified

=cut

sub get_modified
{
    my($self) = @_;
    return grep($_->is_modified(), @{$self->{items}})
}

=pod

=head1 get_diff

Returns diffs of all files concatenated

=cut

sub get_diff
{
    my($self) = @_;
    return map($_->get_diff(), @{$self->{items}});
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

