package Dwarf::Util::DateTime;
use Dwarf::Pragma;
use DateTime;
use DateTime::Format::Strptime;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(is_duration_positive epoch2dt str2dt);

sub is_duration_positive {
	my ($dt1, $dt2) = @_;
	die "Something's wrong" if not defined $dt1 or not defined $dt2;
	my $duration = $dt1 - $dt2;
	$duration->is_positive;
}

# エポック秒から DateTime オブジェクトを生成する
sub epoch2dt {
	my ($epoch) = @_;
	return DateTime->from_epoch(
		epoch     => $epoch,
		time_zone => 'Asia/Tokyo',
	);
}

# 文字列でも DateTime オブジェクトでも渡して構わない
sub str2dt {
	my ($string) = @_;
	return $string if (ref($string) and ref($string) eq 'DateTime');
	$string =~ s|^(\d\d-\d\d)$|$1T00:00:00|;
	$string =~ s|T(\d\d:\d\d)$|T$1:00|;
	$string =~ s|^(\d\d-\d\d)T|2013-$1T|;
	$string =~ s|^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2})|$1T$2|;
	DateTime::Format::Strptime->new(pattern => '%FT%T', time_zone => 'Asia/Tokyo')->parse_datetime($string);
}

1;
