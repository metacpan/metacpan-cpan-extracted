package App::SimpleBackuper;

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT = qw(fmt_weight fmt_datetime fmt_time fmt_hex2base64);

sub fmt_weight {
	my($weight) = @_;
	my $unit = 'b';
	foreach my $u (qw(Kb Mb Gb Tb Pb)) {
		last if $weight < 1000;
		$weight /= 1000;
		$unit = $u;
	}

	if(int(($weight - int($weight)) * 10) == 0) {
		return int($weight).$unit;
	} else {
		return sprintf("%.1f%s", $weight, $unit);
	}
}

sub fmt_datetime {
	my @dt = localtime(shift);
	return sprintf "%04u-%02u-%02u %02u:%02u:%02u", $dt[5] + 1900, $dt[4] + 1, $dt[3], $dt[2], $dt[1], $dt[0];
}

sub fmt_time {
	my $seconds = shift;
	my $minutes = int($seconds / 60);
	return int($seconds).'s' if ! $minutes;
	
	$seconds -= $minutes * 60;
	my $hours = int($minutes / 60);
	return sprintf "%02d:%02d", $minutes, $seconds if ! $hours;
	
	$minutes -= $hours * 60;
	my $days = int($hours / 24);
	return sprintf "%02d:%02d:%02d", $hours, $minutes, $seconds if ! $days;
	
	$hours -= $days * 24;
	return sprintf "%dd %02d:%02d:%02d", $days, $hours, $minutes, $seconds;
}

use MIME::Base64;
sub fmt_hex2base64 { MIME::Base64::encode_base64url(pack "h*", shift) }

1;
