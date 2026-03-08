use strict;
use warnings;

package Data::ZPath::_Parser;

use Carp qw(croak);
use Data::ZPath::_Lexer;

our $VERSION = '0.001000';

sub _parse_top_level_terms {
	my ( $src ) = @_;

	my @parts = _split_top_level_commas($src);
	my @terms;

	for my $p (@parts) {
		my $lexer = Data::ZPath::_Lexer->new($p);
		my $expr  = _parse_expression($lexer);
		$lexer->expect('EOF');
		push @terms, $expr;
	}

	return \@terms;
}

sub _split_top_level_commas {
	my ( $src ) = @_;
	my @out;

	my $depth_paren  = 0;
	my $depth_brack  = 0;
	my $in_string    = 0;
	my $escape       = 0;

	my $buf = '';
	my @chars = split //, $src;

	for ( my $i = 0; $i < @chars; $i++ ) {
		my $c = $chars[$i];

		if ( $in_string ) {
			$buf .= $c;
			if ( $escape ) {
				$escape = 0;
				next;
			}
			if ( $c eq '\\' ) { $escape = 1; next; }
			if ( $c eq '"' )  { $in_string = 0; next; }
			next;
		}

		if ( $c eq '"' ) { $in_string = 1; $buf .= $c; next; }
		if ( $c eq '(') { $depth_paren++; $buf .= $c; next; }
		if ( $c eq ')') { $depth_paren--; $buf .= $c; next; }
		if ( $c eq '[' ) { $depth_brack++; $buf .= $c; next; }
		if ( $c eq ']' ) { $depth_brack--; $buf .= $c; next; }

		if ( $c eq ',' && $depth_paren == 0 && $depth_brack == 0 ) {
			push @out, _trim($buf);
			$buf = '';
			next;
		}

		$buf .= $c;
	}

	push @out, _trim($buf) if length _trim($buf);
	return @out;
}

sub _trim {
	my ( $s ) = @_;
	$s =~ s/^\s+//;
	$s =~ s/\s+$//;
	return $s;
}

# Expression grammar (recursive descent):
#   expr := ternary
#   ternary := or ( WS? '?' WS? expr WS? ':' WS? expr )?
#   or := and ( '||' and )*
#   and := bit_or ( '&&' bit_or )*
#   bit_or := bit_xor ( '|' bit_xor )*
#   bit_xor := bit_and ( '^' bit_and )*
#   bit_and := equality ( '&' equality )*
#   equality := rel ( ('=='|'!=' ) rel )*
#   rel := add ( ('>='|'<='|'>'|'<') add )*
#   add := mul (('+'|'-') mul)*
#   mul := unary (('*'|'/'|'%') unary)*
#   unary := ('!'|'~') unary | primary
#   primary := number | string | function | path | '(' expr ')'
#
# NOTE: per zpath.me, binary ops require whitespace around them.
# We enforce this at lexer-time: a binary op token is only produced if
# it has whitespace before and after in source.

sub _parse_expression { _parse_ternary(@_) }

sub _parse_ternary {
	my ( $lx ) = @_;
	my $cond = _parse_or($lx);

	if ( $lx->peek_kind eq 'QMARK' ) {
		$lx->next_tok; # ?
		my $then = _parse_expression($lx);
		$lx->expect('COLON');
		my $els  = _parse_expression($lx);
		return { t => 'ternary', c => $cond, a => $then, b => $els };
	}

	return $cond;
}

sub _bin_left_assoc {
	my ( $lx, $next_parser, $ops ) = @_;
	my $left = $next_parser->($lx);

	while ( 1 ) {
		my $k = $lx->peek_kind;
		last unless $ops->{$k};
		my $op = $lx->next_tok->{v};
		my $right = $next_parser->($lx);
		$left = { t => 'bin', op => $op, l => $left, r => $right };
	}

	return $left;
}

sub _parse_or {
	my ( $lx ) = @_;
	return _bin_left_assoc($lx, \&_parse_and, { OROR => 1 });
}

