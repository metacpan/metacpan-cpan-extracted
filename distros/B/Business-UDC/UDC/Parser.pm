package Business::UDC::Parser;

use base qw(Exporter);
use strict;
use warnings;

use Business::UDC::Grammar qw(can_follow_operator can_follow_primary can_precede_number
	is_operator_token is_primary_token is_valid_operator);
use Business::UDC::Tokenizer qw(tokenize);
use Error::Pure qw(err);
use List::Util 1.33 qw(any);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(parse);

our $VERSION = 0.08;

sub parse {
	my $input = shift;

	if (! defined $input) {
		err 'No input provided.';
	}
	if ($input !~ /\S/) {
		err 'Empty input.';
	}

	my $tokens = tokenize($input);
	my $normalized_tokens = [];
	foreach my $tok_hr (@{$tokens}) {
		my %parse_tok = %{$tok_hr};
		_check_whitespace_token(\%parse_tok);
		_check_apos_aux_tokens(\%parse_tok);
		_check_aux_time_tokens(\%parse_tok);
		_check_number_token(\%parse_tok);
		_normalize_alpha_spec_token(\%parse_tok);
		push @{$normalized_tokens}, \%parse_tok;
	}
	my $state = {
		'tokens' => $normalized_tokens,
		'pos' => 0,
	};

	my $ast = _parse_expression($state);

	if ($state->{'pos'} < @{$state->{'tokens'}}) {
		my $tok = $state->{'tokens'}[$state->{'pos'}];
		err "Unexpected token '$tok->{'value'}'.",
			'position' => $tok->{'pos'},
		;
	}

	return {
		'tokens' => $tokens,
		'ast' => $ast,
	};
}

sub _check_whitespace_token {
	my $tok = shift;

	if ($tok->{'type'} ne 'WHITESPACE') {
		return;
	}

	err "Whitespace is not allowed in UDC string.",
		'position' => $tok->{'pos'},
		'character' => substr($tok->{'value'}, 0, 1),
	;
}

sub _check_apos_aux_tokens {
	my $tok = shift;

	if ($tok->{'type'} ne 'APOS_AUX') {
		return;
	}
	if (substr($tok->{'value'}, 0, 1) eq "'") {
		return;
	}

	my ($character) = $tok->{'value'} =~ /^(&apos;|.)/us;
	err 'Bad apostrophe character.',
		'character' => $character,
		'position' => $tok->{'pos'},
	;

	return;
}

sub _check_aux_time_tokens {
	my $tok = shift;

	if ($tok->{'type'} ne 'AUX_TIME') {
		return;
	}

	my ($left, $left_length) = _time_quote_at_start($tok->{'value'});
	if ($left ne '"') {
		err 'Bad quotation mark character.',
			'character' => $left,
			'position' => $tok->{'pos'},
		;
	}

	my ($right, $right_length) = _time_quote_at_end($tok->{'value'});
	if ($right ne '"') {
		err 'Bad quotation mark character.',
			'character' => $right,
			'position' => $tok->{'pos'} + length($tok->{'value'}) - $right_length,
		;
	}

	return;
}

sub _check_number_token {
	my $tok = shift;

	if ($tok->{'type'} ne 'NUMBER') {
		return;
	}
	if ($tok->{'value'} !~ /,/) {
		return;
	}

	err 'Bad dot character in number.',
		'position' => $tok->{'pos'} + index($tok->{'value'}, ','),
		'character' => ',',
	;
}

sub _time_quote_at_start {
	my $value = shift;

	if (substr($value, 0, 2) eq "''") {
		return ("''", 2);
	}

	return (substr($value, 0, 1), 1);
}

sub _time_quote_at_end {
	my $value = shift;

	if (substr($value, -2) eq "''") {
		return ("''", 2);
	}

	return (substr($value, -1), 1);
}

sub _consume {
	my $state = shift;

	return $state->{'tokens'}[$state->{'pos'}++];
}

sub _expect {
	my ($state, $type) = @_;

	my $tok = _peek($state);
	if (! $tok) {
		err "Expected '$type' but reached end of input.";
	}
	if ($tok->{'type'} ne $type) {
		err "Expected $type but got $tok->{'type'} ('$tok->{'value'}').",
			'position' => $tok->{'pos'},
		;
	}

	return _consume($state);
}

