use 5.008;
use strict;
use warnings;

package Data::Miscellany;
our $VERSION = '1.100850';
# ABSTRACT: Collection of miscellaneous subroutines

use Exporter qw(import);
our %EXPORT_TAGS = (
    util => [
        qw/
          set_push flex_grep flatten is_deeply eq_array eq_hash
          is_defined value_of str_value_of class_map trim
          /
    ],
);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ] };

# Like push, but only pushes the item(s) onto the list indicated by the list
# ref (first param) if the list doesn't already contain it.
# Originally, I used Storable::freeze to see whether two structures where the
# same, but this didn't work for all cases, so I switched to is_deeply().
sub set_push (\@@) {
    my ($list, @items) = @_;
  ITEM:
    for my $item (@items) {
        for my $el (@$list) {
            next ITEM if is_deeply($item, $el);
        }
        push @$list, $item;
    }
}

sub flatten {
    ref $_[0] eq 'ARRAY' ? @{ $_[0] }
      : defined $_[0] ? @_
      :                 ();
}

# Start of code adapted from Test::More
#
# In set_push and other places within the framework, we need to compare
# structures deeply, so here are the relevant methods copied from Test::More
# with the test-specific code removed.
sub is_deeply {
    my ($this, $that) = @_;
    return _deep_check($this, $that) if ref $this && ref $that;
    return $this eq $that if defined $this && defined $that;

    # undef only matches undef and nothing else
    return !defined $this && !defined $that;
}

sub _deep_check {
    my ($e1, $e2) = @_;

    # Quiet uninitialized value warnings when comparing undefs.
    local $^W = 0;
    return 1 if $e1 eq $e2;
    return eq_array($e1, $e2)
      if UNIVERSAL::isa($e1, 'ARRAY') && UNIVERSAL::isa($e2, 'ARRAY');
    return eq_hash($e1, $e2)
      if UNIVERSAL::isa($e1, 'HASH') && UNIVERSAL::isa($e2, 'HASH');
    return _deep_check($$e1, $$e2)
      if UNIVERSAL::isa($e1, 'REF') && UNIVERSAL::isa($e2, 'REF');
    return _deep_check($$e1, $$e2)
      if UNIVERSAL::isa($e1, 'SCALAR') && UNIVERSAL::isa($e2, 'SCALAR');
    return 0;
}

sub eq_array {
    my ($a1, $a2) = @_;
    return 1 if $a1 eq $a2;
    return 0 unless $#$a1 == $#$a2;
    for (0 .. $#$a1) {
        return 0 unless is_deeply($a1->[$_], $a2->[$_]);
    }
    return 1;
}

sub eq_hash {
    my ($a1, $a2) = @_;
    return 1 if $a1 eq $a2;
    return 0 unless keys %$a1 == keys %$a2;
    foreach my $k (keys %$a1) {
        return 0 unless exists $a2->{$k};
        return 0 unless is_deeply($a1->{$k}, $a2->{$k});
    }
    return 1;
}

# End of code adapted from Test::More
# Handle value objects as well as normal scalars
sub is_defined ($) {
    my $value = shift;

    # restrict the method call to objects of type Class::Value, because we
    # want to avoid deep recursion that could happen if is_defined() is
    # imported into a package and then someone else calls is_defined() on an
    # object of that package.
    ref($value)
      && UNIVERSAL::isa($value, 'Class::Value')
      && UNIVERSAL::can($value, 'is_defined')
      ? $value->is_defined
      : defined($value);
}

sub value_of ($) {
    my $value = shift;

    # Explicitly return undef unless the value is_defined, because it could
    # still be a value object, in which case the value we want isn't the value
    # object itself, but 'undef'
    is_defined $value ? "$value" : undef;
}

sub str_value_of ($) {
    my $value = shift;
    is_defined $value ? "$value" : '';
}

sub flex_grep {
    my $wanted = shift;
    return grep { $_ eq $wanted }
      map { flatten($_) } @_;
}

sub class_map {
    my ($class, $map, $seen) = @_;

    # circularities
    $seen ||= {};

    # so we can pass an object as well as a class name:
    $class = ref $class if ref $class;
    return if $seen->{$class}++;
    my $val = $map->{$class};
    return $val if defined $val;

    # If there's no direct mapping for an exception class, check its
    # superclasses. Assumes that the classes are loaded, of course.
    no strict 'refs';
    for my $super (@{"$class\::ISA"}) {
        my $found = class_map($super, $map, $seen);

        # we will return UNIVERSAL if everything fails - so skip it.
        return $found if defined $found && $found ne $map->{UNIVERSAL};
    }
    return $map->{UNIVERSAL};
}

sub trim {
    my $s = shift;
    $s =~ s/^\s+//;
    $s =~ s/\s+$//;
    $s;
}
1;



__END__
=pod

=head1 NAME

Data::Miscellany - Collection of miscellaneous subroutines

=head1 VERSION

version 1.100850

=head1 SYNOPSIS

  use Data::Miscellany qw/set_push flex_grep/;

  my @foo = (1, 2, 3, 4);
  set_push @foo, 3, 1, 5, 1, 6;
  # @foo is now (1, 2, 3, 4, 5, 6);

  flex_grep('foo', [ qw/foo bar baz/ ]);                   # true
  flex_grep('foo', [ qw/bar baz flurble/ ]);               # false
  flex_grep('foo', 1..4, 'flurble', [ qw/foo bar baz/ ]);  # true
  flex_grep('foo', 1..4, [ [ 'foo' ] ], [ qw/bar baz/ ]);  # false

