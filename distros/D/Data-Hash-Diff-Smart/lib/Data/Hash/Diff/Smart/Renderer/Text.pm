package Data::Hash::Diff::Smart::Renderer::Text;

use strict;
use warnings;

sub render {
	my $changes = $_[0];

	return '' unless @{$changes};

	my @out;

	for my $c (@$changes) {
		my $op   = $c->{op};
		my $path = $c->{path};

		if ($op eq 'change') {
			push @out,
				"~ $path",
				'- ' . ($c->{from}  // ''),
				'+ ' . ($c->{to}    // ''),
				'';
		} elsif ($op eq 'add') {
			push @out,
				"+ $path",
				'+ ' . ($c->{value} // ''),
				'';
		} elsif ($op eq 'remove') {
			push @out,
				"- $path",
				'- ' . ($c->{from}  // ''),
				'';
		} else {
			push @out, "# unknown op: $op";
		}
	}

	return join("\n", @out) . "\n";
}

1;
