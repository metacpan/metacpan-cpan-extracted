package Data::LnArray;
use strict;
no warnings;
use base 'Import::Export';
our $VERSION = '0.03';

our %EX = (
        arr => [qw/all/],
);

sub arr {
	Data::LnArray->new(@_);
}

sub new {
	my $class = shift;
	bless [@_], __PACKAGE__;
}

sub length {
	my ($self) = shift;

	scalar @{$self};
}

sub retrieve {
	my ($self) = shift;

	# probably is not going to work
	return @{$self};
}

sub from {
	my ($self) = shift;

	my ( $data, $code ) = @_;
	my $ref = ref $data;
	my @data
	    = !$ref ? split //, $data
	    : $ref eq 'ARRAY' ? @{$data}
	    : do {
		die 'currently cannot handle' unless $data->{length};
		0 .. $data->{length} - 1;
	    };
	return $self->new( $code ? map { $code->($_) } @data : @data );
}

sub isArray {
	my ($self) = shift;

	my ($data) = @_;
	my $ref = ref $data || "";
	$ref eq 'ARRAY' ? \1 : \0;
}

sub of {
	my ($self) = shift;

	return $self->new(@_);
}

sub copyWithin {
	my ($self) = shift;

	my ( $target, $start, $end ) = @_;
	my $length = $self->length;

	my $to
	    = $target < 0
	    ? $self->mmax( $length + $target, 0 )
	    : $self->mmin( $target, $length );

	my $from
	    = $start < 0
	    ? $self->mmax( $length + $start, 0 )
	    : $self->mmin( $start, $length );

	$end = defined $end ? $end : $length;
	my $final
	    = $end < 0
	    ? $self->mmax( $length + $end, 0 )
	    : $self->mmin( $end, $length );

	my $count = $self->mmin( $final - $from, $length - $to );

	my $direction = 1;

	if ( $from < $to && $to < ( $from + $count ) ) {
		$direction = -1;
		$from += $count - 1;
		$to   += $count - 1;
	}

	while ( $count > 0 ) {
		$self->[$to] = $self->[$from];
		$from += $direction;
		$to   += $direction;
		$count--;
	}

	return $self;
}

sub fill {
	my ($self) = shift;

	my ( $target, $start, $end ) = @_;
	my $length = $self->length;

	my $from
	    = $start < 0
	    ? $self->mmax( $length + $start, 0 )
	    : $self->mmin( $start, $length );

	$end = defined $end ? $end : $length - 1;
	my $final
	    = $end < 0
	    ? $self->mmax( $length + $end, 0 )
	    : $self->mmin( $end, $length );
	while ( $from <= $final ) {
		$self->[$from] = $target;
		$from++;
	}

	return $self;
}

sub pop {
	my ($self) = shift;

	pop @{$self};
}

sub push {
	my ($self) = shift;

	push @{$self}, @_;
}

sub reverse {
	my ($self) = shift;

	return $self->new( reverse @{$self} );
}

sub shift {
	my ($self) = shift;

	shift @{$self};
}

sub sort {
	my ($self) = shift;

	my $sort  = shift;
	my @array = grep { ref $_ ne 'CODE' } sort $sort, @{$self};
	$self->new(@array);
}

sub splice {
	my ($self) = shift;

	my ( $offset, $length, $target ) = @_;
	if ( defined $target ) {
		splice @{$self}, $offset, $length, $target;
	}
	else {
		splice @{$self}, $offset, $length;
	}
	return $self;
}

sub unshift {
	my ($self) = shift;

	my ($target) = @_;
	unshift @{$self}, $target;
	return $self;
}

sub concat {
	my ($self) = shift;

	my ($array) = @_;
	push @{$self}, @{$array};
	return $self;
}

sub filter {
	my ($self) = shift;

	my $grep = shift;
	my @new;
	for ( @{$self} ) {
		if ( $grep->($_) ) {
			push @new, $_;
		}
	}
	return $self->new(@new);
}

sub includes {
	my ($self) = shift;

	my @match = grep { $_[0] =~ m/$_/ } @{$self};
	scalar @match ? \1 : \0;
}

