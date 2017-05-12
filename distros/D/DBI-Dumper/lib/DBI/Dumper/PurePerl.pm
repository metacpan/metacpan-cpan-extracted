package DBI::Dumper::PurePerl;

use strict;
use warnings;

my ($escape, $terminator, $left, $right, $escape_regex);

sub init {
	my ($self) = @_;

	$escape = $self->{escape};
	$terminator = $self->{terminator};
	($left, $right) = ($self->{left_delim}, $self->{right_delim});

	# do not escape embedded terminators if enclosures provided
	my $terminator_regex_str = ($left eq '' && $right eq '') ? $terminator : '';

	my %escape;
	my $escape_regex_string = join('|', map {
		quotemeta $_
	} grep {
		$_ ne '' && !$escape{ $_ }++;
	} ($escape, $terminator_regex_str, $left, $right));
	$escape_regex = qr{($escape_regex_string)};
}

sub build {
	my ($self, $row) = @_;

	my $data = '';
	my $i = 0;
	for (@$row) {
		$_ = defined $_ ? $_ : '';

		s/$escape_regex/$escape$1/g;

		$data .= ($i ? $terminator : '');
		$data .= $left . $_ . $right;
		$i++;
	}
	$data .= "\n";

	return $data;
}

1;
