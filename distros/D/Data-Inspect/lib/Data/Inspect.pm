=head1 NAME

Data::Inspect - human-readable object representations

=head1 SYNOPSIS

  use Data::Inspect;
  my $insp = Data::Inspect->new;
  $insp->p($object);

  use Data::Inspect qw(p);
  p $object;

=head1 DESCRIPTION

Data::Inspect provides a human-readable representation of any Perl
scalar. Classes can be extended with user-defined inspect methods. It
is heavily inspired by Ruby's C<p> method and inspect functionality.

The purpose of this module is to provide debugging/logging code with a
more readable representation of data structures than the extremely
literal form output by Data::Dumper.

It is especially useful in an object-oriented system, since each class
can define its own C<inspect> method, indicating how that particular
object should be displayed.

The L</p> method inspects its arguments and outputs them to the default
filehandle. It can be exported to your package's namespace, in which
case it will silently create the Inspect object with the default
options, if this sort of brevity is desired.

=cut

package Data::Inspect;

our $VERSION = '0.05';

use strict;
use warnings;

use Data::Dumper ();
use Scalar::Util ();

use base 'Exporter';
our @EXPORT_OK = qw(p pe pf);

=head1 PUBLIC METHODS

=over 4

=item new

  my $insp = Data::Inspect->new;

Create a new Data::Inspect object.

=cut

sub new {
  my ($class) = @_;
  my $self = bless {}, $class;

  # Initialize values
  $self->{tracker} = {};
  $self->{options}{truncate_strings} = undef;

  return $self;
}

=item p

  $insp->p($var1, $var2);

  use Data::Inspect qw(p);
  p $var1, $var2;

Inspects each of the provided arguments and outputs the result to the
default filehandle (usually STDOUT).

C<p> can be exported to the current namespace if you don't want to
create a Data::Inspect object to do your inspecting for you.

=cut

sub p {
  my $self = UNIVERSAL::isa($_[0], __PACKAGE__) ? shift : __PACKAGE__->new;
  print $self->inspect($_)."\n" for @_;
}

=item pe

  $insp->pe($var1, $var2);

Exactly like L</p> but outputs to STDERR instead of the default
filehandle.

=cut

sub pe {
  my $self = UNIVERSAL::isa($_[0], __PACKAGE__) ? shift : __PACKAGE__->new;
  print STDERR $self->inspect($_)."\n" for @_;
}

=item pf

  $insp->pf($somefh, $var1, $var2);

Like L</p> and L</pe> but outputs to the filehandle specified in the
first argument.

Note that the filehandle must be a reference. If you want to use a
filehandle that isn't a reference, you can create one using the
L<Symbol>::qualify_to_ref function.

=cut

sub pf {
  # Create a new $self if this is called in the non-OO manner.
  my $self = UNIVERSAL::isa($_[0], __PACKAGE__) ? shift : __PACKAGE__->new;
  my $fh   = shift;
  print $fh $self->inspect($_)."\n" for @_;
}

=item inspect

  my $value = $insp->inspect($var);

Inspects the given scalar value and returns the result.

=cut

sub inspect {
  my ($self, $val) = @_;

  # If no $val is provided or $val is $self, someone is probably
  # trying to inspect this object!
  if (@_ < 2 or (ref $val and
      Scalar::Util::refaddr($val) == Scalar::Util::refaddr($self))) {
    return "#<Inspect options=".$self->inspect($self->{options}).">";
  }

  # If it's a reference, we delegate it to _inspect_reference
  if (ref $val) {
    return $self->_inspect_reference($val);
  }

  # Otherwise, delegate to _inspect_non_reference
  else {
    return $self->_inspect_non_reference($val);
  }
}

=item set_option

  $insp->set_option('truncate_strings', 30);

Set the given option to the given value. Options alter the output of
Inspect.

Available options are:

=over

=item truncate_strings

If set to a positive integer, truncates strings after that number of
characters, replacing the end with '...'.

default: undef

=item sort_keys

If set to the string 'cmp' or '<=>', hashes will have their keys
sorted using the specified comparison before being output.

default: undef

=back

=cut

sub set_option {
  my ($self, $option, $value) = @_;
  if (not grep {$_ eq $option} qw/truncate_strings sort_keys/) {
    warn "Inspect: option '$option' is not a valid option";
    return;
  }
  $self->{options}{$option} = $value;
}

=back

=cut

# Aux method for inspecting non-references. Mostly the grunt work here
# is done by Data::Dumper.
sub _inspect_non_reference {
  my ($self, $val) = @_;

  # Data::Dumper is good at inspecting non-references. If they're
  # strings, it sorts out all the escaping.
  my $dumper = Data::Dumper->new([$val]);
  $dumper->Useqq(1); # Use double quotes so we get nice things like \n
  $dumper->Terse(1); # Just the data, please. No $VAR1!
  chomp(my $dump = $dumper->Dump);

  # If we're truncating strings, do it here
  if ($self->{options}{truncate_strings} and
      length $dump > $self->{options}{truncate_strings}+2
      and $dump =~ /^"/) {
    $dump = substr($dump, 0, $self->{options}{truncate_strings}+1).'..."';
  }

  return $dump;
}

