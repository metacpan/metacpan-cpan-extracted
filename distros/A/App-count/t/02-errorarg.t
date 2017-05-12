use Test::More;
use Test::Exception;
use App::count;
use Getopt::Config::FromPod;
Getopt::Config::FromPod->set_class_default(-file => 'bin/count');

sub check
{
	my ($arg, $qr, $name) = @_;
	throws_ok { App::count->run(@$arg) } $qr, $name;
}

my @tests = (
	(map { [[$_, 0], qr/Column number MUST be more than 0/, "zero with $_"] }
		qw(-g --group --sum -s --min --max --avg --ave)),
	(map { [[$_, 0], qr/Column number MUST NOT be 0/, "zero with $_"] }
		qw(-r --reorder)),
	(map { [[$_, "0,dummy"], qr/Column number MUST be more than 0/, "zero with $_"] }
		qw(-m --map)),
	(map { [[$_, 't/map.yaml'], qr/Column number MUST be more than 0/, "non-numeric with $_"] }
		qw(-g --group --sum -s --min --max --avg --ave -m --map)),
	(map { [[$_, 't/map.yaml'], qr/Column number MUST NOT be 0/, "non-numeric with $_"] }
		qw(-r --reorder)),
	(map { [[$_, 't/nonexistent'], qr@t/nonexistent@, "nonexistent file with $_"] }
		qw(-M --map-file)),
	(map { [[$_, "1,nonexistent"], qr/map is specified but map file is not specified/, "no map file with $_"] }
		qw(-m --map)),
	(map { [[$_, "1,nonexistent",'-M','t/map.yaml'], qr/Map key is not found in map file/, "nonexistent key with $_"] }
		qw(-m --map)),
	[['t/nonexistent'], qr@Can't open t/nonexistent@, 'nonexistent file'],
);

plan tests => scalar @tests;
check(@$_) for @tests;
