package Class::Type::Enum;
# ABSTRACT: Build Enum-like classes
$Class::Type::Enum::VERSION = '0.014';

use strict;
use warnings;

use Carp qw(croak);
use Class::Method::Modifiers qw(install_modifier);
use List::Util 1.33;
use Scalar::Util qw(blessed);

use namespace::clean;

use overload (
  '""'     => 'stringify',
  'cmp'    => 'cmp',
  '0+'     => 'numify',
  fallback => 1,
);



sub import {
  my ($class, %params) = @_;

  # import is inherited, but we don't want to do all this to everything that
  # uses a subclass of Class::Type::Enum.
  return unless $class eq __PACKAGE__;
  # If there's a use case for it, we can still allow extending CTE subclasses.

  my $target = caller;

  my %values;

  if (ref $params{values} eq 'ARRAY') {
    my $i = 0;
    %values = map { $_ => $i++ } @{$params{values}};
  }
  elsif (ref $params{values} eq 'HASH') {
    %values = %{$params{values}};
  }
  else {
    croak "Enum values must be provided either as an array or hash ref.";
  }

  ## the bits that are installed into the target class, plus @ISA
  {
    no strict 'refs';
    push @{"${target}::ISA"}, $class;
  }
  install_modifier $target, 'fresh', sym_to_ord => sub { \%values };
  install_modifier $target, 'fresh', ord_to_sym => sub { +{ reverse(%values) } };

  install_modifier $target, 'fresh', values => sub {
    my $ord = $_[0]->sym_to_ord;
    [ sort { $ord->{$a} <=> $ord->{$b} } keys %values ];
  };

  for my $value (keys %values) {
    install_modifier $target, 'fresh', "is_$value" => sub { $_[0]->is($value) };
  }
}



sub new {
  my ($class, $value) = @_;

  (blessed($class) || $class)->inflate_symbol($value);
}


sub inflate_symbol {
  my ($class, $symbol) = @_;

  my $ord = $class->sym_to_ord->{$symbol};

  croak "Value [$symbol] is not valid for enum $class"
    unless defined $ord;

  bless \$ord, $class;
}


sub inflate_ordinal {
  my ($class, $ord) = @_;

  croak "Ordinal [$ord] is not valid for enum $class"
    unless exists $class->ord_to_sym->{$ord};

  bless \$ord, $class;
}


sub list_is_methods {
  my ($class) = @_;

  map "is_$_", @{$class->values};
}


sub type_constraint {
  my ($class) = @_;

  require Type::Tiny::Class;
  require Types::Standard;
  Type::Tiny::Class->new(class => blessed($class) || $class)
    ->plus_constructors(Types::Standard::Str(), 'inflate_symbol');
}


sub test_symbol {
  my ($class, $value) = @_;

  exists($class->sym_to_ord->{$value})
}


sub test_ordinal {
  my ($class, $value) = @_;

  exists($class->ord_to_sym->{$value})
}


sub coerce_symbol {
  my ($class, $value) = @_;
  return $value if eval { $value->isa($class) };

  $class->inflate_symbol($value);
}


sub coerce_ordinal {
  my ($class, $value) = @_;
  return $value if eval { $value->isa($class) };

  $class->inflate_ordinal($value);
}


sub coerce_any {
  my ($class, $value) = @_;
  return $value if eval { $value->isa($class) };

  for my $method (qw( inflate_ordinal inflate_symbol )) {
    my $enum = eval { $class->$method($value) };
    return $enum if $enum;
  }
  croak "Could not coerce invalid value [$value] into $class";
}



sub is {
  my ($self, $value) = @_;
  my $ord = $self->sym_to_ord->{$value};

  croak "Value [$value] is not valid for enum " . blessed($self)
    unless defined $ord;

  $$self == $ord;
}



sub stringify {
  my ($self) = @_;
  $self->ord_to_sym->{$$self};
}


sub numify {
  my ($self) = @_;
  $$self;
}


sub cmp {
  my ($self, $other, $reversed) = @_;
  return -1 * $self->cmp($other) if $reversed;

  return $$self <=> $other if blessed($other);

  my $ord = $self->sym_to_ord->{$other};
  croak "Cannot compare to invalid symbol [$other] for " . blessed($self)
    unless defined $ord;

  return $$self <=> $ord;
}


sub any {
  my ($self, @cases) = @_;

  List::Util::any { $self->is($_) } @cases;
}