sub _parse_expression {
	my $state = shift;

	my $left = _parse_term($state);
	while (my $tok = _peek($state)) {
		if (! is_operator_token($tok->{'type'})) {
			last;
		}
		if (! is_valid_operator($tok->{'value'})) {
			last;
		}

		my $op = _consume($state);
		my $next = _peek($state)
			or err "Expected term after operator '$op->{'value'}'.";
		err "Token '$next->{'value'}' is not allowed after operator '$op->{'value'}'."
			if $next->{'type'} ne 'LBRACK'
			&& ! can_follow_operator($op->{'value'}, $next->{'type'});
		my $right = _parse_term_after_operator($state, $op->{'value'});

		if ($op->{'value'} eq '/' && $right->{'type'} eq 'APOS_AUX') {
			my ($base, $from) = _split_trailing_apos_aux($left);
			if (! $from) {
				err "Apostrophe auxiliary range shorthand '$op->{'value'}$right->{'value'}' ".
					"requires apostrophe auxiliary on the left side.",

					'position' => $op->{'pos'},
				;
			}

			$left = {
				type => 'APOS_RANGE',
				base => $base,
				from => $from->{'value'},
				to => $right->{'value'},
			};

			next;
		}

		$left = {
			type => 'BINARY_OP',
			operator => $tok->{'value'},
			left => $left,
			right => $right,
		};

		if ($op->{'value'} eq '/') {
			my @modifiers;
			my $current_type = 'NUMBER';
			my $current_value = undef;

			while (my $next_tok = _peek($state)) {
				if (! can_follow_primary(
					$next_tok->{'type'},
					$next_tok->{'value'},
					$current_type,
					$current_value,
				)) {
					last;
				}

				push @modifiers, {
					type => $next_tok->{'type'},
					value => $next_tok->{'value'},
				};

				$current_type = $next_tok->{'type'};
				$current_value = $next_tok->{'value'};

				_consume($state);
			}
			if (@modifiers) {
				$left = {
					type => 'TERM',
					primary => $left,
					modifiers => \@modifiers,
				};
			}
		}
	}

	return $left;
}

sub _parse_primary {
	my $state = shift;

	my $tok = _peek($state)
		or err 'Expected term but reached end of input.';

	if ($tok->{'type'} eq 'LBRACK') {
		return _parse_subgroup($state);
	}

	if (is_primary_token($tok->{'type'})) {
		_consume($state);
		return {
			'type' => $tok->{'type'},
			'value' => $tok->{'value'},
		};
	}

	if ($tok->{'type'} eq 'ALPHA_SPEC') {
		err "Alphabetical specification cannot appear standalone.",
			'position' => $tok->{'pos'},
			'value' => $tok->{'value'},
		;
	}

	if ($tok->{'type'} eq 'APOS_AUX') {
		err "Apostrophe auxiliary '$tok->{'value'}' must follow a valid UDC notation.";
	}

	err "Expected NUMBER, subgroup, or standalone auxiliary but got $tok->{'type'} ('$tok->{'value'}').",
		'position' => $tok->{'pos'},
	;
}

sub _parse_subgroup {
	my $state = shift;

	my $lbrack = _expect($state, 'LBRACK');
	my $expr = _parse_expression($state);

	my $end = _peek($state);
	if (! $end) {
		err "Unclosed subgroup '['.",
			'position' => $lbrack->{'pos'},
		;
	}
	if ($end->{'type'} ne 'RBRACK') {
		err "Expected closing ']' for subgroup but got '$end->{'value'}'.",
			'position' => $end->{'pos'},
		;
	}
	_consume($state);

	return {
		'type' => 'SUBGROUP',
		'expression' => $expr,
	};
}

