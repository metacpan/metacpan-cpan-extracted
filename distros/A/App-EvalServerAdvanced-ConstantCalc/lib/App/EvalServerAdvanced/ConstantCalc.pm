package App::EvalServerAdvanced::ConstantCalc;

our $VERSION = '0.06';

# ABSTRACT: turns strings and constants into values

use v5.24;
use Moo;
use Function::Parameters;
use Data::Dumper;

has constants => (is => 'ro', default => sub {+{}});
has _parser => (is => 'ro', default => sub {App::EvalServerAdvanced::ConstantCalc::Parser->new(consts => $_[0])});

method get_value($key) {
  die "Missing constant [$key]" unless exists($self->constants->{$key});

  return $self->constants->{$key};
}

method add_constant($key, $value) {
  die "Invalid key [$key]" if ($key =~ /\s/ || $key =~ /^\s*\d/);

  if (exists($self->constants->{$key}) && defined(my $eval = $self->constants->{$key})) {
    die "Cannot redefine a constant [$key].  Existing value [$eval] new value [$value]"
  }

  die "Value undefined for [$key]" unless defined($value);
  die "Value [$value] for [$key] must be an integer" if ($value =~ /[^xob\d\-+_]/i);

  $self->constants->{$key} = App::EvalServerAdvanced::ConstantCalc::Parser::_to_int($value);
}

method calculate($string) {
  return $self->_parser->from_string($string);
}

package
  App::EvalServerAdvanced::ConstantCalc::Parser;

use strict;
use warnings;

# Ensure we can't accidentally turn to strings, or floats, or anything other than an integer
use integer;
no warnings 'experimental::bitwise';
use feature 'bitwise';

use parent qw/Parser::MGC/;
use Function::Parameters;

method new($class: %args) {
  my $consts = delete $args{consts};

  my $self = $class->SUPER::new(%args);

  $self->{_private}{consts} = $consts;

  return $self;
}

method consts() {
  return $self->{_private}{consts};
}

method parse_upper() {
  my $val = $self->parse_term();

  1 while $self->any_of(
    sub {$self->expect("&"); $val &= $self->parse_term(); 1},
    sub {0}
  );

  return $val;
}

method parse() {
  my $val = $self->parse_upper();

  1 while $self->any_of(
      sub {$self->expect("^"); $val ^= $self->parse_upper(); 1 },
      sub {$self->expect("|"); $val |= $self->parse_upper(); 1 },
      sub {0}
  );

  return $val;
}

method parse_term() {
   $self->any_of(
      sub { $self->scope_of( "(", sub { $self->parse }, ")" ) },
      sub { $self->expect('~['); my $bitdepth=$self->token_int; $self->expect(']'); my $val = $self->parse_term; (~ ($val & _get_mask($bitdepth))) & _get_mask($bitdepth)},
      sub { $self->expect('~'); ~$self->parse_term},
      sub { $self->token_constant },
      sub { $self->token_int },
   );
}

method token_int() {
  0+$self->any_of(
     sub {_to_int($self->expect(qr/0x[0-9A-F_]+/i));},
     sub {_to_int($self->expect(qr/0b[0-7_]+/i));},
     sub {_to_int($self->expect(qr/0o?[0-7_]+/i));},
     sub {$self->expect(qr/\d+/)}
     );
}

method token_constant() {
  my $const = $self->expect(qr/[a-z_][a-z_0-9]+/i);

  $self->consts->get_value($const);
}

fun _get_mask($size) {
  return 2**($size)-1;
}


fun _to_int($val) {
  $val =~ s/^0o/0/i;

  if ($val =~ /^0/) {
    return oct $val;
  } else {
    return 0+$val;
  }
}

1;

__END__

=pod
 
=encoding UTF-8
 
=head1 NAME
 
App::EvalServerAdvanced::ConstantCalc - A basic bitwise calculator supporting bitwise operations
 
=head1 DESCRIPTION
 
This module handles calculating bitwise expressions using constant values.  Things like O_CREAT|O_RDWR|O_EXCL|O_CLOEXEC.  Mainly intended
to be used for parsing rules/values for Seccomp plugins for App::EvalServerAdvanced but does not depend on it.

=head1 FEATURES
 
=over 1
 
=item Bitwise operators

All bitwise operators | & ~ and ^ are supported.  Along with a special bitwise inverse with built in masking, ~[16] will negate all the bits, and apply a 16 bit mask to the resulting value.

Precedence is the same as Perl and C, where & has higher precedence and | and ^ are the same.  ~ has the highest precedence.

=item Constant value definition

You can predefine constants to be available to expressions so that you don't have to remember that O_RDONLY is 0, O_RDRW is 4.  This means that your expressions can be made to show your intent rather than just some magic number.

=back

=head1 METHODS

=over 1

=item new

Constructor, can take a single argument C<constants> that is a has of any constants you want to define.

=item add_constant

Add a constant at runtime, takes two arguments C<$key> and C<$value>.  Will prevent you from setting up invalid constants or ones with an invalid value.

Valid keys begin with C</[a-z_]/i> and are followed by C</[a-z0-9_]/i>.  Valid values are any integer.

=item get_value

Takes a C<$key> gives back the corrosponding value for the constant.  Most likely not useful for anybody, but used internally to do the lookup.  Will die if the constant doesn't exist.
 
=back
 
=head1 SEE ALSO
 
L<App::EvalServerAdvanced>, L<Parser::MGC>
 
=head1 AUTHOR
 
Ryan Voots <simcop@cpan.org>
 
=cut
