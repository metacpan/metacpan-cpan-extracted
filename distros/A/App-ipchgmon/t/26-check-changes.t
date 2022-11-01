use strict;
use warnings;
use Test::More;
use Text::CSV;
use FindBin qw( $RealBin );
use lib "$RealBin/../lib";

use App::ipchgmon;

# This tests the check_changes sub, which should write to the log
# file if any changes are detected.

my $dir = "$RealBin/..";

SKIP: {
    # If the directory is not writable, the tests cannot pass,
    # so ignore them
    skip "Unable to write to $RealBin" unless -w $dir;
    
    # Write IPv4 & 6 lines and check that they can be read properly
    my $fqname = $dir . '/test.txt';
    $App::ipchgmon::opt_file = $fqname;
    App::ipchgmon::check_changes('102.0.0.0', undef);
    App::ipchgmon::check_changes('C::0', undef);
    my $aoaref = App::ipchgmon::read_file();
    is scalar @$aoaref, 2, 'Two lines written to file';
    is $$aoaref[0][0], '102.0.0.0', 'ip4 address written correctly';
    is $$aoaref[1][0], 'C::0',      'ip6 address written correctly';
    is $$aoaref[0][1], $$aoaref[0][1], 'Timestamps agree';
    ok defined($$aoaref[0][1]), "Timestamps are not null ($$aoaref[0][1])"
        or diag "Timestamp on first line is undef:\n>$$aoaref[0][1]<";

    # Simulate the change of both IP addresses. Two more lines should
    # be written and read correctly.
    App::ipchgmon::check_changes('102.0.0.1', $aoaref);
    App::ipchgmon::check_changes('C::1', $aoaref);
    $aoaref = App::ipchgmon::read_file();
    is scalar @$aoaref, 4, 'Two more lines written to file, total 4';
    is $$aoaref[2][0], '102.0.0.1', 'ip4 address written correctly';
    is $$aoaref[3][0], 'C::1',      'ip6 address written correctly';
    is $$aoaref[2][1], $$aoaref[3][1], 'Timestamps agree';
    ok defined($$aoaref[2][1]), "Timestamps are not null ($$aoaref[2][1])"
        or diag "Timestamp on third line is undef:\n>$$aoaref[2][1]<";

    # Simulate the finding of the same two IP addresses.
    # No new lines should be written.
    App::ipchgmon::check_changes('102.0.0.1', $aoaref);
    App::ipchgmon::check_changes('C::1', $aoaref);
    $aoaref = App::ipchgmon::read_file();
    is scalar @$aoaref, 4, 'Repeats should not be written';
    
    unlink $fqname or warn "Unable to delete $fqname at end of tests.";
}

done_testing();
