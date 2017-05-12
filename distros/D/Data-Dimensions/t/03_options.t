#! perl

use Test::Simple tests => 3;

use Data::Dimensions;

Data::Dimensions->push_handler(\&myunits);

sub myunits {
    my ($hr, $scale) = @_;
    my %temp = %$hr;

    if (exists $temp{FOO}) {
	$FOO++; 
	delete $temp{FOO};
	$temp{m} += 1;
	$scale *= 10;
    }
    return (\%temp, $scale);
}	

ok(1, "loaded, set handler");
$FOO = 0;
my $foo = Data::Dimensions->new({FOO=>1});

ok($FOO == 1, "special handler called");

my $bar = Data::Dimensions->new({m=>1});

$foo->set = 10;
$bar->set = $foo;

ok($bar == 100, "scaling and units found their way the right way")