sub _parse_and {
	my ( $lx ) = @_;
	return _bin_left_assoc($lx, \&_parse_bitor, { ANDAND => 1 });
}

sub _parse_bitor {
	my ( $lx ) = @_;
	return _bin_left_assoc($lx, \&_parse_bitxor, { BOR => 1 });
}

sub _parse_bitxor {
	my ( $lx ) = @_;
	return _bin_left_assoc($lx, \&_parse_bitand, { BXOR => 1 });
}

sub _parse_bitand {
	my ( $lx ) = @_;
	return _bin_left_assoc($lx, \&_parse_equality, { BAND => 1 });
}

sub _parse_equality {
	my ( $lx ) = @_;
	return _bin_left_assoc($lx, \&_parse_rel, { EQEQ => 1, NEQ => 1 });
}

sub _parse_rel {
	my ( $lx ) = @_;
	return _bin_left_assoc($lx, \&_parse_add, { GE => 1, LE => 1, GT => 1, LT => 1 });
}

sub _parse_add {
	my ( $lx ) = @_;
	return _bin_left_assoc($lx, \&_parse_mul, { PLUS => 1, MINUS => 1 });
}

sub _parse_mul {
	my ( $lx ) = @_;
	return _bin_left_assoc($lx, \&_parse_unary, { STAR => 1, SLASH => 1, PCT => 1 });
}

sub _parse_unary {
	my ( $lx ) = @_;
	my $k = $lx->peek_kind;
	if ( $k eq 'NOT' || $k eq 'BNOT' ) {
		my $op = $lx->next_tok->{v};
		my $e  = _parse_unary($lx);
		return { t => 'un', op => $op, e => $e };
	}
	return _parse_primary($lx);
}

sub _parse_primary {
	my ( $lx ) = @_;
	my $k = $lx->peek_kind;

	if ( $k eq 'NUMBER' ) {
		return { t => 'num', v => $lx->next_tok->{v} };
	}
	if ( $k eq 'STRING' ) {
		return { t => 'str', v => $lx->next_tok->{v} };
	}
	if ( $k eq 'LPAREN' ) {
		$lx->next_tok;
		my $e = _parse_expression($lx);
		$lx->expect('RPAREN');
		return $e;
	}

	# Function: NAME '(' ...
	if ( $k eq 'NAME' && $lx->peek_kind_n(1) eq 'LPAREN' ) {
		my $name = $lx->next_tok->{v};
		$lx->expect('LPAREN');
		my @args;
		if ( $lx->peek_kind ne 'RPAREN' ) {
			push @args, _parse_expression($lx);
			while ( $lx->peek_kind eq 'COMMA' ) {
				$lx->next_tok;
				push @args, _parse_expression($lx);
			}
		}
		$lx->expect('RPAREN');
		return { t => 'fn', n => $name, a => \@args };
	}

	# Otherwise treat it as a path-expression
	return _parse_path_expr($lx);
}

