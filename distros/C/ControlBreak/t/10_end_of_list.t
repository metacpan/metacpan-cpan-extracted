# Test suite for ControlBreak

use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use Test::More tests => 1;

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Capture::Tiny ':all';

my ($stdout, $stderr, $exit) = capture {
    synopsis();
};


my $expected = <<__EX__;
Canada,Alberta,1019942*
Canada,Ontario,3412129*
Canada,Quebec,2397919*
Canada total,,6829990**
USA,Arizona,1640641*
USA,California,4946673*
USA,Illinois,2756546*
USA,New York,9211759*
USA,Pennsylvania,1619355*
USA,Texas,2345606*
USA total,,22520580**
Grand total,,29350570***
__EX__


is $stdout, $expected;

sub synopsis {
    use v5.18;

    use lib $FindBin::Bin . '/../lib';

    use ControlBreak;

    # set up two levels, in minor to major order, and an extra level
    # for tracking the end of the file
    my $cb = ControlBreak->new( qw( District Country EOL ) );


    my @totals;

    # set up some level number variables for convenient indexing into @totals
    my ($L1, $L2, $L3) = $cb->level_numbers;

    my @data = <DATA>;

    # iterations begin at zero and are incremented during the call
    # to test() -- which is called within test_and_do().  So, the
    # iteration number of the last value in the list -- for the
    # purpose of comparison to the iteration number before a test
    # method is called -- is the list length minus one.
    my $last_iter = @data - 1;

    foreach my $line (@data) {
        chomp $line;

        my ($country, $district, $city, $population) = split ',', $line;

        # # test the values (minor to major order) using perl eof to
        # # detect the last record of the file and trigger an EOF break
        # $cb->test($district, $country, $cb->iteration == $last_record);
        my $sub_totals = sub {
            # break on District (or Country) detected
            if ($cb->break('District')) {
                say join ',', $cb->last('Country'), $cb->last('District'), $totals[$L1] . '*';
                $totals[$L1] = 0;
            }

            # break on Country detected
            if ($cb->break('Country')) {
                say join ',', $cb->last('Country') . ' total', '', $totals[$L2] . '**';
                $totals[$L2] = 0;
            }
            # break at end of list
            if ($cb->break('EOL')) {
                say 'Grand total,,', $totals[$L3], '***';
            }

            # accumulate subtotals
            map { $totals[$_] += $population } $cb->level_numbers;
        };

        $cb->test_and_do($district, $country, $cb->iteration == $last_iter, $sub_totals);
    }
}

__DATA__
Canada,Alberta,Calgary,1019942
Canada,Ontario,Ottawa,812129
Canada,Ontario,Toronto,2600000
Canada,Quebec,Montreal,1704694
Canada,Quebec,Quebec City,531902
Canada,Quebec,Sherbrooke,161323
USA,Arizona,Phoenix,1640641
USA,California,Los Angeles,3919973
USA,California,San Jose,1026700
USA,Illinois,Chicago,2756546
USA,New York,New York City,8930002
USA,New York,Buffalo,281757
USA,Pennsylvania,Philadelphia,1619355
USA,Texas,Houston,2345606
