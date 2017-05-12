package Cvs::Result::Update;

use strict;
use base qw(Cvs::Result::Base);

=pod

=head1 NAME

Cvs::Result::Update - Result class for cvs update command

=head1 DESCRIPTION


=head1 FIELDS

=head2 updated

=head2 patched

=head2 added

=head2 removed

=head2 modified

=head2 conflict

=head2 merged

=head2 unknown

=head2 gone

=cut

my %types =
  (
   U => 'updated',
   P => 'patched',
   A => 'added',
   R => 'removed',
   M => 'modified',
   C => 'conflict',
   '?' => 'unknown',
   G => 'gone',
  );

Cvs::Result::Update->mk_accessors(values %types);

# override get method of Class::Accessor class
sub get
{
    my($self, $key) = @_;

    if(ref $self->{$key} eq 'ARRAY')
    {
        return @{$self->{$key}};
    }
    else
    {
        return $self->{$key};
    }
}

sub init
{
    my($self) = @_;
    $self->{$_} = [] for values %types;
    return $self;
}

sub add_entry
{
    my($self, $type, $file) = @_;
    push @{$self->{$types{$type}}}, $file;
}

sub push_ignored_directory
{
    my($self, $directory) = @_;
    push @{$self->{ignored_directories}}, $directory;
}

sub ignored_directories
{
    my($self) = @_;
    return @{$self->{ignored_directories}||[]};
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

