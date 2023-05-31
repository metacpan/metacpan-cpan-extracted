# $Id$

package CPU::Z80::Assembler::Expr;

#------------------------------------------------------------------------------

=head1 NAME

CPU::Z80::Assembler::Expr - Represents one assembly expression to be computed at link time

=cut

#------------------------------------------------------------------------------

use strict;
use warnings;

our $VERSION = '2.25';

use CPU::Z80::Assembler;
use CPU::Z80::Assembler::Parser;
use Iterator::Simple::Lookahead;
use Asm::Preproc::Line;
use Asm::Preproc::Token;

#use Class::Struct (
#		child	=> '@',		# list of children of this node
#		line 	=> 'Asm::Preproc::Line',
#							# line where tokens found
#		type 	=> '$',		# one of:
#							#	"sb" - signed byte
#							#	"ub" - unsigned byte
#							#	"w"  - 2 byte word
#);
sub new { 
	my($class, %args) = @_;
	bless [
		$args{type}, 
		$args{line} 	|| Asm::Preproc::Line->new(),
		$args{child} 	|| [], 
	], $class;
}
sub type	{ defined($_[1]) ? $_[0][0] = $_[1] : $_[0][0] }
sub line 	{ defined($_[1]) ? $_[0][1] = $_[1] : $_[0][1] }
sub child	{ defined($_[1]) ? $_[0][2] = $_[1] : $_[0][2] }

#------------------------------------------------------------------------------

=head1 SYNOPSIS

  use CPU::Z80::Assembler::Expr;
  my $node = CPU::Z80::Assembler::Expr->new( type => "sb" );
  $expr->parse($input);
  $new_expr = $expr->build($expr_text);
  $value = $expr->evaluate($address, \%symbol_table);
  $bytes = $expr->bytes($address, \%symbol_table);

=head1 DESCRIPTION

This module defines the class that represents one assembly expression to be
computed at link time.

=head1 EXPORTS

Nothing.

=head1 FUNCTIONS

=head2 new

Creates a new object, see L<Class::Struct|Class::Struct>.

=head2 type

The type string has to be defined before the C<bytes> method is called, and defines
how to code the value returned by C<evaluate> into a byte string.

Type is one of:

=over 4

=item "sb"

for signed byte - a 8 bit signed value. A larger value is truncated and a warning
is issued.

=item "ub" 

for unsigned byte - a 8 bit unsigned value. A larger value is truncated and a warning
is issued.

=item "w" 

for word - a 16 bit unsigned value in little endian format. A larger value is truncated,
but in this case no warning is issued. The address part above 0xFFFF is considered
a bank selector for memory banked systems.

A STRING value is computed in little endian format and only the first two characters are used.
"ab" is encoded as ord("a")+(ord("b")<<8).

=back

The text bytes used in defm / deft are a string of bytes in big endian format, not truncated. For example, 0x112233 is stored as the 3-byte sequence 0x11, 0x22 and 0x33. 

A STRING value is encoded with the list of characters in the string. If the string is 
used in an expression, then the expression applies to the last character of the string. This allows expressions like "CALL"+0x80 to invert bit 7 of the last character of the string.

C-like escape sequences are expanded both in single- and double-quoted strings.

=head2 child

List of tokens composing the expression.

=head2 line

Get/set the line - text, file name and line number where the token was read.

=cut

#------------------------------------------------------------------------------

=head2 parse

  $expr->parse($input);

Parses an expression at the given $input stream 
(L<Iterator::Simple::Lookahead|Iterator::Simple::Lookahead>), 
leaves the stream pointer after the expression and updates the expression object. 
Dies if the expression cannot be parsed.

=cut

sub parse {
	my($self, $input) = @_;
	$self->child([]);
	
	my $value = CPU::Z80::Assembler::Parser::parse($input, undef, "expr");
	$self->child($value);
	$self->line($value->[0]->line);
}

#------------------------------------------------------------------------------

=head2 evaluate

  $value = $expr->evaluate($address, $symbol_table)

Computes the value of the expression, as found at the given address and looking
up any referenced symbols from the given symbol table.

The address is used to evaluate the value of '$'.

The symbol table is a hash of symbol names to values. The value is either a
scalar value that is used directly in the expression, or a reference to a
sub-expression that is computed recursively by calling its C<evaluate> method.

Exits with a fatal error if the expression cannot be evaluated (circular reference,
undefined symbol or mathematical error).

=cut

#------------------------------------------------------------------------------