sub _parse_term {
	my $state = shift;

	my $primary = _parse_primary($state);
	if ($primary->{'type'} ne 'NUMBER') {
		my $next = _peek($state);
		if ($next && $next->{'type'} eq 'NUMBER') {
			if (! can_precede_number($primary->{'type'}, $primary->{'value'})) {
				my $what = defined $primary->{'value'} ? $primary->{'value'} : $primary->{'type'};
				err "NUMBER cannot follow '$what'.";
			}

			my $number = _consume($state);

			my @modifiers;
			my $current_type = 'NUMBER';
			my $current_value = $number->{'value'};
			my $has_main_number = 1;
			while (my $tok = _peek($state)) {
				if (any { $tok->{'type'} eq $_ } qw(APOS_AUX AUX_DOT)) {
					if (! $has_main_number) {
						last;
					}
				} elsif (! can_follow_primary(
					$tok->{'type'},
					$tok->{'value'},
					$current_type,
					$current_value,
				)) {
					last;
				}

				push @modifiers, {
					'type' => $tok->{'type'},
					'value' => $tok->{'value'},
				};

				$current_type = $tok->{'type'};
				$current_value = $tok->{'value'};

				_consume($state);
			}

			return {
				'type' => 'TERM',
				'prefixes' => [
					{
						'type' => $primary->{'type'},
						'value' => $primary->{'value'},
					},
				],
				'primary' => {
					'type' => 'NUMBER',
					'value' => $number->{'value'},
				},
				'modifiers' => \@modifiers,
			};
		}
	}

	my @modifiers;
	my $current_type = $primary->{'type'};
	my $current_value = $primary->{'value'};
	my $allow_dot_aux = any { $primary->{'type'} eq $_ } qw(NUMBER SUBGROUP);
	while (my $tok = _peek($state)) {
		if ($tok->{'type'} eq 'LBRACK') {
			my $subgroup = _parse_primary($state);

			push @modifiers, $subgroup;

			$current_type = $subgroup->{'type'};
			$current_value = undef;

			next;
		}

		if ($tok->{'type'} eq 'AUX_DOT') {
			if (! $allow_dot_aux) {
				last;
			}
		}
		if (! can_follow_primary(
			$tok->{'type'},
			$tok->{'value'},
			$current_type,
			$current_value,
		)) {
			last;
		}

		push @modifiers, {
			'type' => $tok->{'type'},
			'value' => $tok->{'value'},
		};

		$current_type = $tok->{'type'};
		$current_value = $tok->{'value'};

		_consume($state);
	}

	return {
		'type' => 'TERM',
		'primary' => $primary,
		'modifiers' => \@modifiers,
	};
}

sub _parse_term_after_operator {
	my ($state, $op) = @_;

	my $tok = _peek($state)
		or err "Expected term after operator '$op'.";

	if ($op eq '/' && $tok->{'type'} eq 'AUX_DOT') {
		_consume($state);
		return {
			type => 'PARTIAL_NUMBER',
			value => $tok->{'value'},
		};
	}

	if ($op eq '/' && $tok->{'type'} eq 'FORM') {
		_consume($state);
		return {
			type => 'PARTIAL_FORM',
			value => $tok->{'value'},
		};
	}

	if ($op eq '/' && $tok->{'type'} eq 'APOS_AUX') {
		_consume($state);
		return {
			type => 'APOS_AUX',
			value => $tok->{'value'},
		};
	}

	return _parse_term($state);
}

sub _peek {
	my $state = shift;

	return $state->{'tokens'}[$state->{'pos'}];
}

sub _normalize_alpha_spec_token {
	my $tok = shift;

	if ($tok->{'type'} ne 'ALPHA_SPEC') {
		return;
	}

	my ($value, $pos) = _trim_alpha_spec_value($tok);
	$tok->{'pos'} = $pos;
	$tok->{'value'} = $value;

	return;
}

sub _trim_alpha_spec_value {
	my $tok = shift;
	my $value = $tok->{'value'};
	my $pos = $tok->{'pos'};

	if ($value =~ s/^(\s+)//) {
		$pos += length($1);
	}
	$value =~ s/\s+\z//;

	return ($value, $pos);
}

sub _split_trailing_apos_aux {
	my $node = shift;

	if (! defined $node) {
		return;
	}
	if ($node->{'type'} ne 'TERM') {
		return;
	}
	if (! $node->{'modifiers'} || ! @{$node->{'modifiers'}}) {
		return;
	}

	my @modifiers = @{$node->{'modifiers'}};
	my $last = $modifiers[-1];
	if (! defined $last || $last->{'type'} ne 'APOS_AUX') {
		return;
	}

	pop @modifiers;

	my $base = {
		type => 'TERM',
		primary => $node->{'primary'},
		modifiers => \@modifiers,
	};

	if (exists $node->{'prefixes'}) {
		$base->{'prefixes'} = [ @{$node->{'prefixes'}} ];
	}

	return ($base, $last);
}

1;

__END__
