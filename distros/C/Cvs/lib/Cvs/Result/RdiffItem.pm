package Cvs::Result::RdiffItem;

use strict;
use base qw(Cvs::Result::Base);

=pod

=head1 NAME

Cvs::Result::RdiffItem - Result class for cvs rdiff command

=head1 DESCRIPTION

This class handle the cvs rdiff result for one file.

=head1 FIELDS

=head2 filename

Returns the item's filename.

=cut

Cvs::Result::RdiffItem->mk_accessors
(qw(
    filename
    from_revision
    to_revision
    is_added
    is_removed
));

sub is_modified
{
    my($self) = @_;
    # is modified if neither added nor removed
    if(not $self->is_added and not $self->is_removed)
    {
        return 1;
    }
}

sub push_diff
{
    my($self, $line) = @_;
    push(@{$self->{_diff}}, $line);
}

sub get_diff {return @{shift->{_diff}||[]}};

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