sub none {
  my ($self, @cases) = @_;

  List::Util::none { $self->is($_) } @cases;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::Type::Enum - Build Enum-like classes

=head1 VERSION

version 0.014

=head1 SYNOPSIS

  package Toast::Status {
    use Class::Type::Enum values => ['bread', 'toasting', 'toast', 'burnt'];
  }

  package Toast {
    use Moo;

    has status => (
      is      => 'rw',
      isa     => Toast::Status->type_constraint,
      coerce  => 1,
      handles => [ Toast::Status->list_is_methods ],
    );
  }

  my @toast = map { Toast->new(status => $_) } qw( toast burnt bread bread toasting toast );

  my @trashcan = grep { $_->is_burnt } @toast;
  my @plate    = grep { $_->is_toast } @toast;

  my $ready_status   = Toast::Status->new('toast');
  my @eventual_toast = grep { $_->status < $ready_status } @toast;

  # or:

  @eventual_toast = grep { $_->status lt 'toast' } @toast;

  # or:

  @eventual_toast = grep { $_->status->none('toast', 'burnt') } @toast;

=head1 DESCRIPTION

Class::Type::Enum is a class builder for type-like classes to represent your
enumerated values.  In particular, it was built to scratch an itch with
L<DBIx::Class> value inflation.

I wouldn't consider the interface stable yet; I'd love feedback on this dist.

When C<use>ing Class::Type::Enum:

=over 4

=item *

Required:

=over 4

=item values => [@symbols]

The list of symbolic values in your enum, in ascending order if relevant.

=item values => {symbol => ordinal, ...}

The list of symbols and ordinal values in your enum.  There is no check that a
given ordinal isn't reused.

=back

=back

=head2 Custom Ordinal Values

If you'd like to build an enum that works like a bitfield or some other custom
setup, you need only pass a more explicit hashref to Class::Type::Enum.

  package BitField {
    use Class::Type::Enum values => {
      READ    => 1,
      WRITE   => 2,
      EXECUTE => 4,
    };
  }

=head1 METHODS

=head2 $class->import(values => ...)

Sets up the consuming class as a subclass of Class::Type::Enum and installs
functions that are unique to the class.

=head2 $class->new($value)

Your basic constructor, expects only a value corresponding to a symbol in the
enum type.  Also works as an instance method for enums of the same class.

=head2 $class->inflate_symbol($symbol)

Does the actual work of C<$class-E<gt>new($value)>, also used when inflating values for
L<DBIx::Class::InflateColumn::ClassTypeEnum>.

=head2 $class->inflate_ordinal($ord)

Used when inflating ordinal values for
L<DBIx::Class::InflateColumn::ClassTypeEnum> or if you need to work with
ordinals directly.

=head2 $class->sym_to_ord

Returns a hashref keyed by symbol, with ordinals as values.

=head2 $class->ord_to_sym

Returns a hashref keyed by ordinal, with symbols as values.

=head2 $class->values

Returns an arrayref of valid symbolic values, in order.

=head2 $class->list_is_methods

Returns a list of C<is_> methods defined for each symbolic value for the class.

=head2 $class->type_constraint

This method requires the optional dependency L<Type::Tiny>.

Returns a type constraint suitable for use with L<Moo> and friends.

=head2 $class->test_symbol($value)

Test whether or not the given value is a valid symbol in this enum class.

=head2 $class->test_ordinal($value)

Test whether or not the given value is a valid ordinal in this enum class.

=head2 $class->coerce_symbol($value)

If the given value is already a $class, return it, otherwise try to inflate it
as a symbol.  Dies on invalid value.

=head2 $class->coerce_ordinal($value)

If the given value is already a $class, return it, otherwise try to inflate it
as an ordinal.  Dies on invalid value.

=head2 $class->coerce_any($value)

If the given value is already a $class, return it, otherwise try to inflate it
first as an ordinal, then as a symbol.  Dies on invalid value.

=head2 $o->is($value)

Given a test symbol, test that the enum instance's value is equivalent.

An exception is thrown if an invalid symbol is provided

=head2 $o->is_$value

Shortcut for C<$o-E<gt>is($value)>

=head2 $o->stringify

Returns the symbolic value.

=head2 $o->numify

Returns the ordinal value.

=head2 $o->cmp($other, $reversed = undef)

The string-compare implementation used by overloading.  Returns the same values
as C<cmp>.  The optional third argument is an artifact of L<overload>, set to
true if the order of C<$o> and C<$other> have been reversed in order to make
the overloaded method call work.

=head2 $o->any(@cases)

True if C<$o-E<gt>is(..)> for any of the given cases.

=head2 $o->none(@cases)

True if C<$o-E<gt>is(..)> for none of the given cases.

=head1 SEE ALSO

=over 4

=item *

L<Object::Enum>

=item *

L<Class::Enum>

=item *

L<Enumeration>

=back

=head1 AUTHOR

Meredith Howard <mhoward@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Meredith Howard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