sub evaluate { my($self, $address, $symbol_table, $seen) = @_;
	$seen ||= {};								# to detect circular references
	my @code;
	for my $token (@{$self->child}) {
		my($type, $value) = ($token->type, $token->value);
		if ($type eq "NUMBER") {
			push(@code, $value);
		}
		elsif ($type eq "NAME") {
			if ($value eq '$') {
				push(@code, $address);
			}
			else {
				my $expr = $symbol_table->{$value};
				my $expr_value;
				
				defined($expr) or
					$self->line->error("Symbol '$value' not defined");
				if (ref($expr)) {					# compute sub-expression first
					$seen->{$value} and
						$self->line->error("Circular reference computing '$value'");
					my %local_seen = (%$seen, $value => 1);
					$expr_value = $expr->evaluate($address, $symbol_table, 
												  \%local_seen);
				}
				else {
					$expr_value = $expr;
				}				
				push(@code, $expr_value);
			}
		}
		elsif ($type eq "STRING") {
			if (length($value) > 2) {
				$self->line->warning("Expression $value: extra bytes ignored");
				$value = substr($value, 0, 2);
			}
			$value .= "\0\0";
			my @bytes = map {ord($_)} split(//, $value);
			my $value = $bytes[0] + ($bytes[1] << 8);
			push(@code, $value);
		}
		elsif ($type eq "EXPR") {
			my $expr_value = $value->evaluate($address, $symbol_table, $seen);
			push(@code, $expr_value);
		}
		else {
			$type =~ /^[a-z_]/ and		# reserved word
				$self->line->error("Expression '$type': syntax error");
			push(@code, $type);
		}
	}
	return 0 if !@code;
	my $code = join(" ", @code);
	my $value = eval $code;
	if ($@) {
		$@ =~ s/ at .*//;
		$self->line->error("Expression '$code': $@");
	}

	return $value;
}

#------------------------------------------------------------------------------

=head2 build

  $new_expr = $expr->build($expr_text)
  $new_expr = $expr->build($expr_text, @init_args)

Build and return a new expresion object with an expression based on the current
object. The expression is passed as a string and is lexed by L<CPU::Z80::Assembler|CPU::Z80::Assembler> C<z80lexer>.
The special token '{}' is used to refer to this expression.

For example, to return a new expression object that, when evaluated, gives the double
of the current expression object:

  my $new_expr = $expr->build("2*{}");

C<@init_args> can be used to pass parameters to the constructor of the new expression
object.

=cut

#------------------------------------------------------------------------------

sub build {	my($self, $expr_text, @init_args) = @_;
	my $line = $self->line;
	my $new_expr = ref($self)->new(line => $line, type => $self->type, @init_args);
	my $token_stream = CPU::Z80::Assembler::z80lexer($expr_text);
	while (defined(my $token = $token_stream->next)) {
		if ($token->type eq '{') {
			(defined($token_stream->peek) && $token_stream->next->type eq '}')
				or die "unmatched {}";
				
			# refer to this expression
			push(@{$new_expr->child}, 
					Asm::Preproc::Token->new(EXPR => $self, $line));
		}
		else {
			$token->line($line);
			push(@{$new_expr->child}, $token);
		}
	}
	$new_expr;
}

#------------------------------------------------------------------------------

=head2 bytes

  $bytes = $expr->bytes($address, \%symbol_table);

Calls C<evaluate> to compute the value of the expression, and converts the
value to a one or two byte string, according to the C<type>.

=cut

#------------------------------------------------------------------------------

sub bytes { my($self, $address, $symbol_table) = @_;
	my $type = $self->type || "";	
	my $value = $self->evaluate($address, $symbol_table);
			
	my $ret;
	if ($type eq "w") {
		if ($value > 0xFFFF) {
			# silently accept values > 0xFFFF to ignore segment selectors
		}
		elsif ($value < -0x8000) {
			# error if negative value out of range
			$self->line->error(sprintf("value -0x%04X out of range", (-$value) & 0xFFFF));
			die; # not reached
		}
		$ret = pack("v", $value & 0xFFFF);	# 16 bit little endian unsigned
	}
	elsif ($type eq "ub") {
		if ($value > 0xFF) {
			# accept values > 0xFF, but issue warning
			$self->line->warning(sprintf("value 0x%02X truncated to 0x%02X",
										 $value, $value & 0xFF));
		}
		elsif ($value < -0x80) {
			# error if negative value out of range
			$self->line->error(sprintf("value -0x%02X out of range", (-$value) & 0xFF));
			die; # not reached
		}
		$ret = pack("C", $value & 0xFF);	# 8 bit unsigned
	}
	elsif ($type eq "sb") {
		# error if value outside of signed byte range
		# used by (ix+d) and jr NN; error if out of range
		if ($value > 0x7F) {
			$self->line->error(sprintf("value 0x%02X out of range", $value));
			die; # not reached
		}
		elsif ($value < -0x80) {
			$self->line->error(sprintf("value -0x%02X out of range", (-$value) & 0xFF));
			die; # not reached
		}
		$ret = pack("C", $value & 0xFF);	# 8 bit unsigned
	}
	else {
		die "Expr::bytes(): unrecognized type '$type'";		# exception
	}
	return $ret;
}

#------------------------------------------------------------------------------

=head1 BUGS and FEEDBACK

See L<CPU::Z80::Assembler|CPU::Z80::Assembler>.

=head1 SEE ALSO

L<CPU::Z80::Assembler|CPU::Z80::Assembler>
L<Asm::Preproc::Line|Asm::Preproc::Line>
L<Class::Struct|Class::Struct>

=head1 AUTHORS, COPYRIGHT and LICENCE

See L<CPU::Z80::Assembler|CPU::Z80::Assembler>.

=cut

1;