sub _parse_path_expr {
	my ( $lx ) = @_;

	my @segs;

	# path can start with "/" or with a segment.
	if ( $lx->peek_kind eq 'SLASH_PATH' ) {
		$lx->next_tok; # consume '/'
		push @segs, { k => 'root', q => [] };

		if ( $lx->peek_kind eq 'LBRACK' ) {
			$segs[-1]->{q} = _parse_qualifiers($lx);
		}

		if ( 
			$lx->peek_kind eq 'EOF'
			or $lx->peek_kind eq 'COMMA'
			or $lx->peek_kind eq 'RPAREN'
			or $lx->peek_kind eq 'RBRACK'
			or $lx->peek_kind eq 'QMARK'
			or $lx->peek_kind eq 'COLON'
			or $lx->peek_kind eq 'EQEQ'
			or $lx->peek_kind eq 'NEQ'
			or $lx->peek_kind eq 'GE'
			or $lx->peek_kind eq 'LE'
			or $lx->peek_kind eq 'GT'
			or $lx->peek_kind eq 'LT'
			or $lx->peek_kind eq 'ANDAND'
			or $lx->peek_kind eq 'OROR'
			or $lx->peek_kind eq 'PLUS'
			or $lx->peek_kind eq 'MINUS'
			or $lx->peek_kind eq 'STAR'
			or $lx->peek_kind eq 'SLASH'
			or $lx->peek_kind eq 'PCT'
			or $lx->peek_kind eq 'BAND'
			or $lx->peek_kind eq 'BOR'
			or $lx->peek_kind eq 'BXOR'
		) {
			return { t => 'path', s => \@segs };
		}
	}
	elsif ( $lx->peek_kind eq 'LBRACK' ) {
		my $seg = { k => 'dot', q => _parse_qualifiers($lx) };
		push @segs, $seg;
		return { t => 'path', s => \@segs }
			if $lx->peek_kind eq 'EOF' || $lx->peek_kind eq 'COMMA' || $lx->peek_kind eq 'RPAREN' || $lx->peek_kind eq 'RBRACK';
	}

	if (  $lx->peek_kind ne 'SLASH_PATH'
		&& $lx->peek_kind ne 'EOF'
		&& $lx->peek_kind ne 'COMMA'
		&& $lx->peek_kind ne 'RPAREN'
		&& $lx->peek_kind ne 'RBRACK' ) {
		push @segs, _parse_path_segment($lx);
	}

	while ( $lx->peek_kind eq 'SLASH_PATH' ) {
		$lx->next_tok;
		if ( $lx->peek_kind eq 'LBRACK' ) {
			# "list/[expr]" implies "*"
			my $seg = { k => 'star', q => [] };
			$seg->{q} = _parse_qualifiers($lx);
			push @segs, $seg;
			next;
		}
		push @segs, _parse_path_segment($lx);
	}

	return { t => 'path', s => \@segs };
}

sub _parse_path_segment {
	my ( $lx ) = @_;

	my $k = $lx->peek_kind;

	my $seg;
	if ( $k eq 'DOT' )       { $lx->next_tok; $seg = { k => 'dot' }; }
	elsif ( $k eq 'DOTDOT' ) { $lx->next_tok; $seg = { k => 'parent' }; }
	elsif ( $k eq 'DOTDOTSTAR' ) { $lx->next_tok; $seg = { k => 'ancestors' }; }
	elsif ( $k eq 'STAR_PATH' )  { $lx->next_tok; $seg = { k => 'star' }; }
	elsif ( $k eq 'STARSTAR' )   { $lx->next_tok; $seg = { k => 'desc' }; }
	elsif ( $k eq 'INDEX' )      { my $i = $lx->next_tok->{v}; $seg = { k => 'index', i => $i }; }
	elsif ( $k eq 'NUMBER' )     { my $i = $lx->next_tok->{v}; $seg = { k => 'index', i => $i }; }
	elsif ( $k eq 'NAME' && $lx->peek_kind_n(1) eq 'LPAREN' ) {
		my $name = $lx->next_tok->{v};
		$lx->expect('LPAREN');
		my @args;
		if ( $lx->peek_kind ne 'RPAREN' ) {
			push @args, _parse_expression($lx);
			while ( $lx->peek_kind eq 'COMMA' ) {
				$lx->next_tok;
				push @args, _parse_expression($lx);
			}
		}
		$lx->expect('RPAREN');
		$seg = { k => 'fnseg', n => $name, a => \@args };
	}
	elsif ( $k eq 'NAME' )       { my $n = $lx->next_tok->{v}; $seg = { k => 'name', n => $n }; }
	else {
		croak "Unexpected token in path segment: $k";
	}

	# optional name#index
	if ( $seg->{k} eq 'name' && $lx->peek_kind eq 'INDEX' ) {
		$seg->{i} = $lx->next_tok->{v};
	}

	# qualifiers
	$seg->{q} = _parse_qualifiers($lx);

	return $seg;
}

sub _parse_qualifiers {
	my ( $lx ) = @_;
	my @q;

	while ( $lx->peek_kind eq 'LBRACK' ) {
		$lx->next_tok;
		my $e = _parse_expression($lx);
		$lx->expect('RBRACK');
		push @q, $e;
	}

	return \@q;
}

1;
