package Data::Hash::Diff::Smart::Renderer::Test2;

use strict;
use warnings;

sub render {
	my ($changes) = @_;

	return '' unless @$changes;

	my @out;

	for my $c (@$changes) {
		my $op   = $c->{op};
		my $path = $c->{path};

		if ($op eq 'change') {
			push @out,
				"Difference at $path",
				'  - ' . ($c->{from}  // ''),
				'  + ' . ($c->{to}    // ''),
				'';
		} elsif ($op eq 'add') {
			push @out,
				"Added at $path",
				'  + ' . ($c->{value} // ''),
				'';
		} elsif ($op eq 'remove') {
			push @out,
				"Removed at $path",
				'  - ' . ($c->{from}  // ''),
				'';
		} else {
			push @out, "Unknown op '$op' at $path";
		}
	}

	# Prefix each line with '# ' so Test2::Diag displays it cleanly
	return join("\n", map { "# $_" } @out) . "\n";
}

1;