sub indexOf {
	my ($self) = shift;

	my $i = 0;
	for ( @{$self} ) {
		return $i if $_ eq $_[0];
		$i++;
	}
	return -1;
}

sub join {
	my ($self) = shift;

	join $_[0], @{$self};
}

sub lastIndexOf {
	my ($self) = shift;

	for ( my $i = $self->length - 1; $i >= 0; $i-- ) {
		return $i if $self->[$i] eq $_[0];
	}
}

sub slice {
	my ($self) = shift;

	my ( $begin, $end ) = @_;
	my @de = @{$self};
	return $self->new( @de[ $begin, $end ] );
}

sub toString {
	my ($self) = shift;

	return $self->join(',');
}

sub toLocaleString {
	my ($self) = shift;

	die 'TODO DateTime';
}

sub entries {
	my ($self) = shift;

	my %entries;
	for ( my $i = $self->length - 1; $i >= 0; $i-- ) {
		$entries{$i} = $self->[$i];
	}
	return %entries;
}

sub every {
	my ($self) = shift;

	my $cb = shift;
	for ( @{$self} ) {
		return \0 unless $cb->($_);
	}
	return \1;
}

sub find {
	my ($self) = shift;

	my $cb = shift;
	for ( @{$self} ) {
		return $_ if $cb->($_);
	}
	return;
}

sub findIndex {
	my ($self) = shift;

	my $cb = shift;
	my $i  = 0;
	for ( @{$self} ) {
		return $i if $cb->($_);
		$i++;
	}
	return;
}

sub forEach {
	my ($self) = shift;

	my ($code) = @_;
	my @out;
	for (@$self) {
		push @out, $code->($_);
	}
	return @out;
}

sub keys {
	my ($self) = shift;

	return 0 .. $self->length - 1;
}

sub map {
	my ($self) = shift;

	my ( $cb, @new ) = (shift);
	for ( @{$self} ) {
		push @new, $cb->($_);
	}
	return $self->new(@new);
}

sub reduce {
	my ($self) = shift;

	my ( $cb, $reduced ) = ( shift, shift );
	for ( @{$self} ) {
		$reduced = $cb->( $reduced, $_ );
	}
	return $reduced;
}

sub reduceRight {
	my ($self) = shift;

	my $rev = $self->reverse;
	return $rev->reduce(@_);
}

sub some {
	my ($self) = shift;

	my ($cb) = (shift);
	for ( @{$self} ) {
		return \1 if $cb->($_);
	}
	return \0;
}

sub values {
	my ($self) = shift;
	return @{$self};
}

sub mmax {
	my ($self)  = shift;
	my $caller  = caller();
	my @allowed = qw//;
	unless ( $caller eq __PACKAGE__ || grep { $_ eq $caller } @allowed ) {
		die "cannot call private method mmax from $caller";
	}
	$_[ ( $_[0] || 0 ) < ( $_[1] || 0 ) ] || 0;
}

sub mmin {
	my ($self)  = shift;
	my $caller  = caller();
	my @allowed = qw//;
	unless ( $caller eq __PACKAGE__ || grep { $_ eq $caller } @allowed ) {
		die "cannot call private method mmin from $caller";
	}
	$_[ ( $_[0] || 0 ) > ( $_[1] || 0 ) ] || 0;
}

1;

=head1 NAME

Data::LnArray - The great new Data::LnArray!

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

	use Data::LnArray;

	my $foo = Data::LnArray->new(qw/last night in paradise/);
	

	$foo->push('!');

	...

	use Data::LnArray qw/all/;

	my $okay = arr(qw/one two three/);

=head1 Exports

=head2 arr

Shorthand for generating a new Data::LnArray Object.

	my $dlna = arr(qw/.../);

	$dlna->$method;


=head1 SUBROUTINES/METHODS

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

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lnarray at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-LnArray>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::LnArray

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-LnArray>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-LnArray>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Data-LnArray>

=item * Search CPAN

L<https://metacpan.org/release/Data-LnArray>

=back

=head1 ACKNOWLEDGEMENTS

MDN Array
L<https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array#Static_methods>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
