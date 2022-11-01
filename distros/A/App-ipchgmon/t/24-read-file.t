use strict;
use warnings;
use Test::More;
use Test::Exception;
use Text::CSV;
use FindBin qw( $RealBin );
use lib "$RealBin/../lib";

use App::ipchgmon;

# This tests the read_file sub. It is essential to be able to write
# a test file.

my $dir = "$RealBin/..";

SKIP: {
    # If the directory is not writable, the tests cannot pass,
    # so ignore them
    skip "Unable to write to $dir" unless -w $dir;

    if ($^O =~ m/win/i) {
        # Invalid file name throws an error on Windows
        my $dudname = '/' . chr(0); # this ought to be invalid in *u*x and ms*
                                    # but works on at least some linuxes  
        $App::ipchgmon::opt_file = $dudname;
        # "Invalid argument" is thrown by Text::CSV, so trying to improve on it
        # is strange, but the CPAN test routine generates 
        # "No such file or directory", causing a failure.
        throws_ok {App::ipchgmon::read_file()} qr/Invalid argument|No such file/, 
            'Invalid file name dies OK';
    }

    my $fqname = $dir . '/test.txt';

    # The typical file will be a csv that is read into an aoaref.
    my $aoaref = [
        ["11.11.11.11",     "Fri Aug 28 00:00:00 2022"],
        ["101.101.101.101", "Fri Aug 28 01:01:01 2022"],
        ["B::0",            "Fri Aug 28 00:00:00 2022"],
        ["B::1",            "Fri Aug 28 01:01:01 2022"],
    ];
    open my $fh, ">:encoding(utf8)", $fqname or die "Couldn't create $fqname: $!";
    my $csv = Text::CSV->new();
    $csv->say ($fh, $_) for @$aoaref;
    close $fh or die "Couldn't close $fqname: $!";
    
    # Pass the file name as though it were a parameter
    $App::ipchgmon::opt_file = $fqname;
    my $aoa = App::ipchgmon::read_file();
    is $$aoa[0][0], '11.11.11.11',              'first ip4 address';
    is $$aoa[0][1], 'Fri Aug 28 00:00:00 2022', 'first ip4 timestamp';
    is $$aoa[1][0], '101.101.101.101',          'second ip4 address';
    is $$aoa[1][1], 'Fri Aug 28 01:01:01 2022', 'second ip4 timestamp';
    is $$aoa[2][0], 'B::0',                     'first ip6 timestamp';
    is $$aoa[2][1], 'Fri Aug 28 00:00:00 2022', 'first ip6 address';
    is $$aoa[3][0], 'B::1',                     'second ip6 timestamp';
    is $$aoa[3][1], 'Fri Aug 28 01:01:01 2022', 'second ip6 address';
    # The test below is the only one really needed, but if there is a
    # problem, the detail above may help. 
    is_deeply $aoa, $aoaref, 'Aoa saves & reads correctly';

    unlink $fqname or warn "Unable to delete $fqname at end of tests.";
}

done_testing();
