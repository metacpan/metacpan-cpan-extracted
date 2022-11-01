use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::File;
use FindBin qw( $RealBin );
use lib "$RealBin/../lib";

use App::ipchgmon;

# This tests the new_ip sub. A new file should be created if none
# exists and a new ip address is found.

# An invalid filename ought to throw an error regardless of any
# directory issues
my $dudname = '/' . chr(0); # this ought to be invalid in *u*x and ms*
$App::ipchgmon::opt_file = $dudname;
throws_ok {App::ipchgmon::new_ip()} qr/Unable to append to/, 'Invalid file name dies OK';

SKIP: {
    # If the directory is not writable, these tests cannot pass,
    # so ignore them
    skip "Unable to write to $RealBin" unless -w $RealBin;
    my $fqname = $RealBin . '/test.txt';
    # Pass the file name as though it were a command line parameter
    $App::ipchgmon::opt_file = $fqname;
    # Pass IPv4 and IPv6 addresses through new_ip
    App::ipchgmon::new_ip('123.123.123.123');
    App::ipchgmon::new_ip('A::1');
    file_exists_ok($fqname, 'New file should be created ...');
    file_not_empty_ok($fqname, '... and should contain something.');

    # Read the entire file. No need for File::Slurp for something so basic
    my $tmpsep = $/;
    open my $fh, '<', $fqname;
    undef $/; # No line separator
    my $contents = <$fh>;
    close $fh;
    $/ = $tmpsep; # Tidy up!
    like $contents, qr(123\.123\.123\.123), 'IPv4 address saved correctly';
    like $contents, qr(A::1),               'IPv6 address saved correctly';

    unlink $fqname or warn "Unable to delete $fqname at end of tests.";
}

done_testing;
