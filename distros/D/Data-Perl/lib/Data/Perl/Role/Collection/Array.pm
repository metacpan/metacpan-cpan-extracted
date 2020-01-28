package Data::Perl::Role::Collection::Array;
$Data::Perl::Role::Collection::Array::VERSION = '0.002011';
# ABSTRACT: Wrapping class for Perl's built in array structure.

use strictures 1;

use Role::Tiny;
use List::Util;
use List::MoreUtils;
use Scalar::Util qw/blessed/;

sub new {
  my $cl = CORE::shift; bless([ @_ ], $cl)
}

# find the package name if possible else default to __PACKAGE__
#sub _blessed { blessed($_[0]) || __PACKAGE__ }

sub count { CORE::scalar @{$_[0]} }

sub is_empty { CORE::scalar @{$_[0]} ? 0 : 1 }

{
  no warnings 'once';
  sub all { @{$_[0]} }

  *elements = *all;
  *flatten = *all;
}

sub get { $_[0]->[ $_[1] ] }

sub pop { CORE::pop @{$_[0]} }

sub push { CORE::push @{$_[0]}, @_[1..$#_] }

sub shift { CORE::shift @{$_[0]} }

sub unshift { CORE::unshift @{$_[0]}, @_[1..$#_] }

sub clear { @{$_[0]} = () }

sub first { &List::Util::first($_[1], @{$_[0]}) }

sub first_index { &List::MoreUtils::first_index($_[1], @{$_[0]}) }

sub reduce { List::Util::reduce { $_[1]->($a, $b) } @{$_[0]} }

sub set { $_[0]->[ $_[1] ] = $_[2] }

sub accessor {
  if (@_ == 2) {
    $_[0]->[$_[1]];
  }
  elsif (@_ > 2) {
    $_[0]->[$_[1]] = $_[2];
  }
}

sub natatime {
  my $iter = List::MoreUtils::natatime($_[1], @{$_[0]});

  if ($_[2]) {
    while (my @vals = $iter->()) {
      $_[2]->(@vals);
    }
  }
  else {
    $iter;
  }
}

sub shallow_clone { blessed($_[0]) ? bless([@{$_[0]}], ref $_[0]) : [@{$_[0]}] }

# Data::Collection methods that return a Data::Perl::Collection::Array object
#sub members {
#  my ($self) = @_;
#  qw/map grep member_count sort reverse print any all one none join/;
#}


sub map {
  my ($self, $cb) = @_;

  my @res = CORE::map { $cb->($_) } @$self;

  blessed($self) ? blessed($self)->new(@res) : @res;
}

sub grep {
  my ($self, $cb) = @_;

  my @res = CORE::grep { $cb->($_) } @$self;

  blessed($self) ? blessed($self)->new(@res) : @res;
}

sub sort {
  my ($self, $cb) = @_;

  my @res = $cb ? CORE::sort { $cb->($a, $b) } @$self : CORE::sort @$self;

  blessed($self) ? blessed($self)->new(@res) : @res;
}

sub reverse {
  my ($self) = @_;

  my @res = CORE::reverse @$self;

  blessed($self) ? blessed($self)->new(@res) : @res;
}

sub sort_in_place {
  @{$_[0]} = ($_[1] ? sort { $_[1]->($a, $b) } @{$_[0]} : sort @{$_[0]});
  $_[0];
}

sub splice {
  my ($self) = @_;

  my @res = CORE::splice @{$_[0]}, $_[1], $_[2], @_[3..$#_];

  blessed($self) ? blessed($self)->new(@res) : @res;
}

sub shuffle {
  my ($self) = @_;

  my @res = List::Util::shuffle(@$self);

  blessed($self) ? blessed($self)->new(@res) : @res;
}

sub uniq {
  my ($self) = @_;

  my @res = List::MoreUtils::uniq(@$self);

  blessed($self) ? blessed($self)->new(@res) : @res;
}

sub delete {
  my ($self, $idx) = @_;

  my ($res) = CORE::splice(@$self, $idx, 1);

  $res;
}

sub insert {
  my ($self, $idx, $el) = @_;

  my ($res) = CORE::splice(@$self, $idx, 0, $el);

  $res;
}

sub flatten_deep {
  my ($self, $depth) = @_;

  _flatten_deep(@$self, $depth);
}

sub _flatten_deep {
  my @array = @_;
  my $depth = CORE::pop @array;
  --$depth if (defined($depth));

  my @elements = CORE::map {
      (ref eq 'ARRAY')
          ? (defined($depth) && $depth == -1) ? $_ : _flatten_deep( @$_, $depth )
          : $_
  } @array;
}

sub join {
  my ($self, $with) = @_;

  CORE::join((defined $with ? $with : ','), @$self);
}

sub print {
  my ($self, $fh, $arg) = @_;

  print { $fh || *STDOUT } CORE::join((defined $arg ? $arg : ','), @$self);
}

sub head {
  my ($self, $count) = @_;

  $count = $self->count if $count > $self->count;
  $count = $self->count - -$count if $count < 0;

  my @res = ($self->elements)[0 .. $count - 1];

  blessed($self) ? blessed($self)->new(@res) : @res;
}

sub tail {
  my ($self, $count) = @_;

  $count = $self->count if $count > $self->count;
  $count = $self->count - -$count if $count < 0;
  my $start = $self->count - $count;

  my @res = ($self->elements)[$start .. $self->count - 1];

  blessed($self) ? blessed($self)->new(@res) : @res;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Data::Perl::Role::Collection::Array - Wrapping class for Perl's built in array structure.

=head1 VERSION

version 0.002011

=head1 SYNOPSIS

  use Data::Perl qw/array/;

  my $array = array(1, 2, 3);

  $array->push(5);

  $array->grep(sub { $_ > 2 })->map(sub { $_ ** 2 })->elements; # (3, 5);

=head1 DESCRIPTION

This class provides a wrapper and methods for interacting with an array.
All methods that return a list do so via a Data::Perl::Collection::Array object.

=head1 PROVIDED METHODS

=over 4

=item B<new($value, $value, ....)>

Constructs a new Data::Perl::Collection::Array object initialized with passed
in values, and returns it.

=item B<count>

Returns the number of elements in the array.

  $stuff = Data::Perl::Collection::Array->new(qw/foo bar baz boo/);

  print $stuff->count; # prints 4

This method does not accept any arguments.

=item B<is_empty>

Returns a boolean value that is true when the array has no elements.

  $stuff->is_empty ? die "No options!\n" : print "Good boy.\n";

This method does not accept any arguments.

=item B<elements/all>

Returns all of the elements of the array as an array (not an array reference).

  my @options = $stuff->elements;
  print "@options\n";    # prints "foo bar baz boo"

This method does not accept any arguments.

=item B<get($index)>

Returns an element of the array by its index. You can also use negative index
numbers, just as with Perl's core array handling.

  my $option = $stuff->get(1);
  print "$option\n";    # prints "bar"

If the specified element does not exist, this will return C<undef>.

This method accepts just one argument.

=item B<pop>

Just like Perl's builtin C<pop>.

This method does not accept any arguments.

=item B<push($value1, $value2, value3 ...)>

Just like Perl's builtin C<push>. Returns the number of elements in the new
array.

This method accepts any number of arguments.

=item B<shift>

Just like Perl's builtin C<shift>.

This method does not accept any arguments.

=item B<unshift($value1, $value2, value3 ...)>

Just like Perl's builtin C<unshift>. Returns the number of elements in the new
array.

This method accepts any number of arguments.

=item B<splice($offset, $length, @values)>

Just like Perl's builtin C<splice>. In scalar context, this returns the last
element removed, or C<undef> if no elements were removed. In list context, this
returns all the elements removed from the array, wrapped in a Collection::Array
object.

This method requires at least one argument.

=item B<first( sub { ... } )>

This method returns the first matching item in the array, just like
L<List::Util>'s C<first> function. The matching is done with a subroutine
reference you pass to this method. The subroutine will be called against each
element in the array until one matches or all elements have been checked.

  my $found = $stuff->find_option( sub {/^b/} );
  print "$found\n";    # prints "bar"

This method requires a single argument.

=item B<first_index( sub { ... } )>

This method returns the index of the first matching item in the array, just
like L<List::MoreUtils>'s C<first_index> function. The matching is done with a
subroutine reference you pass to this method. The subroutine will be called
against each element in the array until one matches or all elements have been
checked.

This method requires a single argument.

=item B<grep( sub { ... } )>

This method returns every element matching a given criteria, just like Perl's
core C<grep> function. This method requires a subroutine which implements the
matching logic. The returned list is provided as a Collection::Array object.

  my @found = $stuff->grep( sub {/^b/} );
  print "@found\n";    # prints "bar baz boo"

This method requires a single argument.

=item B<map( sub { ... } )>

This method transforms every element in the array and returns a new array, just
like Perl's core C<map> function. This method requires a subroutine which
implements the transformation. The returned list is provided as
a Collection::Array object.

  my @mod_options = $stuff->map( sub { $_ . "-tag" } );
  print "@mod_options\n";    # prints "foo-tag bar-tag baz-tag boo-tag"

This method requires a single argument.

=item B<reduce( sub { ... } )>

This method turns an array into a single value, by passing a function the
value so far and the next value in the array, just like L<List::Util>'s
C<reduce> function. The reducing is done with a subroutine reference you pass
to this method.

  my $found = $stuff->reduce( sub { $_[0] . $_[1] } );
  print "$found\n";    # prints "foobarbazboo"

This method requires a single argument.

=item B<sort>

=item B<sort( sub { ... } )>

Returns the elements of the array in sorted order.

You can provide an optional subroutine reference to sort with (as you can with
Perl's core C<sort> function). However, instead of using C<$a> and C<$b> in
this subroutine, you will need to use C<$_[0]> and C<$_[1]>. The returned list
is provided as a Collection::Array object.

  # ascending ASCIIbetical
  my @sorted = $stuff->sort();

  # Descending alphabetical order
  my @sorted_options = $stuff->sort( sub { lc $_[1] cmp lc $_[0] } );
  print "@sorted_options\n";    # prints "foo boo baz bar"

This method accepts a single argument.

=item B<sort_in_place>

=item B<sort_in_place( sub { ... } )>

Sorts the array I<in place>, modifying the value of the attribute.

You can provide an optional subroutine reference to sort with (as you can with
Perl's core C<sort> function). However, instead of using C<$a> and C<$b>, you
will need to use C<$_[0]> and C<$_[1]> instead. The returned list is provided
as a Collection::Array object.

This method accepts a single argument.

=item B<reverse>

Returns the elements of the array in reversed order. The returned list is
provided as a Collection::Array object.

This method does not accept any arguments.

=item B<shuffle>

Returns the elements of the array in random order, like C<shuffle> from
L<List::Util>. The returned list is provided as a Collection::Array object.

This method does not accept any arguments.

=item B<uniq>

Returns the array with all duplicate elements removed, like C<uniq> from
L<List::MoreUtils>. The returned list is provided as a Collection::Array object.

This method does not accept any arguments.

=item B<head($count)>

Returns the first C<$count> elements of the array. If C<$count> is greater
than the number of elements in the array, the array (without spurious C<undef>s)
is returned. Negative C<$count> means "all but the last C<$count> elements". The
returned list is provided as a Collection::Array object.

=item B<tail($count)>

Returns the last C<$count> elements of the array. If C<$count> is greater
than the number of elements in the array, the array (without spurious C<undef>s)
is returned. Negative C<$count> means "all but the first C<$count> elements". The
returned list is provided as a Collection::Array object.

=item B<join($str)>

Joins every element of the array using the separator given as argument, just
like Perl's core C<join> function.

  my $joined = $stuff->join(':');
  print "$joined\n";    # prints "foo:bar:baz:boo"

This method requires a single argument.

=item B<print($handle, $str)>

Prints the output of join($str) to $handle. $handle defaults to STDOUT, and
join $str defaults to join()'s default of ','.

  $joined = $stuff->print(*STDERR, ';'); # prints foo;bar;baz to STDERR

=item B<set($index, $value)>

Given an index and a value, sets the specified array element's value.

This method returns the value at C<$index> after the set.

This method requires two arguments.

=item B<delete($index)>

Removes the element at the given index from the array.

This method returns the deleted value, either as an array or scalar as
dependent on splice context semantics. Note that if no value exists, it will

return C<undef>.

This method requires one argument.

=item B<insert($index, $value)>

Inserts a new element into the array at the given index.

This method returns the new value at C<$index>, either as an array or scalar as
dependent on splice context semantics.

This method requires two arguments.

=item B<clear>

Empties the entire array, like C<@array = ()>.

This method does not define a return value.

This method does not accept any arguments.

=item B<accessor($index)>

=item B<accessor($index, $value)>

This method provides a get/set accessor for the array, based on array indexes.
If passed one argument, it returns the value at the specified index.  If
passed two arguments, it sets the value of the specified index.

When called as a setter, this method returns the new value at C<$index>.

This method accepts one or two arguments.

=item B<natatime($n)>

=item B<natatime($n, $code)>

This method returns an iterator which, on each call, returns C<$n> more items
from the array, in order, like C<natatime> from L<List::MoreUtils>. A coderef
can optionally be provided; it will be called on each group of C<$n> elements
in the array.

This method accepts one or two arguments.

=item B<shallow_clone>

This method returns a shallow clone of the array reference.  The return value
is a reference to a new array with the same elements.  It is I<shallow>
because any elements that were references in the original will be the I<same>
references in the clone.

=item B<flatten>

This method returns a list of elements in the array.  This method is an alias
to the I<elements> method.

=item B<flatten_deep($level)>

This method returns a flattened list of elements in the array. Will flatten
arrays contained within the root array recursively - depth is controlled by the
optional $level parameter.

=back

=head1 SEE ALSO

=over 4

=item * L<Data::Perl>

=item * L<MooX::HandlesVia>

=back

=head1 AUTHOR

Matthew Phillips <mattp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Matthew Phillips <mattp@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
==pod