=head1 DESCRIPTION

This is a collection of miscellaneous subroutines useful in wide but varying
scenarios; a catch-all module for things that don't obviously belong anywhere
else. Obviously what's useful differs from person to person, but this
particular collection should be useful in object-oriented frameworks, such as
L<Class::Scaffold> and L<Data::Conveyor>.

=head1 FUNCTIONS

=head2 set_push(ARRAY, LIST)

Like C<push()>, but only pushes the item(s) onto the list indicated by the
list or list ref (the first argument) if the list doesn't already contain it.

Example:

    @foo = (1, 2, 3, 4);
    set_push @foo, 3, 1, 5, 1, 6;
    # @foo is now (1, 2, 3, 4, 5, 6)

=head2 flatten()

If the first argument is an array reference, it returns the dereferenced
array. If the first argument is undefined (or there are no arguments), it
returns the empty list. Otherwise the argument list is returned as is.

=head2 flex_grep(SCALAR, LIST)

Like C<grep()>, but compares the first argument to each flattened (see
C<flatten()>) version of each element of the list.

Examples:

    flex_grep('foo', [ qw/foo bar baz/ ])                     # true
    flex_grep('foo', [ qw/bar baz flurble/ ])                 # false
    flex_grep('foo', 1..4, 'flurble', [ qw/foo bar baz/ ])    # true
    flex_grep('foo', 1..4, [ [ 'foo' ] ], [ qw/bar baz/ ])    # false

=head2 is_deeply()

Like L<Test::More>'s C<is_deeply()> except that this version respects
stringification overloads. If a package overloads stringification, it means
that it specifies how it wants to be compared. Recent versions of
L<Test::More> break this behaviour, so here is a working version of
C<is_deeply()>. This subroutine only does the comparison; there are no test
diagnostics or results recorded or printed anywhere.

=head2 eq_array()

Like L<Test::More>'s C<eq_array()> except that this version respects
stringification overloads. If a package overloads stringification, it means
that it specifies how it wants to be compared. Recent versions of
L<Test::More> break this behaviour, so here is a working version of
C<eq_array()>. This subroutine only does the comparison; there are no test
diagnostics or results recorded or printed anywhere.

=head2 eq_hash()

Like L<Test::More>'s C<eq_hash()> except that this version respects
stringification overloads. If a package overloads stringification, it means
that it specifies how it wants to be compared. Recent versions of
L<Test::More> break this behaviour, so here is a working version of
C<eq_hash()>. This subroutine only does the comparison; there are no test
diagnostics or results recorded or printed anywhere.

=head2 is_defined(SCALAR)

A kind of C<defined()> that is aware of L<Class::Value>, which has its own
views of what is a defined value and what isn't. The issue arose since
L<Class::Value> objects are supposed to be used transparently, mixed with
normal scalar values. However, it is not possible to overload "definedness",
and C<defined()> used on a value object always returns true since the
object reference certainly exists. However, what we want to know is
whether the value encapsulated by the value object is defined.
Additionally, each value class can have its own ideas of when its
encapsulated value is defined. Therefore, L<Class::Value> has an
C<is_defined()> method.

This subroutine checks whether its argument is a value object and if so, calls
the value object's C<is_defined()> method. Otherwise, the normal C<defined()>
is used.

=head2 value_of(SCALAR)

Stringifies its argument, but returns undefined values (per C<is_defined()>)
as C<undef>.

=head2 str_value_of(SCALAR)

Stringifies its argument, but returns undefined values (per C<is_defined()>)
as the empty string.

=head2 class_map(SCALAR, HASH)

Takes an object or class name as the first argument (if it's an object, the
class name used will be the package name the object is blessed into).
Takes a hash whose keys are class names as the second argument. The hash
values are completely arbitrary.

Looks up the given class name in the hash and returns the corresponding value.
If no such hash key is found, the class hierarchy for the given class name is
traversed depth-first and checked against the hash keys in turn. The first
value found is returned.

If no key is found, a special key, C<UNIVERSAL> is used.

As an example of how this might be used, consider a hierarchy of exception
classes. When evaluating each exception, we want to know how severe this
exception is, so we define constants for C<RC_OK> (meaning it's informational
only), C<RC_ERROR> (meaning some sort of action should be taken) and
C<RC_INTERNAL_ERROR> (meaning something has gone badly wrong and we might halt
processing). In the following table assume that if you have names like
C<Foo::Bar> and C<Foo::Bar::Baz>, then the latter subclasses the former.

    %map = (
        'UNIVERSAL'                                => RC_INTERNAL_ERROR,
        'My::Exception::Business'                  => RC_ERROR,
        'My::Exception::Internal'                  => RC_INTERNAL_ERROR,
        'My::Exception::Business::ValueNormalized' => RC_OK,
    );

Assuming that C<My::Exception::Business::IllegalValue> exists and that it
subclasses C<My::Exception::Business>, here are some outcomes:

    class_map('My::Exception::Business::IllegalValue', \%map)     # RC_ERROR
    class_map('My::Exception::Business::ValueNormalzed', \%map)   # RC_OK

=head2 trim(STRING)

Trims off whitespace at the beginning and end of the string and returns the
trimmed string.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Miscellany>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Data-Miscellany/>.

The development version lives at
L<http://github.com/hanekomu/Data-Miscellany/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

