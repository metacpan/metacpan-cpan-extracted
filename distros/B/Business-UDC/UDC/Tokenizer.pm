package Business::UDC::Tokenizer;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Unicode::UTF8 qw(decode_utf8);

Readonly::Array our @EXPORT_OK => qw(tokenize);

our $VERSION = 0.11;

sub tokenize {
	my ($input, $position_offset) = @_;

	$position_offset //= 0;
	my @tokens;
	my $left_double_quote = decode_utf8('“');
	my $right_double_quote = decode_utf8('”');
	my $time_quote = qr/"|''|$left_double_quote|$right_double_quote/;

	pos($input) = 0;

	while (pos($input) < length($input)) {
		my $start = pos($input);

		if ($input =~ /\G( +(?=\p{L})\p{L}(?:[\p{L}\p{N}._#,]|\[[^\]]+\]|\+(?! )|\/(?! )|-(?!\d)| +(?=[\p{L}\p{N}._\[]))* *)/gcu) {
			_push_token(\@tokens, 'ALPHA_SPEC', $1, $start, 1);
			next;
		}

		if ($input =~ /\G( +(?=($time_quote)(?:(?!$time_quote)[\s\S])*\p{L})(?:$time_quote)(?:(?!$time_quote)[\s\S])*$time_quote *)/gcu) {
			_push_token(\@tokens, 'ALPHA_SPEC', $1, $start, 1);
			next;
		}

		if ($input =~ /\G(\s+)/gc) {
			_push_token(\@tokens, 'WHITESPACE', $1, $start, 1);
			next;
		}

		if ($input =~ /\G(\d+(?:[\.,]\d+)*)/gc) {
			_push_token(\@tokens, 'NUMBER', $1, $start);
			next;
		}

		if (substr($input, $start, 2) eq './') {
			err "Extra dot '.'.",
				'position' => $position_offset + $start,
				'character' => '.',
			;
		}

		if ($input =~ /\G(\.)(?=\s)/gc) {
			_push_token(\@tokens, 'AUX_DOT', $1, $start, 1);
			next;
		}

		if ($input =~ /\G(\.\d+(?:\.\d+)*)/gc) {
			_push_token(\@tokens, 'AUX_DOT', $1, $start);
			next;
		}

		if ($input =~ /\G(\[)/gc) {
			_push_token(\@tokens, 'LBRACK', $1, $start);
			next;
		}

		if ($input =~ /\G(\])/gc) {
			_push_token(\@tokens, 'RBRACK', $1, $start);
			next;
		}

		if ($input =~ /\G(::|[+:\/])/gc) {
			_push_token(\@tokens, 'OP', $1, $start);
			next;
		}

		if (substr($input, $start, 2) eq '--'
			|| substr($input, $start, 1) eq '-'
			&& $start + 1 >= length($input)) {
			err "Extra dash '-'.",
				'position' => $position_offset + $start
					+ (substr($input, $start, 2) eq '--' ? 1 : 0),
				'character' => '-',
			;
		}

		if ($input =~ /\G(-)(?=\s)/gc) {
			_push_token(\@tokens, 'FORM', $1, $start, 1);
			next;
		}

		if ($input =~ /\G(-\d+(?:[\.,]\d+)*)/gc) {
			_push_token(\@tokens, 'FORM', $1, $start);
			next;
		}

		if (substr($input, $start, 1) eq '(') {
			my $end = _find_parenthesis_end($input, $start);
			if (defined $end) {
				my $value = substr($input, $start, $end - $start);
				my $inner = substr($value, 1, length($value) - 2);
				my $inner_tokens = tokenize($inner, $position_offset + $start + 1);
				_offset_token_positions($inner_tokens, $start + 1);
				pos($input) = $end;
				_push_token(\@tokens, 'AUX_GROUP', $value, $start, 1);
				$tokens[-1]->{'tokens'} = $inner_tokens;
				next;
			}
		}

		if ($input =~ /\G(\()/gc) {
			_push_token(\@tokens, 'LPAREN', $1, $start, 1);
			next;
		}

		if ($input =~ /\G(\))/gc) {
			_push_token(\@tokens, 'RPAREN', $1, $start, 1);
			next;
		}

		if (substr($input, $start, 1) eq '"'
			&& index($input, '"', $start + 1) < 0
			&& index($input, "''", $start + 1) < 0
			&& index($input, $right_double_quote, $start + 1) < 0) {
			my $invalid_year_position = _invalid_time_year_position($input, $start);
			if (defined $invalid_year_position) {
				err 'Invalid year in time auxiliary.',
					'position' => $position_offset + $invalid_year_position,
					'character' => substr($input, $invalid_year_position, 1),
				;
			}

			err "Missing closing quotation mark '\"'.",
				'position' => $position_offset + _missing_quote_position($input, $start),
				'character' => '"',
			;
		}

		if ($input =~ /\G(($time_quote)(?:(?!$time_quote)[\s\S])*$time_quote)/gc) {
			my $value = $1;
			if ($value =~ /\p{L}/u) {
				_push_token(\@tokens, 'ALPHA_SPEC', $value, $start, 1);
			} else {
				_push_token(\@tokens, 'AUX_TIME', $value, $start);
			}
			next;
		}

		if ($input =~ /\G(=+)(?=\s)/gc) {
			_push_token(\@tokens, 'AUX_LANG', $1, $start, 1);
			next;
		}

		if ($input =~ /\G(=+(?:[A-Za-z]+|\d+(?:\.\d+)*))/gc) {
			_push_token(\@tokens, 'AUX_LANG', $1, $start);
			next;
		}

		if ($input =~ /\G(\p{L}(?:[\p{L}\p{N}._#,]|\[[^\]]+\]|\+(?! )|\/(?! )|-(?!\d)| +(?=[\p{L}\p{N}._\[]))* *)/gcu) {
			_push_token(\@tokens, 'ALPHA_SPEC', $1, $start, 1);
			next;
		}

		my $a = decode_utf8('’');
		my $acute = decode_utf8('´');
		if ($input =~ /\G(')(?=\s)/gc) {
			_push_token(\@tokens, 'APOS_AUX', $1, $start, 1);
			next;
		}

		if ($input =~ /\G((?:'|`|&apos;|$a|$acute)\d+(?:\.\d+)*)/gc) {
			_push_token(\@tokens, 'APOS_AUX', $1, $start);
			next;
		}

		my $nonbreaking_hyphen = decode_utf8('‑');
		if (substr($input, $start, 1) eq $nonbreaking_hyphen) {
			err 'Bad hyphen character.',
				'position' => $position_offset + $start,
				'character' => $nonbreaking_hyphen,
			;
		}

		my $bad = substr($input, $start, 20);
		err "Unrecognized input near '$bad'.",
			'position' => $position_offset + $start,
		;
	}

	return _merge_bracketed_alpha_specs(\@tokens);
}

sub _invalid_time_year_position {
	my ($input, $start) = @_;

	my $value = substr($input, $start + 1);
	if ($value =~ /^\d{4}\/(\d{1,3})(?=\D|$)/) {
		return $start + 1 + 5;
	}

	return;
}

sub _missing_quote_position {
	my ($input, $start) = @_;

	my $value = substr($input, $start + 1);
	my ($time) = $value =~ /^(\d{4}(?:\.\d+)*)/;
	$time //= '';
	my $rest = substr($value, length($time));
	if (substr($rest, 0, 1) eq '/') {
		my ($end_year) = $rest =~ m{^/(\d+)};
		if (defined $end_year) {
			$time .= '/' . $end_year;
		}
	}

	return $start + 1 + length($time);
}

sub _find_parenthesis_end {
	my ($input, $start) = @_;

	my $depth = 0;
	for (my $pos = $start; $pos < length($input); $pos++) {
		my $character = substr($input, $pos, 1);
		if ($character eq '(') {
			$depth++;
		} elsif ($character eq ')') {
			$depth--;
			return $pos + 1 if $depth == 0;
		}
	}

	return;
}

sub _offset_token_positions {
	my ($tokens_ar, $offset) = @_;

	foreach my $token (@{$tokens_ar}) {
		$token->{'pos'} += $offset;
		if ($token->{'tokens'}) {
			_offset_token_positions($token->{'tokens'}, $offset);
		}
	}

	return;
}

sub _check_whitespace {
	my ($value, $start) = @_;

	if ($value =~ /^(.*?)\s/s) {
		my $ws_pos = length($1);
		my $char = substr($value, $ws_pos, 1);
		err "Whitespace is not allowed in UDC string.",
			'position' => $start + $ws_pos,
			'character' => $char,
		;
	}

	return;
}

sub _push_token {
	my ($tokens_ar, $type, $value, $start, $allow_whitespace) = @_;

	if (! $allow_whitespace) {
		_check_whitespace($value, $start);
	}

	push @{$tokens_ar}, {
		type => $type,
		value => $value,
		pos => $start,
	};

	return;
}

sub _merge_bracketed_alpha_specs {
	my $tokens_ar = shift;

	my @merged;
	while (@{$tokens_ar}) {
		my $token = shift @{$tokens_ar};

		if (@merged
			&& $merged[-1]->{'type'} eq 'ALPHA_SPEC'
			&& $token->{'type'} eq 'LBRACK'
			&& @{$tokens_ar} >= 2
			&& $tokens_ar->[0]->{'type'} eq 'ALPHA_SPEC'
			&& $tokens_ar->[1]->{'type'} eq 'RBRACK') {

			my $inner = shift @{$tokens_ar};
			shift @{$tokens_ar};
			$merged[-1]->{'value'} .= '['.$inner->{'value'}.']';
			next;
		}

		push @merged, $token;
	}

	return \@merged;
}


1;

__END__
