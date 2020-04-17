use strict;
use warnings;
use Test::More;
use Test::More::UTF8;
use Encode;
use Capture::Tiny 'capture_stderr';
use FindBin '$RealBin';

my $expected = q{Can't call method "Dumper" on unblessed reference};

subtest 'function is not imported via loading object' => sub {
    my $dump = capture_stderr(sub {
        qx{perl $RealBin/no-import-into.pl}
    });

    like( $dump, qr/$expected/, 'output ok' );
};

done_testing;
__END__