
package DBIx::MyParsePP::Token;

use DBIx::MyParsePP::Symbols;
use strict;

1;

use constant TOKEN_TYPE		=> 0;
use constant TOKEN_VALUE	=> 1;

sub new {
	my ($class, $type, $value) = @_;
	my $token = bless([], $class);
	$token->[TOKEN_TYPE] = $type;
	$token->[TOKEN_VALUE] = $value;
	return $token;
}

sub value {
	return $_[0]->[TOKEN_VALUE];	
}

sub type {
	return $_[0]->[TOKEN_TYPE];
}

sub getValue {
	return $_[0]->[TOKEN_VALUE];
}

sub getType {
	return $_[0]->[TOKEN_TYPE];
}

sub setType {
	$_[0]->[TOKEN_TYPE] = $_[1];
}

sub setValue {
	$_[0]->[TOKEN_VALUE] = $_[1];
}

sub extract {
	my $token = shift;

	foreach my $match (@_) {
		return $token if $token->type() eq $match;
	}

	return undef;
}

sub extractInner {
	my $token = shift;
	return $token->extract(@_);
}

sub children {
	return ();
}

# Shrinking has no effect on tokens, just return original token

sub shrink {
	return $_[0];
}

sub toString {
	my $token = shift;
	my $type = $token->type();
	my $value = $token->value();
	my $result;

	if ($type eq 'NCHAR_STRING') {
		$result = $value;
		$result =~ s{\\}{\\\\}sgio;
		$result =~ s{'}{\\'}sgio;
		$result = "N'".$result."'";
	} elsif ($type eq 'IDENT_QUOTED') {
		return '`'.$value.'` ';
	} elsif ($type eq 'GLOBAL_SYM') {
		return $value;	# No spaces
	} elsif ($type eq 'SET_VAR') {
		$result = ':=';
	} elsif ($type eq 'BIN_NUM') {
		$result = "b'".$value."'";
	} elsif ($type eq 'HEX_NUM') {
		$result = ' 0x'.$value.' ';
	} elsif ($type eq 'TEXT_STRING') {
		$result = $value;
		$result =~ s{\\}{\\\\}sgio;
		$result =~ s{'}{\\'}sgio;
		$result = "'".$result."'";
	} elsif ($type eq 'UNDERSCORE_CHARSET') {
		$result = '_'.$value;
	} elsif ($type eq '@') {
		return '@';	# No leading space
	} elsif (($type eq 'IDENT') || ($type eq 'LEX_HOSTNAME')) {
		return $value.' ';	# No leading space
	} elsif ($DBIx::MyParsePP::Symbols::functions->{uc($value)} eq $type) {
		return ' '.$value;	# No trailing space
	} elsif ($type eq '(') {
		return $value.' ';	# No leading space;
	} elsif (($type eq '.') || ($type eq '*')) {
		return $value;		# No spaces around table.field, etc.
	} else {
		$result = ' '.$value.' ';
	}
	return $result;
}

sub print {
	return $_[0]->toString();
}

sub isEqual {
    return 0 if !$_[1]->isa( 'DBIx::MyParsePP::Token' );
    return $_[0]->type() eq $_[1]->type() &&
           $_[0]->value() eq $_[1]->value();
}

1;

__END__

=pod

=head1 NAME

DBIx::MyParsePP::Token - Lexical tokens extracted by DBIx::MyParsePP::Lexer

=head1 SYNOPSIS

Please see the example under C<DBIx::MyParsePP::Lexer>

=head1 METHODS

C<new($type, $value)> creates a new Token object.

C<type()> or C<getType()> returns the type of the Token, as string.

C<value()> or C<getValue()> returns the value of the Token.

C<setType($new_type)> and C<setValue($new_value)> can be used to manipulate the Token.

C<toString()> returns the value of the token, quoted if necessary, as it would appear in a SQL statement. A leading
space is added for most tokens in order to facilitate chaining tokens into a larger statement.

=head1 TOKEN TYPES

Token types are returned as strings, to avoid possible confusion between integer values of constants and tokens whose type
is equal to their value. The following types are used by MySQL:

	"IDENT", "IDENT_QUOTED" - database, table or field identifiers or portions thereof.

	"TEXT_STRING", "NCHAR_STRING" - strings in the form 'aaa' and N'aaa'

	"HEX_NUM", "BIN_NUM" - numbers in the form x'ffff' and b'010101'

	"DECIMAL_NUM", "NUM", "LONG_NUM", "ULONGLONG_NUM" - integers of various lengths

	"FLOAT_NUM" - floating-point numbers in scientific notation, e.g -32032.6809e+10

	"UNDERSCORE_CHARSET" - charset modifier before literal string, eg. _utf8

	"LEX_HOSTNAME" - 

	"SET_VAR" - the variable assignment operator :=

Function names and SQL constructs are returned mostly as strings ending in C<_SYM">. The complete list can be found in
C<DBIx::MyParsePP::Symbols>. Some functions are returned as C<"FUNC_ARG1">, C<"FUNC_ARG2"> or C<"FUNC_ARG3">, signifying
the number of arguments the function expects. In this case, the actual name of the function can be obtained by calling
C<getValue()>.

The rules that determine which type of C<"NUM"> is returned can be found in C<DBIx::MyParsePP::Lexer::int_token()>

=cut
