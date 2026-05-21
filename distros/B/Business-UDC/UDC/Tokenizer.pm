package Business::UDC::Tokenizer;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Unicode::UTF8 qw(decode_utf8);

Readonly::Array our @EXPORT_OK => qw(tokenize);

our $VERSION = 0.08;

sub tokenize {
	my ($input) = @_;
	my @tokens;
	my $left_double_quote = decode_utf8('“');
	my $right_double_quote = decode_utf8('”');
	my $time_quote = qr/"|''|$left_double_quote|$right_double_quote/;

	pos($input) = 0;

	while (pos($input) < length($input)) {
		my $start = pos($input);

		if ($input =~ /\G( +(?=\p{L})\p{L}(?:[\p{L}\p{N}._#,]|\+(?! )|\/(?! )|-(?!\d)| +(?=[\p{L}\p{N}._]))* *)/gcu) {
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

		if ($input =~ /\G([:+\/])/gc) {
			_push_token(\@tokens, 'OP', $1, $start);
			next;
		}

		if ($input =~ /\G(-\d+(?:\.\d+)*)/gc) {
			_push_token(\@tokens, 'FORM', $1, $start);
			next;
		}

		if ($input =~ /\G(\([^)]+\))/gc) {
			_push_token(\@tokens, 'AUX_GROUP', $1, $start, 1);
			next;
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

		if ($input =~ /\G(=+(?:[A-Za-z]+|\d+(?:\.\d+)*))/gc) {
			_push_token(\@tokens, 'AUX_LANG', $1, $start);
			next;
		}

		if ($input =~ /\G(\p{L}(?:[\p{L}\p{N}._#,]|\+(?! )|\/(?! )|-(?!\d)| +(?=[\p{L}\p{N}._]))* *)/gcu) {
			_push_token(\@tokens, 'ALPHA_SPEC', $1, $start, 1);
			next;
		}

		my $a = decode_utf8('’');
		my $acute = decode_utf8('´');
		if ($input =~ /\G((?:'|`|&apos;|$a|$acute)\d+(?:\.\d+)*)/gc) {
			_push_token(\@tokens, 'APOS_AUX', $1, $start);
			next;
		}

		my $bad = substr($input, $start, 20);
		err "Unrecognized input near '$bad'.",
			'position' => $start,
		;
	}

	return \@tokens;
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


1;

__END__
