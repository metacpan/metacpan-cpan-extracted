package Data::Enum;

# ABSTRACT: immutable enumeration classes

use v5.14;
use warnings;

use Package::Stash;
use List::Util 1.45 qw/ any uniqstr /;
use Scalar::Util qw/ blessed refaddr /;

# RECOMMEND PREREQ: Package::Stash::XS

use overload
  q{""} => \&as_string,
  q{eq} => \&MATCH,
  q{ne} => \&_NOT_MATCH;

use constant TRUE  => 1;
use constant FALSE => 0;

our $VERSION = 'v0.4.0';


sub new {
    my $this = shift;

    my $opts   = ref( $_[0] ) eq "HASH" ? shift : {};
    my $prefix = $opts->{prefix} // "is_";

    my @values = uniqstr( sort map { "$_" } @_ );

    die "has no values" unless @values;

    die "values must be alphanumeric" if any { /\W/ } @values;

    my $key = join chr(28), @values;

    state %Cache;
    state $Counter = 1;

    if ( my $name = $Cache{$key} ) {
        return $name;
    }

    my $name = __PACKAGE__ . "::" . $Counter++;

    my $base = Package::Stash->new($name);

    my $_make_symbol = sub {
        my ($value) = @_;
        my $self    = bless \$value, "${name}::${value}";
        Internals::SvREADONLY( $value, 1 );
        return $self;
    };

    my $_make_predicate = sub {
        my ($value) = @_;
        return $prefix . $value;
    };

    $base->add_symbol(
        '&new',
        sub {
            my ( $class, $value ) = @_;
            state $symbols = {
                map { $_ => $_make_symbol->($_) } @values
            };
            exists $symbols->{"$value"} or die "invalid value: '$value'";
            return $symbols->{"$value"};
        }
    );

    $base->add_symbol( '&values', sub { return @values } );

    $base->add_symbol(
        '&predicates',
        sub {
            return map { $_make_predicate->($_) } @values;
        }
    );

    $base->add_symbol( '&prefix', sub { $prefix } );

    for my $value (@values) {
        my $predicate = $_make_predicate->($value);
        $base->add_symbol( '&' . $predicate, \&FALSE );
        my $elem    = "${name}::${value}";
        my $subtype = Package::Stash->new($elem);
        $subtype->add_symbol( '@ISA',           [ __PACKAGE__, $name ] );
        $subtype->add_symbol( '&' . $predicate, \&TRUE );
    }

    return $Cache{$key} = $name;
}

sub _NOT_MATCH {
    my ( $self, $arg ) = @_;
    return blessed($arg)
      ? refaddr($arg) != refaddr($self)
      : $arg ne $$self;
}


sub MATCH {
    my ( $self, $arg ) = @_;
    return blessed($arg)
      ? refaddr($arg) == refaddr($self)
      : $arg eq $$self;
}


sub as_string {
    my ($self) = @_;
    return $$self;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Enum - immutable enumeration classes

=head1 VERSION

version v0.4.0

=head1 SYNOPSIS

  use Data::Enum;

  my $color = Data::Enum->new( qw[ red yellow blue green ] );

  my $red = $color->new("red");

  $red->is_red;    # "1"
  $red->is_yellow; # "0" (false)
  $red->is_blue;   # "0" (false)
  $red->is_green;  # "0" (false)

  say $red;        # outputs "red"

  $red eq $color->new("red"); # true

  $red eq "red"; # true

=head1 DESCRIPTION

This module will create enumerated constant classes with the following
properties:

=over

=item *

Any two classes with the same elements are equivalent.

The following two classes are the I<same>:

  my $one = Data::Enum->new( qw[ foo bar baz ] );
  my $two = Data::Enum->new( qw[ baz bar foo ] );

=item *

All class instances are singletons.

  my $one = Data::Enum->new( qw[ foo bar baz ] );

  my $a = $one->new("foo")
  my $b = $one->new("foo");

  refaddr($a) == refaddr($b); # they are the same thing

=item *

Methods for checking values are fast.

  $a->is_foo; # constant time

  $a eq $b;   # compares refaddr

=item *

Values are immutable (read-only).

=back

This is done by creating a unique internal class name based on the
possible values.  Each value is actually a subclass of that class,
with the appropriate predicate method returning a constant.

=head1 METHODS

=head2 new

  my $class = Data::Enum->new( @values );

This creates a new anonymous class. Values can be instantiated with a
constructor:

  my $instance = $class->new( $value );

Calling the constructor with an invalid value will throw an exception.

Each instance will have an C<is_> method for each value.

Each instance stringifies to its value.

Since v0.3.0 you can change the method prefix of the predicate methods to something other than C<is_>. For example,

  my $class = Data::Enum->new( { prefix => "from_" }, "home", "work" );
  my $place = $class->new("work");

  $place->from_home;

=head2 values

  my @values = $class->values;

Returns a list of valid values, stringified and sorted with duplicates
removed.

This was added in v0.2.0.

=head2 predicates

  my @predicates = $class->predicates;

Returns a list of predicate methods for each value.

A hash of predicates to values is roughly

  use List::Util 1.56 'mesh';

  my %handlers = mesh [ $class->values ], [ $class->predicates ];

This was added in v0.2.1.

=head2 prefix

This returns the prefix.

This was added in v0.3.0.

=head2 MATCH

This method adds support for L<match::simple>.

=head2 as_string

This stringifies the the object.

This was added in v0.4.0.

=for Pod::Coverage TRUE

=for Pod::Coverage FALSE

=head1 CAVEATS

The overheard of creating a new class instance and resolving methods may actually take more time than comparing simple
strings.  When using this in production code, you may want to benchmark performance.

=head1 SUPPORT FOR OLDER PERL VERSIONS

This module requires Perl v5.14 or later.

Future releases may only support Perl versions released in the last ten years.

=head1 SEE ALSO

L<Class::Enum>

L<Object::Enum>

L<MooX::Enumeration>

L<MooseX::Enumeration>

L<Type::Tiny::Enum>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Data-Enum>
and may be cloned from L<git://github.com/robrwo/perl-Data-Enum.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Data-Enum/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021-2024 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
