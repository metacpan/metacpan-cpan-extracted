#!perl

# generate test data with DD for baselining DDez
use Data::Dumper;
use base 'Exporter';

# these vars hold data structures, and ref output that DD produces

use vars qw($AR $HR @ARGold @HRGold);
@EXPORT = ($AR, $HR, @ARGold, @HRGold);

# ref data
$AR = [qw/ hello there /, [qw/ nested data /]];
$HR = {qw/ alpha 1 beta 2 gamma 3 delta 4 zed 26 /,
	   nest => { level => 42 }};


unless ($ENV{TEST_FAIL}) {
    # get baseline output for $AR, 
    for my $i (0..3) {
	local $Data::Dumper::Indent = $i;
	push @{$ARGold[0]}, Dumper($AR);
	push @{$HRGold[0]}, Dumper($HR);
	
	local $Data::Dumper::Terse = 1;
	push @{$ARGold[1]}, Dumper($AR);
	push @{$HRGold[1]}, Dumper($HR);
    }
}

1;

