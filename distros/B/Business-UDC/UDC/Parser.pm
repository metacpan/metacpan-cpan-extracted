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

our $VERSION = 0.03;

sub parse {
	my $input = shift;

	if (! defined $input) {
		err 'No input provided.';
	}
	if ($input !~ /\S/) {
		err 'Empty input.';
	}

	my $tokens = tokenize($input);
	my $state = {
		'tokens' => $tokens,
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
		err "Alphabetical specification '$tok->{'value'}' cannot appear standalone.";
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
