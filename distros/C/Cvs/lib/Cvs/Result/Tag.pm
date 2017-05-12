package Cvs::Result::Tag;

use strict;
use base qw(Cvs::Result::Base);

=pod

=head1 NAME

Cvs::Result::Tag - Result class for the cvs tag command.

=head1 DESCRIPTION

This class handle things that compose the result of the cvs tag
command.

=head1 METHODS

=head3 get_warning

  my $warn_str = $result->get_warning($file);

Get the warning message for the specified file if any.

=head1 FIELDS

=head2 tagged

Returns the list of tagged files if any.

=head2 untagged

Returns the list of untagged files if any.

=head2 warned

Return the lost of file who's got warning

=cut

sub push_tagged
{
    my($self, $file) = @_;
    push @{$self->{tagged}}, $file;
}

sub tagged
{
    return @{shift->{tagged}||[]};
}

sub push_untagged
{
    my($self, $file) = @_;
    push @{$self->{untagged}}, $file;
}

sub untagged
{
    return @{shift->{untagged}||[]};
}

sub push_warning
{
    my($self, $file, $warning) = @_;
    $self->{warning}->{$file} = $warning;
}

sub warned
{
    return keys %{shift->{warning}||{}};
}

sub get_warning
{
    my($self, $file) = @_;
    return $self->{warning}->{$file};
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

