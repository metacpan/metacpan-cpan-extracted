package Data::Dump::JavaScript;
$Data::Dump::JavaScript::VERSION = '0.001';
use strict;
use warnings;
use Exporter 'import';
use Scalar::Util 'blessed';
use Encode ();

# ABSTRACT: Pretty printing of data structures as JavaScript


our @EXPORT_OK = qw( dump_javascript false true );

# Literal names
# Users may override Booleans with literal 0 or 1 if desired.
our($FALSE, $TRUE) = map { bless \(my $dummy = $_), 'Data::Dump::JavaScript::_Bool' } 0, 1;

# Escaped special character map with u2028 and u2029
my %ESCAPE = (
  '"'     => '"',
  '\\'    => '\\',
  '/'     => '/',
  'b'     => "\x08",
  'f'     => "\x0c",
  'n'     => "\x0a",
  'r'     => "\x0d",
  't'     => "\x09",
  'u2028' => "\x{2028}",
  'u2029' => "\x{2029}"
);
my %REVERSE = map { $ESCAPE{$_} => "\\$_" } keys %ESCAPE;

for(0x00 .. 0x1f) {
    my $packed = pack 'C', $_;
    $REVERSE{$packed} = sprintf '\u%.4X', $_ unless defined $REVERSE{$packed};
}

my $indent_level;
# standard and semi-standard JS default
my $indent_count = 2;


sub false () {$FALSE}  ## no critic (prototypes)


sub true () {$TRUE} ## no critic (prototypes)


sub dump_javascript {
    $indent_level = 0;
    Encode::encode 'UTF-8', _encode_value(shift);
}

sub _encode_key {
  my $str = shift;
  $str =~ s!([\x00-\x1f\x{2028}\x{2029}\\"/])!$REVERSE{$1}!gs;
  return "$str";
}

sub _encode_array {
    my $str = '[';
    $str .= "\n"
        if scalar @{$_[0]} > 1;
    $indent_level++;
    $str .= join(",\n", map { scalar @{$_[0]} > 1 ? _get_indented(_encode_value($_)) : _encode_value($_) } @{$_[0]});
    $indent_level--;
    $str .=  scalar @{$_[0]} > 1
        ? "\n" . _get_indented("]")
        : ']';
}

sub _encode_object {
  my $object = shift;
  my $str = '{';
  $str .= "\n"
    if keys %$object > 0;
  $indent_level++;
  my @pairs = map { _get_indented(_encode_key($_)) . ': ' . _encode_value($object->{$_}) }
    sort keys %$object;
  #$str .= join(",\n", @pairs) . "\n";
  $str .= join(",\n", @pairs);
  $indent_level--;
  $str .= keys %$object > 0
    ? "\n" . _get_indented("}")
    : '}';
  return $str;
}

sub _encode_string {
  my $str = shift;
  $str =~ s!([\x00-\x1f\x{2028}\x{2029}\\"/])!$REVERSE{$1}!gs;
  return "'$str'";
}

sub _encode_value {
  my $value = shift;

  # Reference
  if (my $ref = ref $value) {

    # Object
    return _encode_object($value) if $ref eq 'HASH';

    # Array
    return _encode_array($value) if $ref eq 'ARRAY';

    # True or false
    return $$value ? 'true' : 'false' if $ref eq 'SCALAR';
    return $value  ? 'true' : 'false' if $ref eq 'Data::Dump::JavaScript::_Bool';

    # Blessed reference with TO_JSON method
    if (blessed $value && (my $sub = $value->can('TO_JSON'))) {
      return _encode_value($value->$sub);
    }
  }

  # Null
  return 'null' unless defined $value;


  # Number (bitwise operators change behavior based on the internal value type)

  # "0" & $x will modify the flags on the "0" on perl < 5.14, so use a copy
  my $zero = "0";
  # "0" & $num -> 0. "0" & "" -> "". "0" & $string -> a character.
  # this maintains the internal type but speeds up the xor below.
  my $check = $zero & $value;
  return $value
    if length $check
    # 0 ^ itself          -> 0    (false)
    # $character ^ itself -> "\0" (true)
    && !($check ^ $check)
    # filter out "upgraded" strings whose numeric form doesn't strictly match
    && 0 + $value eq $value
    # filter out inf and nan
    && $value * 0 == 0;

  # String
  return _encode_string($value);
}

sub _get_indented {
    return ' ' x ( $indent_level * $indent_count ) . shift;
}

# Emulate boolean type
package Data::Dump::JavaScript::_Bool;
$Data::Dump::JavaScript::_Bool::VERSION = '0.001';
use overload '""' => sub { ${$_[0]} }, fallback => 1;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Dump::JavaScript - Pretty printing of data structures as JavaScript

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Data::Dump::JavaScript qw( dump_javascript true false );

  my $javascript = dump_javascript({ foo => [1, 2], bar => 'hello!', baz => true });

=head1 DESCRIPTION

Data::Dump::JavaScript is a fork of L<JSON::Tiny> version 0.55 which outputs
pretty-printed JavaScript.

The indention is according to L<JavaScript Standard Style|http://standardjs.com>
and L<JavaScript Semi-Standard Style|https://github.com/Flet/semistandard>.
Hash keys are sorted in standard string comparison order.

=head1 FUNCTIONS

Data::Dump::JavaScript implements the following functions, which can be imported
individually.

=head2 false

  my $false = false;

False value, used because Perl has no equivalent.

=head2 true

  my $true = true;

True value, used because Perl has no native equivalent.

=head2 dump_javascript

    my $bytes = dump_javascript({ foo => 'bar' });

Encode Perl value to UTF-8 encoded JavaScript.

=head1 SEE ALSO

=over 4

=item L<Data::JavaScript>

Can only dump Perl structures as JavaScript variable assignment.
No boolean handling, no formatting.

=item L<Data::JavaScript::Anon>

No boolean handling, no formatting.

=back

=head1 AUTHOR

Alexander Hartmaier <abraxxa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
