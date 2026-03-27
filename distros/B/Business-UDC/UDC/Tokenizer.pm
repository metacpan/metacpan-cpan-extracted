package Business::UDC::Tokenizer;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(tokenize);

our $VERSION = 0.03;

sub tokenize {
	my ($input) = @_;
	my @tokens;

	pos($input) = 0;

	while (pos($input) < length($input)) {
		if ($input =~ /\G\s+/gc) {
			next;
		}

		my $start = pos($input);

		if ($input =~ /\G(\d+(?:\.\d+)*)/gc) {
			push @tokens, {
				type => 'NUMBER',
				value => $1,
				pos => $start,
			};
			next;
		}

		if ($input =~ /\G(\.\d+(?:\.\d+)*)/gc) {
			push @tokens, {
				type => 'AUX_DOT',
				value => $1,
				pos => $start,
			};
			next;
		}

		if ($input =~ /\G(\[)/gc) {
			push @tokens, {
				type => 'LBRACK',
				value => $1,
				pos => $start,
			};
			next;
		}

		if ($input =~ /\G(\])/gc) {
			push @tokens, {
				type => 'RBRACK',
				value => $1,
				pos => $start,
			};
			next;
		}

		if ($input =~ /\G([:+\/])/gc) {
			push @tokens, {
				type => 'OP',
				value => $1,
				pos => $start,
			};
			next;
		}

		if ($input =~ /\G(-\d+(?:\.\d+)*)/gc) {
			push @tokens, {
				type => 'FORM',
				value => $1,
				pos => $start,
			};
			next;
		}

		if ($input =~ /\G(\([^)]+\))/gc) {
			push @tokens, {
				type => 'AUX_GROUP',
				value => $1,
				pos => $start,
			};
			next;
		}

		if ($input =~ /\G("[^"]*")/gc) {
			push @tokens, {
				type => 'AUX_TIME',
				value => $1,
				pos => $start,
			};
			next;
		}

		if ($input =~ /\G(=+(?:[A-Za-z]+|\d+(?:\.\d+)*))/gc) {
			push @tokens, {
				type => 'AUX_LANG',
				value => $1,
				pos => $start,
			};
			next;
		}

		if ($input =~ /\G(\p{L}[\p{L}\p{N}._-]*)/gcu) {
			push @tokens, {
				type => 'ALPHA_SPEC',
				value => $1,
				pos => $start,
			};
			next;
		}

		if ($input =~ /\G(\'\d+(?:\.\d+)*)/gc) {
			push @tokens, {
				type => 'APOS_AUX',
				value => $1,
				pos => $start,
			};
			next;
		}

		my $bad = substr($input, $start, 20);
		err "Unrecognized input near '$bad'.",
			'position' => $start,
		;
	}

	return \@tokens;
}

1;

__END__
