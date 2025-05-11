package Data::LnArray::XS;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.11';

use base 'Import::Export';

our %EX = (
        arr => [qw/all/],
);

require XSLoader;
XSLoader::load('Data::LnArray::XS', $VERSION);

sub splice {
	splice @{$_[0]}, $_[1], $_[2], ($_[3] ? $_[3] : ());
        return $_[0];
}

1;

__END__

=head1 NAME

Data::LnArray::XS - Arrays

=head1 VERSION

Version 0.11

=cut

=head1 SYNOPSIS

	use Data::LnArray::XS;

	my $foo = Data::LnArray::XS->new(qw/last night in paradise/);

	$foo->push('!');

	...

	use Data::LnArray::XS qw/all/;

	my $okay = arr(qw/one two three/);

=head1 Exports

=head2 arr

Shorthand for generating a new Data::LnArray::XS Object.

	my $dlna = arr(qw/.../);

	$dlna->$method;

=head1 SUBROUTINES/METHODS

=head2 get

Returns the value of the passed index

	$foo->get(0);

=head2 set

Sets the value of the passed index.

	$foo->set(0, 'patience');

=head2 length

Returns an Integer that represents the length of the array.

	$foo->length;

=head2 from

Creates a new Data::LnArray instance from a string, array reference or hash reference.

	Data::LnArray->from(qw/foo/); # ['f', 'o', 'o']

	$foo->from([qw/one two three four/]); # ['one', 'two', 'three', 'four']

	$foo->from([qw/1 2 3/], sub { $_ + $_ }); # [2, 4, 6]

	$foo->from({length => 5}, sub { $_ + $_ }); # [0, 2, 4, 6, 8]

=head2 isArray

Returns a boolean, true if value is an array or false otherwise.

	$foo->isArray($other);

=head2 of

Creates a new Array instance with a variable number of arguments, regardless of number or type of the arguments.

	my $new = $array->of(qw/one two three four/);

=head2 copyWithin

Copies a sequence of array elements within the array.

	my $foo = Data::LnArray->new(qw/one two three four/);
	my $bar = $foo->copyWithin(0, 2, 3); # [qw/three four three four/];

	...

	my $foo = Data::LnArray->new(1, 2, 3, 4, 5);
	my $bar = $array->copyWithin(-2, -3, -1); # [1, 2, 3, 3, 4]

=head2 fill

Fills all the elements of an array from a start index to an end index with a static value.

	my $foo = Data::LnArray->new(1, 2, 3, 4, 5);
	$foo->fill(0, 2) # 0, 0, 0, 4, 5

=head2 pop

Removes the last element from an array and returns that element.

	$foo->pop;

=head2 push

Adds one or more elements to the end of an array, and returns the new length of the array.

	$foo->push(@new);

=head2 reverse

Reverses the order of the elements of an array in place. (First becomes the last, last becomes first.)

	$foo->reverse;

=head2 shift

Removes the first element from an array and returns that element.

	$foo->shift;

=head2 sort

Sorts the elements of an array in place and returns the array.

	$foo->sort(sub {
		$a <=> $b
	});

=head2 splice

Adds and/or removes elements from an array.

	$foo->splice(0, 1, 'foo');

=head2 unshift

Adds one or more elements to the front of an array, and returns the new length of the array.

	$foo->unshift;

=head2 concat

Returns a new array that is this array joined with other array(s) and/or value(s).

	$foo->concat($bar);

=head2 filter

Returns a new array containing all elements of the calling array for which the provided filtering callback returns true.

	$foo->filter(sub {
		$_ eq 'one'
	});

=head2 includes

Determines whether the array contains the value to find, returning true or false as appropriate.

	$foo->includes('one');

=head2 indexOf

Returns the first (least) index of an element within the array equal to search string, or -1 if none is found.

	$foo->indexOf('one');

=head2 join

Joins all elements of an array into a string.

	$foo->join('|');

=head2 lastIndexOf

Returns the last (greatest) index of an element within the array equal to search string, or -1 if none is found.

	$foo->lastIndexOf('two');

=head2 slice

Extracts a section of the calling array and returns a new array.

	$foo->slice(0, 2);

=head2 toString

Returns a string representing the array and its elements.

	$foo->toString;

=head2 toLocaleString

Returns a localized string representing the array and its elements. Overrides the Object.prototype.toLocaleString() method.

	TODO

=head2 entries()

Returns a new Array Iterator object that contains the key/value pairs for each index in the array.

	$foo->entries;
	# {
	#	0 => 'one',
	#	1 => 'two'
	# }

=head2 every

Returns true if every item in this array satisfies the testing callback.

	$foo->every(sub { ... });

=head2 find

Returns the found item in the array if some item in the array satisfies the testing callbackFn, or undefined if not found.

	$foo->find(sub { ... });

=head2 findIndex

Returns the found index in the array, if an item in the array satisfies the testing callback, or -1 if not found.

	$foo->findIndex(sub { ... });

=head2 forEach

Calls a callback for each element in the array.

	$foo->forEach(sub { ... });

=head2 keys

Returns a new Array that contains the keys for each index in the array.

	$foo->keys();

=head2 map

Returns a new array containing the results of calling the callback on every element in this array.

	my %hash = $foo->map(sub { ... });

=head2 reduce

Apply a callback against an accumulator and each value of the array (from left-to-right) as to reduce it to a single value.

	my $str = $foo->reduce(sub { $_[0] + $_[1] });

=head2 reduceRight

Apply a callback against an accumulator and each value of the array (from right-to-left) as to reduce it to a single value.

	my $str = $foo->reduceRight(sub { ... });

=head2 some

Returns true if at least one element in this array satisfies the provided testing callback.

	my $bool = $foo->some(sub { ... });

=head2 values

Returns the raw Array(list) of the Data::LnArray Object.

	my @values = $foo->values;

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-lnarray-xs at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-LnArray-XS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::LnArray::XS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-LnArray-XS>

=item * Search CPAN

L<https://metacpan.org/release/Data-LnArray-XS>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024->2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Data::LnArray::XS
