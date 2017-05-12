#Array::OrdHash =======================

package Array::OrdHash;
our $VERSION = '1.03';

use Carp qw/croak/;
use strict;

use overload
	'""' => sub { $_[0] },
	'%{}' => sub { tied(@{ $_[0] })->[0] },
;

sub new {
	my ($class) = shift;
	my @me;
	my $ar = tie @me, $class;#.'::_array';
	my $hs = tie %{ $ar->[0] }, $class.'::_hash';
	($hs->[0], $hs->[1]) = ($ar->[1], $ar->[2]);
	$ar->[4] = $hs;
	push @me, @_ if scalar @_;
	bless \@me, $class;
}

sub List {
	my $ar = tied @{ $_[0] };
	$ar->[3] = 0 unless defined $ar->[3];
	if ($ar->[3] > $#{ $ar->[2] }) {
		undef($ar->[3]);
		return ();
	}
	($ar->[1][$ar->[3]], ${ $ar->[2][$ar->[3]] }, $ar->[3]++);
}

sub Reset {
	my $ar = tied @{ $_[0] };
	undef($ar->[3]);
	tied(%{ $ar->[0] })->[3] = -1;
}

sub Sort {
	my $ar = tied @{ (shift) };
	my %args = ( src=>'keys', @_ );
	my ($src_ind, $proc);
	my ($src, $direction) = map { lc } split /\s+/, $args{ src };
	if ($src eq 'keys') {
		$src_ind = 0;
	}
	elsif ($src eq 'values') {
		$src_ind = 1;
	}
	else {
		return;
	}
	if (defined $args{ proc } && ref $args{ proc } eq 'CODE') {
		$proc = sub { $args{ proc }->($a->[$src_ind], $b->[$src_ind]) }
	}
	else {
		$proc = ($direction eq 'desc')? sub { $b->[$src_ind] cmp $a->[$src_ind] } : sub { $a->[$src_ind] cmp $b->[$src_ind] };
	}
	my $j=0;
	foreach (sort $proc map { [$ar->[1][$_], ${ $ar->[2][$_] }, $ar->[2][$_]] } (0 .. $#{ $ar->[1] })) {
		$ar->[1][$j] = $_->[0];
		$ar->[2][$j] = $_->[2];
		$j++;
	}
}

sub Reorder {
	my $ar = tied @{ (shift) };
	my (@ks, %ks, @vs);
	foreach (@_) {
		if (exists($ar->[4][2]{ $_ }) && !exists($ks{ $_ })) {
			push @ks, $_;
			push @vs, $ar->[4][2]{ $_ };
			$ks{ $_ } = $ar->[4][2]{ $_ };
		}
	}
	$ar->[4][0] = $ar->[1] = \@ks;
	$ar->[4][1] = $ar->[2] = \@vs;
	$ar->[4][2] = \%ks;
}

sub Indices {
	my $ar = tied @{ (shift) };
	my @ret = ();
	return @ret unless @_;
	my %ks = map { $_, -1 } @_;
	my $cnt = 0;
	foreach (keys %ks) {
		$cnt++ if (exists $ar->[4][2]{ $_ });
	}
	if ($cnt) {
		my $i = 0;
		foreach (@{ $ar->[1] }) {
			if (exists $ks{ $_ }) {
				$ks{ $_ } = $i;
				$cnt--;
				last unless $cnt;
			}
			$i++;
		}
		push @ret, $ks{ $_ } foreach (@_);
	}
	@ret;
}

sub Last {
	my $ar = tied @{ (shift) };
	$ar->[4][3] == $#{ $ar->[2] };
}
sub First { (tied @{ (shift) })->[4][3] == 0 }

sub Length { scalar @{ $_[0] } }

sub Keys {
	my $ar = tied @{ (shift) };
	if (@_) { @{ $ar->[1] }[@_] }
	else { @{ $ar->[1] } }
}

sub Values {
	my $ar = tied @{ (shift) };
	if (@_) { (map { $$_ } @{ $ar->[2] })[@_] }
	else { map { $$_ } @{ $ar->[2] } }
}

sub TIEARRAY {
	bless [
		{}, 			#hash ref
		[], 			#keys
		[], 			#values refs
		undef,		#pointer
		undef,		#tied hash (array) ref
	], $_[0];
}

sub FETCH {
	${ $_[0]->[2][$_[1]] };
}

sub STORE {
	croak("Index $_[1] doesn't exist") if $_[1] > $#{ $_[0]->[2] };
	${ $_[0]->[2][$_[1]] } = $_[2];
}

sub EXISTS {
	exists $_[0]->[2][$_[1]];
}

sub FETCHSIZE {
	scalar @{ $_[0]->[2] };
}

sub DELETE {
	return if $_[1] > $#{ $_[0]->[2] };
	delete $_[0]->[4][2]{ $_[0]->[1][$_[1]] };
	[splice(@{ $_[0]->[1] }, $_[1], 1), ${ splice(@{ $_[0]->[2] }, $_[1], 1) }];
}

sub SPLICE {
	my ($self, $offset, $len) = (shift, shift, shift);
	my (@k, @v, @ki, @vi, @ret, $k);
	my $start;
	my $lastind = $#{ $self->[2] };
	if ($offset < 0) {
		croak("Offset $offset is illegal") if -$offset > $lastind+1;
		$start = $lastind + $offset+1;
	}
	elsif ($offset > $lastind+1) {
		$start = $lastind+1;
	}
	else {
		$start = int $offset;
	}
	if ($len) {
		@k = splice @{ $self->[1] }, $start, $len;
		@v = splice @{ $self->[2] }, $start, $len;
		while (@k) {
			$k = shift @k;
			delete $self->[4][2]{ $k };
			push @ret, $k, ${ shift(@v) };
		}
	}
	while (@_) {
		($k, my $v) = (shift, shift);
		if (exists($self->[4][2]{ $k })) {
			${ $self->[4][2]{ $k } } = $v;
		}
		else {
			push @ki, $k;
			push @vi, \$v;
			$self->[4][2]{ $k } = \$v;
		}
	}
	if (@ki) {
		splice @{ $self->[1] }, $start, 0, @ki;
		splice @{ $self->[2] }, $start, 0, @vi;
	}
	@ret;
}

sub PUSH {
	my ($self) = shift;
	my ($k);
	while (@_) {
		($k, my $v) = (shift, shift);
		if (exists($self->[4][2]{ $k })) {
			${ $self->[4][2]{ $k } } = $v;
		}
		else {
			push @{ $self->[1] }, $k;
			push @{ $self->[2] }, \$v;
			$self->[4][2]{ $k } = \$v;
		}
	}
	scalar @{ $self->[2] };
}

sub UNSHIFT {
	my ($self) = shift;
	my ($k, @ki, @vi);
	while (@_) {
		($k, my $v) = (shift, shift);
		if (exists($self->[4][2]{ $k })) {
			${ $self->[4][2]{ $k } } = $v;
		}
		else {
			push @ki, $k;
			push @vi, \$v;
			$self->[4][2]{ $k } = \$v;
		}
	}
	if (scalar @ki) {
		unshift @{ $self->[1] }, @ki;
		unshift @{ $self->[2] }, @vi;
	}
	scalar @{ $self->[2] };
}

sub POP { $_[0]->DELETE($#{ $_[0]->[2] }) }
sub SHIFT { $_[0]->DELETE(0) }

#sub EXTEND { print "\tarray EXTEND($_[1])\n"; }
#sub STORESIZE { print "\tSTORESIZE\n"; }

1;

package Array::OrdHash::_hash;
#use warnings;
use strict;

sub TIEHASH {
	my $ret = bless [
		undef,		#keys ref
		undef,		#values ref
		{},			#keys - val refs
		-1,			#pointer
	], $_[0];
	$ret;
}

sub STORE {
	if (exists $_[0]->[2]{ $_[1] }) {
		${ $_[0]->[2]{ $_[1] } } = $_[2];
	}
	else {
		my $v = $_[2];
		push(@{ $_[0]->[0] }, $_[1]);
		push(@{ $_[0]->[1] }, \$v);
		$_[0]->[2]{ $_[1] } = \$v;
	}
}

sub FETCH {
	(exists $_[0]->[2]{ $_[1] }) ? ${ $_[0]->[2]{ $_[1] } } : undef;
}

sub EXISTS {
	exists $_[0]->[2]->{ $_[1] };
}

sub FIRSTKEY {
	$_[0]->[3] = 0;
	$_[0]->[0][0];
}
sub NEXTKEY {
	if ($_[0]->[3] >= $#{ $_[0]->[0] }) {
		$_[0]->[3] = -1;
		return;
	}
	$_[0]->[0][++$_[0]->[3]];
}
sub DELETE {
	return unless (exists $_[0]->[2]->{ $_[1] });
	my $ind = Array::OrdHash::_util::_keyindex($_[0]->[0], $_[1]);
	delete $_[0]->[2]{ $_[1] };
	splice(@{ $_[0]->[0] }, $ind, 1);
	[$ind, ${ splice(@{ $_[0]->[1] }, $ind, 1) }];
}
sub CLEAR {
	$_[0]->[0] = [];
	$_[0]->[1] = [];
	$_[0]->[2] = {};
	$_[0]->[3] = -1;
}
sub SCALAR   { scalar %{$_[0]->[2]} }

1;

package Array::OrdHash::_util;
use strict;

sub _keyindex {
	my $j = 0;
	foreach (@{ $_[0] }) {
		return $j if $_ eq $_[1];
		$j++;
	}
	-1;
}
#=head1 DISCLAIMER
#BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.
#IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

1;

__END__

=head1 NAME

Array::OrdHash - ordered associative array with array-like, hash-like and OO interface.

=head1 SYNOPSIS

 use Array::OrdHash;

 $oh = Array::OrdHash->new;

 $oh->{'a'} = 'First';
 $oh->{'b'} = 'Second';
 $oh->{'c'} = 'Third';
 
 $oh->[0] = 'new First';
 $oh->[1] = 'new Second';
 $oh->[3] = 'Forth';	# (would be croaked)
 
 exists $oh->{'c'};
 exists $oh->[2];	# the same result

 delete $oh->{'c'};
 delete $oh->[2];	# the same result
 
 # inserting a list
 @LIST = ('d'=>'Forth', 'e'=>'Fifth', 'f'=>'Sixth');
 push @$oh, @LIST;
 


 unshift @$oh, ('i'=>'I', 'j'=>'J', 'k'=>'K');
 
 # iterating as a hash
 while (($key, $val) = each %$oh) {
  print "$key=", $val, "\n";
 }
 
 # iterating as a list (more efficient)
 while (($key, $val, $ind) = $oh->List) {
  print "($ind) $key = $val\n";
 }

 # iterating as an array
 foreach $val (@$oh) {
  print $val, "\n";
 }
 
  $oh->Reset();

 # pop, shift and splice
 $item = pop @$oh;
 $item = shift @$oh;
 @spliced = splice @$oh, $offset, $len [,LIST];
 
 # keys and values arrays
 @k = keys %$oh;
 @v = values %$oh;
 
 @k = $oh->Keys([LIST]);
 @v = $oh->Values([LIST]);
 
 # miscellaneous
 $oh->Sort( src=>'keys' );
 $oh->Sort( src=>'values DESC' );
 $oh->Sort( proc=>\&SortProcedure );
 
 $oh->Reorder(LIST);
 
 $oh->First();
 $oh->Last()
 
 $oh->Indices(LIST);
 
 $oh->Length();

=head1 DESCRIPTION

This module implements Perl arrays that have both numeric and string indices, similar to PHP arrays or Collections, therefore the array keys are unique strings.

The order in which the elements were added is preserved just like B<L<Tie::IxHash|Tie::IxHash>> does this.

Both Perl array and Perl hash functions can be performed on a variable of this class. 
The elements of an array may be sorted both by keys and values, or with an external callback subroutine. They can also be reordered.


=head1 CONSTRUCTOR

=head2 new

 my $oh = Array::OrdHash->new([LIST]);

The new() constructor method instantiates a new B<Array::OrdHash> object.

=head1 STANDARD INTERFACES

=head2 Hash Interface

A value of an B<Array::OrdHash> object element can be set/read in a hash-like manner. When an element under the specified key does not exist then it is newly created:

 $oh->{'a'} = 'First';        $value = $oh->{'a'};
 $oh->{'b'} = 0.18;           $value = $oh->{'b'};
 $oh->{'c'} = [qw(3 .. 20)];  $value = $oh->{'c'};

 while (($key, $val) = each %$oh) {
  print "$key=", $val, "\n";
 }

The order in which the elements were added through the Standard Hash Interface is preserved. It is altered only when sorting or reordering.

Any Perl hash functions (L<delete|perlfunc/"delete">, L<each|perlfunc/"each">, L<exists|perlfunc/"exists">, L<keys|perlfunc/"keys">, L<values|perlfunc/"values">) can be performed on an B<Array::OrdHash> object just like on a Perl hash reference. The exception: when L<each|perlfunc/"each"> is called outside the B<while> cycle, or in the case of a premature end of a 'B<while> - L<each|perlfunc/"each">' cycle, the B<L</Reset>> method must be called as soon as possible in order to reset the inner iterator.
The returned value of the B<delete> function also differs from the standard one.

=head4 B<L<delete|perlfunc/"delete">>

Deletes the B<Array::OrdHash> object array element under the specified key. The returned value is an array reference representing the deleted index-value pair.

 $deleted_item = delete $oh->{ KEY };
 ($index, $value) = @$deleted_item;

=head2 Array Interface

A value of an already existing B<Array::OrdHash> object element can be set/read in an array-like manner:

 $oh->[0] = 'First';        $value = $oh->[0];
 $oh->[1] = 0.18;           $value = $oh->[1];
 $oh->[2] = [qw(3 .. 20)];  $value = $oh->[2];

 foreach $val (@$oh) {
  print $val, "\n";
 }

An element with the specified index must already exist. It can previously be set through the B<L<Hash interface>> or with B<push>, B<unshift> or B<splice> functions. An attempt to modify an element under unexisting index is croaked. However, negative indexes are acceptable within the limits of standard Perl arrays.

=head4 B<L<push|perlfunc/"push">, L<unshift|perlfunc/"unshift">>

 @LIST = ('d'=>'Forth', 'e'=>'Fifth', 'f'=>'Sixth');
 push @$oh, @LIST;
 unshift @$oh, ('i'=>'I', 'j'=>'J', 'k'=>'K');

These functions insert a list to the end or to the beginning of B<Array::OrdHash> object respectively:

The elements of the inserted list are treated as consecutive key-value pairs. The functions return the new number of items in the B<Array::OrdHash> object array.

If a key in the list already exists in the B<Array::OrdHash> object array, then its value is replaced with the supplied one, but its position is not changed.

=head4 B<L<pop|perlfunc/"pop">, L<shift|perlfunc/"shift">>

 $item = pop @$oh;
 $item = shift @$oh;
 ($key, $value) = @$item;

These functions pops or shifts an B<Array::OrdHash> object element. The returned value is an array reference representing the key-value pair.

=head4 B<L<splice|perlfunc/"splice">>

 @spliced = splice @$oh, $offset, $len [,LIST];

Does just similar as the standard splice function, but the elements of the inserted list are treated as consecutive key-value pairs.
Returns the list of spliced items as consecutive key-value pairs.

The restictions for offset and length parameters are the same as for the standard L<splice|perlfunc/"splice"> function.

=head4 B<L<exists|perlfunc/"exists">>

 $exists = exists $oh->[INDEX];

This function acts just like the standard L<exists|perlfunc/"exists">:

=head4 B<L<delete|perlfunc/"delete">>

 $deleted_item = delete $oh->[INDEX];
 ($key, $value) = @$deleted_item;

Deletes the B<Array::OrdHash> object array element under the specified index. The returned value is an array reference representing the deleted key-value pair.

=head1 METHODS

=head2 First, Last

 $is_first = $oh->First();
 $is_last = $oh->Last();

Return 1 when the current item of the B<Array::OrdHash> object during the hash-style iteration process has the first or the last position in the whole array respectively. Otherwise return undefined value.

=head2 Indices

 @indices = $oh->Indices(LIST);

Returns the indices of the keys specified by the LIST.

=head2 Keys, Values

 @k = $oh->Keys([LIST]);
 @v = $oh->Values([LIST]);

Return the array of keys or values of the B<Array::OrdHash> object respectively. When the LIST of indices is specified then only the corresponding data are returned. If the LIST is omitted then all keys or values are returned.

=head2 Length

 $len = $oh->Length();

Returns the number of items in the B<Array::OrdHash> object array.

=head2 List

Iterates through the B<Array::OrdHash> object array. Returns next key-value pair plus the current item's index. This method is some more efficient than the hash-style B<while - each> cycle.

When the cycle ends prematurely, then it is necessary to call B<L</Reset>> method as soon as possible to reset the inner iterator.

 while (($key, $val, $ind) = $oh->List) {
  print "($ind) $key = $val\n";
 }

=head2 Reorder

 $oh->Reorder(LIST);

Reorders the items in the B<Array::OrdHash> object array according to the specified LIST of keys. All items of the B<Array::OrdHash> object array whose keys are not present in the LIST are deleted. Elements of the LIST, which are not present in the initial B<Array::OrdHash> object array as keys, are ignored.

=head2 Reset



Resets the inner iterating variable of the B<Array::OrdHash> object. It is required to be called in cases when the cycles 'B<while> - L<each|perlfunc/"each">' or B<L</List>> are prematurely ended.

=head2 Sort

 $oh->Sort( ['src'=>'(keys|values)[ DESC]'][,'proc'=>\&SORT_PROCEDURE] );

Sorts the B<Array::OrdHash> object array.

Parameters:

B<I<src>> (optional) - by what must the array be sorted. Can be 'B<keys>' (default) or 'B<values>'. Sorting is case sensitive. If 'B< DESC>' is additionally given then the sorting order is descending, otherwise the order is ascending.

B<I<proc>> (optional) - a reference to an external sort procedure. When supplied then the presence of ' DESC' is ignored.

=head1 EXAMPLE

 use Array::OrdHash;

 $oh = Array::OrdHash->new('a'=>'FIRST', 'b'=>'SECOND', 'c'=>'THIRD', 'd'=>'FORTH');
 
 # replacing the third element (index 2) with another key/value pair
 
 @old_pair = splice @$oh, 2, 1, 'c new', 'THIRD new';


=head1 BUGS & CAVEATS

There no known bugs at this time, but this doesn't mean there are aren't any.

=head1 AUTHOR

Vladimir Surin C<<brexs@yandex.ru>>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2009-2010 Vladimir Surin. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 VERSION

Version 1.03

=head1 SEE ALSO

L<perlfunc>, L<Tie::IxHash|Tie::IxHash>

=cut
