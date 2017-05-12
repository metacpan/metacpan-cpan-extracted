package Array::Lock;
require 5.007003;
# use strict;
# use warnings;
require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(lock_values unlock_values lock_indexes 
  unlock_indexes lock_array unlock_array) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION = '0.02';

=head1 NAME

Array::Lock- Subroutines to make Arrays read-only.

=head1 SYNOPSIS

  use Array::Lock qw(lock_indexes  unlock_indexes
                    lock_value    unlock_value
                    lock_array    unlock_array);

  @array   = qw/f o o b a r/;
  @indexes = qw/1 2 4/;
  lock_values    (@array);
  lock_values    (@array, @indexes);
  unlock_values  (@array);

  lock_indexes   (@array);
  unlock_indexes (@array);

  lock_array     (@array);
  unlock_array   (@array);

=head1 DESCRIPTION

C<Array::Lock> contains functions to lock an array.

By default C<Array::Lock> does not export anything.

=head2 Restricted arrays

Perl 5.8.0 (inadvertantly for arrays?) introduces the ability to restrict
an array to a range of indexes... No indexes outside of these can be
altered..  It also introduces the ability to lock an individual index so
it cannot be deleted and the value cannot be changed.

=over 4

=item lock_indexes

=item unlock_indexxes

  lock_indexes(@array);

Restricts the given arrays indexes to its current amount. No more indexes
can be added; however, the values of current indexes can be changed.
exists() will still work, but delete() will not, as its standard behavior
is to get rid of the current index. B<Note>: the current implementation prevents
bless()ing while locked. Any attempt to do so will raise an exception. Of course
you can still bless() the array before you call lock_indexes() so this shouldn't be
a problem.

Right now, lock_indexes does not function with a range.  However, if I get feedback that
sugests that a range is desired, a hack of some sort may be possible.

  unlock_indexes(@array);

Removes the restriction on the array's indexes.

=cut
sub lock_indexes   (\@) { Internals::SvREADONLY @{$_[0]}, 1; }
sub unlock_indexes (\@) { Internals::SvREADONLY @{$_[0]}, 0; }
# You cannot lock a specific index, because of shift...
# I guess, you could lock that one index, and allow all the other
# indexes _above_ it to be usable... should I do that?

=item lock_value

=item unlock_value

  lock_values   (@array, @indexes);
  lock_values   (@array);
  unlock_values (@array, @indexes);

Locks and unlocks index value pairs in an array.  If no set of indexes is
specified, then all current indexes are locked.

=cut

sub lock_values (\@;@) {
  my($array,@indexes) = @_;
  Internals::SvREADONLY $array->[$_], 1 for @indexes ? @indexes : $[.. $#{$array};
}

sub unlock_values (\@;@) {
  my($array,@indexes) = @_;
  Internals::SvREADONLY $array->[$_], 0 for @indexes ? @indexes : $[.. $#{$array};
}

=item B<lock_array>

=item B<unlock_array>

    lock_array(@array);

lock_array() locks an entire array, making all indexes and values readonly.
No value can be changed, no indexes can be added or deleted.

    unlock_array(@array);

unlock_arrray() does the opposite of lock_array().  All indexes and values
are made read/write.  All values can be changed and indexes can be added
and deleted.

=cut

sub lock_array (\@) { #You can only retrieve from the array
  my $array = shift;
  lock_indexes(@$array);
  lock_values(@$array);
}

sub unlock_array (\@) {
  my $array = shift;
  unlock_indexes(@$array);
  unlock_values(@$array);
}
1;
__END__

=back
=head1 SEE ALSO

L<Hash::Util>, L<ReadOnly>

=head1 AUTHOR

Gyan Kapur, <gkapur@cpan.org>

This is really just Schwern's code, although he doesn't know it...

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Gyan Kapur

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
