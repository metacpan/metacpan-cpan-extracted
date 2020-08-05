package Bosch::RCPPlus::Utils;
use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(bytes2int);

sub bytes2int
{
	my ($a, $unsigned) = @_;
	my $back = 0;

	if ($a) {
		my $length = scalar @{$a};
		for (my $i = 0; $i < $length; $i++) {
			my $idx = $length - 1 - $i;
			my $val = $a->[$idx];
			# back += val<<(i*8)
			$back += $val * (256 ** $i);
		}

		if (not $unsigned) {
			if (($a->[0] & 0x80) > 0) {
				# 1st bit is set --> negative number
				my $intMax = 2 ** ($length * 8) - 1;
				$back = ($intMax - $back + 1) * (-1);
			}
		}
	}

	return $back;
}

1;
