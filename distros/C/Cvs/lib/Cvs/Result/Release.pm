package Cvs::Result::Release;

use strict;
use base qw(Cvs::Result::Base);

=pod

=head1 NAME

Cvs::Result::Release - Result class for the release command.

=head1 DESCRIPTION

This class handle things that compose the result of the release
command.

=head1 FIELDS

=head2 altered

Returns the list of altered files if any.

=cut

sub push_altered
{
    my($self, $file) = @_;
    push @{$self->{altered}}, $file;
}

sub altered
{
    return @{shift->{altered}||[]};
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

