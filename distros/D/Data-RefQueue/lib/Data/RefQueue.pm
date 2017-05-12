package Data::RefQueue;
# Data::RefQueue - Queue system based on references and scalars.
# (c) 2002 - Ask Solem <ask@0x61736b.net>
# All rights reserved.
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License version 2 
#   as published by the Free Software Foundation.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
# $Id: RefQueue.pm,v 1.1 2007/05/07 13:08:23 ask Exp $
# $Source: /opt/CVS/DataRefqueue/lib/Data/RefQueue.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.1 $
# $Date: 2007/05/07 13:08:23 $
#####

use 5.006;
use strict;
use vars qw($VERSION $DEBUG);

$DEBUG = 0;

$VERSION = '0.4';

# ### prototypes
sub new;		# new RefQueue object.
sub set;		# set queue values.
sub setpos;		# set position.
sub getpos;		# get position.
sub size;		# return the number of elements in queue.
sub next;		# set position to next element.
sub prev;		# set position to previous element.
sub save;		# save current position and set pos to next.
sub reset;		# reset the position to the first element.
sub fetch;		# fetch current position.
sub queue;		# the queue itself.
sub filled;		# return all filled positions.
sub delete;		# delete (truncate) current element.
sub remove;		# remove this element.
sub cleanse;	# remove all positions not filled.
sub insert_at;  # find the element that contains 'key' and replace key with value.
sub not_filled;	# return all positions that isn't filled.

# #### data::refqueue new(string pkg, array values)
# Create a new RefQueue queue starting with @values.
# 
sub new {
	my($class, @values) = @_;
	my $self = { };
	bless $self, $class;

	if (scalar @values) {
		$self->set(@values);
	}
	$self->reset;

	return $self;
}

# #### arrayref queue(data::refqueue q)
# The queue itself.
#
sub queue {
	my ($self) = @_;
	$self->{QUEUE} ||= [ ];
	return $self->{QUEUE};
}

# #### int setpos(data::refqueue q, int pos)
# Set current queue position.
# XXX: Wraps around if higher/lower than availible elements.
#
sub setpos {
	my ($self, $pos) = @_;
	my ($package, $filename, $line, $subroutine) = caller( );

	if ($pos >= 0) {

		if ($pos > $self->size) {
			$pos = 0;
		}
        elsif ($pos < 0) {
			$pos = $self->size;
		}

		$self->{POS} = $pos;
	}
}

# #### int getpos(data::refqueue q)
# Get current queue position.
#
sub getpos {
	my ($self) = @_;
	return $self->{POS};
}


# #### int size(data::refqueue q)
# Return the number of elements in the queue.
#
sub size {
	my ($self) = @_;
	my $q = $self->queue;
	return $#$q;
}

# #### void set(data::refqueue q, array values)
# Initialize queue, with values @values.
#
sub set {
	my ($self, @values) = @_;
	my $q = $self->queue;
	print {*STDERR} "SET ". join(", ", @values). "\n" if $DEBUG;
	@$q = @values;
}

# #### void next(data::refqueue q)
# Set position to the next availible position.
#
sub next {
	my ($self) = @_;
	my $pos = $self->getpos() + 1;
	$pos ||= 1;
	$self->setpos($pos);
}

# #### void next(data::refqueue q)
# Set position to the previous availible position.
#
sub prev {
	my ($self) = @_;
	my $pos = $self->getpos() - 1;
	$pos ||= 0;
	$self->setpos($pos);
}

# #### void reset(data::refqueue q)
# Set queue position to 0.
#
sub reset {
	my ($self) = @_;
	$self->{POS} = 0;
}

# #### void cleanse(data::refqueue q)
# Remove all positions not filled.
sub cleanse {
	my ($self) = @_;
	my $q = $self->queue;
	MAIN:
	while (1) {
		ELEMENT:
		for (my $qi; $qi <= $self->size; $qi++) {
			if (! ref $q->[$qi]) {
				$self->remove($self->setpos($qi));
                goto MAIN;
# We use iteration instead of recursion for performance.
# Therefore the goto.
			}
		}
		last MAIN;
	}
}

# #### arrayref not_filled(data::refqueue q)
# Return an array with the values not filled.
#
sub not_filled {
	my ($self) = @_;
	my $q = $self->queue;
	my @ret;
	for (my $qi = 0; $qi <= $self->size; $qi++) {
		if (! ref $q->[$qi]) {
			push @ret, $q->[$qi];
		}
	}
	return \@ret;
}

# #### arrayref filled(data::refqueue q)
# Return an array with the values filled.
# 
sub filled {
	my ($self) = @_;
	my $q = $self->queue;
	my @ret;
	for (my $qi = 0; $qi <= $self->size; $qi++) {
		if (ref $q->[$qi]) {
			push @ret, $q->[$qi];
		}
	}
	return \@ret;
}

# #### void* fetch(data::refqueue q)
# Fetch the value in the current position.
#
sub fetch {
	my ($self) = @_;
	print {*STDERR} "FETCH AT ".$self->getpos(). "\n" if $DEBUG;
	return $self->queue->[$self->getpos()];
}

