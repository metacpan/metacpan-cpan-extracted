package Dwarf::Util::Geo;
use Dwarf::Pragma;
use Math::Trig;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(distance2lat distance2lng);

sub distance2lat {
	my ($distance) = @_; # 単位はメートル
	my $radius = 6356752;
	my $circumference = 2 * pi * $radius;
	my $distance_of_sec = $circumference / (360 * 60 * 60);
	my $angle_of_sec = 1 / 60 / 60;
	my $one_meter = $angle_of_sec / $distance_of_sec;
	return $distance * $one_meter;
}

# デフォルトは経度の計算は東京の緯度（北緯 35 度）を基準
sub distance2lng {
	my ($distance, $lat) = @_; # 単位はメートル
	$lat //= 35;
	my $radius = 6356752;
	my $circumference =  $radius * cos($lat / 180 * pi) * 2 * pi;
	my $distance_of_sec = $circumference / (360 * 60 * 60);
	my $angle_of_sec = 1 / 60 / 60;
	my $one_meter = $angle_of_sec / $distance_of_sec;
	return $distance * $one_meter;
}

1;