# Aux method for inspecting references. This is the bit we have to do
# ourselves because Data::Dumper is just too literal.
#
# The second argument, reftype, is taken to be the reftype instead of
# the autodetected one.
sub _inspect_reference {
  my ($self, $val, $reftype) = @_;

  # Avoid circular references by keeping track of the references we're
  # currently inspecting. We have to ignore this check if $reftype is
  # set because we are technically re-evaluating the same old thing.
  my $refaddr = Scalar::Util::refaddr($val);
  if (not $reftype and exists $self->{tracker}{$refaddr}) {
    return sprintf "#<CIRCULAR REFERENCE 0x%x>", $refaddr;
  }
  local $self->{tracker}{$refaddr} = 1;

  # Set $reftype to 'HASH', 'ARRAY', 'object' etc.
  if (not $reftype) {
    if (Scalar::Util::blessed($val)) {
      $reftype = 'object';
    }
    else {
      $reftype = ref $val;
    }
  }

  # If we have a method for inspecting this reftype, call it
  my $method = "_inspect_$reftype";
  if ($self->can($method)) {
    $self->$method($val);
  }
  # Otherwise, we call the _inspect_other with $val and $reftype
  else {
    $self->_inspect_other($val, $reftype);
  }
}

# Inspect an object. If the object defines an inspect() method this is
# easy. If it doesn't, we just return the class and the underlying
# reference inspected.
sub _inspect_object {
  my ($self, $val) = @_;
  # Object's class defines an 'inspect'
  if ($val->can('inspect')) {
    return $val->inspect($self);
  }
  # Otherwise return the object's class name followed by an inspection
  # of the underlying representation.
  else {
    my $class = Scalar::Util::blessed($val);
    my $inspected =
      $self->_inspect_reference($val, Scalar::Util::reftype($val));
    return "#<$class $inspected>";
  }
}

# Inspect a scalar reference. Well, this is just the same as
# inspecting the scalar it references but with a \ in front.
sub _inspect_SCALAR {
  my ($self, $val) = @_;
  return q{\\}.$self->inspect($$val);
}

# Inspect a hash reference. This is a lot like Data::Dumper except we
# inspect all the keys and values and provide it in a nice one-line
# format.
sub _inspect_HASH {
  my ($self, $val) = @_;

  # Do the keys need sorting?
  my @keys;
  if ($self->{options}{sort_keys} and $self->{options}{sort_keys} eq 'cmp') {
    @keys = sort keys %$val;
  }
  elsif ($self->{options}{sort_keys} and $self->{options}{sort_keys} eq '<=>') {
    @keys = sort {$a<=>$b} keys %$val;
  }
  else {
    @keys = keys %$val;
  }

  my $ostr = '{';
  my @vals = map { $self->inspect($_).' => '.$self->inspect($val->{$_}) } @keys;
  $ostr .= join ', ', @vals;
  return "$ostr}";
}

# Inspect an array reference.
sub _inspect_ARRAY {
  my ($self, $val) = @_;
  my $ostr = '[';
  my @vals = map { $self->inspect($_) } @$val;
  $ostr .= join ', ', @vals;
  return "$ostr]";
}

# Inspect a glob reference.
sub _inspect_GLOB {
  my ($self, $val) = @_;
  my $ostr = '#<GLOB';
  foreach (qw/NAME SCALAR ARRAY HASH CODE IO GLOB FORMAT PACKAGE/) {
    if (defined *{$val}{$_}) {
      $ostr .= " $_=".$self->inspect(*{$val}{$_});
    }
  }
  return "$ostr>";
}

# Inspect anything else. This takes a second argument, which is the
# type of reference we're inspecting.
sub _inspect_other {
  my ($self, $val, $reftype) = @_;
  return "#<$reftype>";
}

=head1 EXAMPLES

=head2 Inspecting built-in Perl types

In this example, we use the L</p> method to output the inspected contents
of a Perl hash:

  use Data::Inspect qw(p);
  p \%some_hash;

The output is something like:

  {"baz" => "qux\n\n", "foo" => "bar"}

=head2 Changing how an object looks

In this example, objects of class C<Wibble> are blessed hashrefs
containing a lot of data. They are uniquely identifiable by one key,
C<id>; so we create an inspect method that just displays that C<id>:

  package Wibble;
  
  sub inspect {
    my ($self, $insp) = @_;
    "#<Wibble id=$self->{id}>";
  }

If we have a hash full of Wibbles we can now see its contents easily
by inspecting it:

  use Data::Inspect qw(p);
  p \%hash_of_wibbles;

The output will be something like:

  {"bar" => #<Wibble id=42>, "baz" => #<Wibble id=667>, "foo" => #<Wibble id=1>}

=head2 Recursive inspecting

$_[1] is set to the current Data::Inspect object in calls to an
object's C<inspect> method. This allows you to recursively inspect
data structures contained within the object, such as hashes:

  package Wibble;

  sub inspect {
    my ($self, $insp) = @_;
    "#<Wibble id=$self->{id} data=".$insp->inspect($self->{data}).">";
  }

=head2 Using Data::Inspect in the OO form

The OO form provides a greater degree of flexibility than just
importing the L</p> method. The behaviour of Data::Inspect can be
modified using the L</set_option> method and there is also an
L</inspect> method that returns the inspected form rather than
outputting it.

  use Data::Inspect;
  my $insp = Data::Inspect->new;
  
  # Strings are truncated if they are more than 10 characters long
  $insp->set_option('truncate_strings', 10);
  
  $insp->p("Supercalifragilisticexpialidocious");

Outputs:

  "Supercalif..."

=head1 SEE ALSO

L<Data::Dumper>

The Ruby documentation for C<Object#inspect> and C<Kernel#p> at
http://www.ruby-doc.org/core/

=head1 CHANGES

  - 0.05 Fix deprecated regexp in test (thanks Jim Keenan!)
  
  - 0.04 Fixed test case 7 to work with Perl 5.11.5

  - 0.03 Fixed documentation and tests further.

  - 0.02 Added support and documentation for recursive inspecting.
         Fixed tests on versions of perl built without useperlio.

  - 0.01 Initial revision

=head1 AUTHOR

Rich Daley <cpan@owl.me.uk>

=head1 COPYRIGHT

Copyright (c) 2009 Rich Daley. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