# #### void delete(data::refqueue q)
# Delete the contents of the current position.
#
sub delete {
	my ($self) = @_;
	print {*STDERR} "DELETE AT ".$self->getpos(). "\n" if $DEBUG;
	return delete $self->queue->[$self->getpos()];
}

# #### void save(data::refqueue q, void* value)
# Save something into the current position and set position
# to the next availible element in the queue.
#
sub save {
	my ($self, $value) = @_;
	print {*STDERR} "SAVE AT ".$self->getpos(). "\n" if $DEBUG;
	my $q = $self->queue;
	$q->[$self->getpos()] = $value;
	return $self->next;
}

# ### void remove(data::refqueue)
# Remove the current position entirely, decrementing
# the size of the queue by one.
#
sub remove {
	my ($self) = @_;
	my $q = $self->queue;
	my @copy;
	print {*STDERR} "REMOVE AT ".$self->getpos(). "\n" if $DEBUG;
	for (my $qi = 0; $qi <= $self->size; $qi++) {
		if ($qi != $self->getpos()) {
			push @copy, $q->[$qi];
		}
	}
	$self->set(@copy);
    return;
}

# ### int insert_at(data::refqueue q, void* key, void* value)
# Find the element that contains 'key' and replace key with value.
#
sub insert_at {
	my ($self, $key, $value) = @_;
	my $orig_pos = $self->getpos();
	my $q = $self->queue;
	print {*STDERR} "INSERT AT $key $value\n" if $DEBUG;
	for (my $qi = 0; $qi <= $self->size; $qi++) {
		if ($q->[$qi] eq $key) {
			print {*STDERR} "KEY '$key' IS AT ELEMENT NUMBER ;$qi;\n" if $DEBUG;
			$self->setpos($qi);
			$self->save($value);
			$self->setpos($orig_pos);
			return 1;
		}
	}
	return;
}	

1;
__END__

=head1 NAME

Data::RefQueue - Queue system based on references and scalars.

=head1 VERSION

This document describes version 0.3.

=head1 SYNOPSIS

  use Data::RefQueue;

  # ###
  # These are the id's we need to fetch, and this is the
  # order we want to return.
  my $refq = new RefQueue (32, 123, 39, 20, 33, 123);

  # ### get id's we already have in cache.
  foreach my $obj_id (@{$refq->not_filled}) {
    my $objref = get_obj_from_cache($obj_id);
	if($objref) {
		$refq->save($objref)
	} else {
		$refq->next;
	}
  }	
  $refq->reset;

  # ### fetch the rest from the database. 
  my $query = build_select_query(@{$refq->not_fille});
  $db->query($query);
  while(my $result = $db->fetchrow_hash) {
	my $objref = build_obj_from_db_result($result);
    $refq->insert_at($objref->id, $objref);
  }

  # ### remove the id's we didn't find.
  $refq->cleanse;

  my $final_objects = $refq->queue;
  return $final_objects;

	

=head1 DESCRIPTION

Data::RefQueue is a Queue system based on references and scalars,
where the references are filled and scalars are unfilled positions.

A typical queue could look something like:

$refq->queue = [SCALAR(0x8109fb0), 1, 32, 128, 230, SCALAR(0x8109fb0), 140];

Element 0 and 5 are filled positions, which is proved by:

print join("\n> ", $refq->filled);

> SCALAR(0x8109fb0)

> SCALAR(0x8109fb0)

$refq->save($value) saves a value into the next availible position. etc.

=head1 METHODS

=over 4

=item data::refqueue new(string pkg, array values)

	Create a new RefQueue queue starting with @values.

=item arrayref queue(data::refqueue q)

	The queue itself.

=item int setpos(data::refqueue q, int pos)

	Set current queue position.
	Wraps around if higher/lower than availible elements.

=item int getpos(data::refqueue q)

	Get current queue position.

=item int size(data::refqueue q)

	Return the number of elements in the queue.

=item void set(data::refqueue q, array values)

	Initialize queue, with values @values.

=item void next(data::refqueue q)

	Set position to the next availible position.

=item void next(data::refqueue q)

	Set position to the previous availible position.

=item void reset(data::refqueue q)

	Set queue position to 0.

=item void cleanse(data::refqueue q)

	Remove all positions not filled.

=item arrayref not_filled(data::refqueue q)

	Return an array with the values not filled.

=item arrayref filled(data::refqueue q)

	Return an array with the values filled.

=item void* fetch(data::refqueue q)

	Fetch the value in the current position.

=item void delete(data::refqueue q)

	Delete the contents of the current position.

=item void save(data::refqueue q, void* value)

	Save something into the current position and set position
	to the next availible element in the queue.

=item void remove(data::refqueue)

	Remove the current position entirely, decrementing
	the size of the queue by one.

=item int insert_at(data::refqueue q, void* key, void* value)

	Find the element that contains 'key' and replace key with value.
 
=back

=head1 EXPORT

This module has nothing to export.

=head1 SEE ALSO

L<perl>.

=head1 AUTHOR

Ask Solem, E<lt>ask@0x61736b.netE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c), 2002-2007 Ask Solem C<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut
