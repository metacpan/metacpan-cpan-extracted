#!perl
# generate labelled test data with DD for baselining DDez

use Data::Dumper;
use base 'Exporter';

use vars qw($AR  $HR  @ARGold  @HRGold  @Arrays  @ArraysGold  @LArraysGold);
@EXPORT =  ($AR, $HR, @ARGold, @HRGold, @Arrays, @ArraysGold, @LArraysGold);
	    

# ref data
$AR = [qw/ hello there /, [qw/ nested data /]];
$HR = {qw/ alpha 1 beta 2 gamma 3 delta 4 zed 26 /,
	   nest => { level => 42 }};

# more ref data
@Arrays =
    (
     [qw/ odd length list /],
     [qw/ an even length list /],

     [ 'odd', 'length', [qw/ with nesting /] ],
     [ 'even', [qw/with nesting/], 'length', [qw/ on-even positions /] ],
     [ 'even', 'length', [qw/with nesting/], [qw/ in-both positions /] ],
     );


# ref output: each array holds [terse 0..1][indent 0..2]
#our (@ARGold, @HRGold, @ArraysGold);	# from $AR, $HR respectively


unless ($ENV{TEST_FAIL}) {
    # get baseline output for $AR, $HR
    for my $i (0..3) {
	local $Data::Dumper::Indent = $i;
	push @{$ARGold[0]}, Data::Dumper->Dump([$AR]=>["indent$i"]);
	push @{$HRGold[0]}, Data::Dumper->Dump([$HR]=>["indent$i"]);
	
	local $Data::Dumper::Terse = 1;
	push @{$ARGold[1]}, Data::Dumper->Dump([$AR]=>["indent$i"]);
	push @{$HRGold[1]}, Data::Dumper->Dump([$HR]=>["indent$i"]);
    }

    for my $i (0..$#Arrays) {
	# unlabelled and labelled
	push ( @ArraysGold, Dumper($Arrays[$i]));
	push ( @LArraysGold
	       , Data::Dumper->Dump([$Arrays[$i]]=>["item$i"]));
    }
}

#print @ArraysGold;

1;

