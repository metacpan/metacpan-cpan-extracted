package Cvs::Result::Commit;


use strict;
use base qw(Cvs::Result::Base);


=pod

=head1 NAME

Cvs::Result::Commit - Result class for cvs commit command

=head1 SYNOPSIS

  my $commit = $cvs->commit
    ( { recursive => 0, message => 'bar', },
      'changed.txt' );

  my $old = $commit->old_revision;
  my $new = $commit->new_revision;

=head1 DESCRIPTION

Returns the old and new revisions of a previously checked-in file.

=head1 METHODS

=head2 old_revision

Returns the old revision of the file checked in. Will return undef if no
change in version occurred.

=head2 new_revision

Returns the new revision of the file checked in. Will return undef if no
change in version occurred.

=cut

Cvs::Result::Commit->mk_accessors
(qw(
	old_revision
	new_revision
));

sub set_revision
{
	my $self = shift;
	my ($old, $new) = @_;
	$self->{old_revision} = $old;
	$self->{new_revision} = $new;
}

1;
=pod

=head1 SEE ALSO

L<Cvs::Command::Commit>, L<Cvs>, cvs(1).

=head1 AUTHOR

Steven Cotton E<lt>cotton@cpan.orgE<gt>

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
