# perl
use v5.18;
use File::Spec::Functions qw< catfile >;
use File::Basename qw< basename >;
use FindBin qw< $Bin $Script >;
use Test2::V0;

use App::p5find qw(p5_source_file_iterator);

subtest "see p5find.pm is found" => sub {
    my $iter = p5_source_file_iterator( catfile($Bin, "..")  );
    my $found = 0;
    while(my $f = $iter->()) {
        my $fb = basename($f);
        if ($fb eq "p5find.pm") {
            $found = 1;
            last;
        }
    }
    ok $found;
};

subtest "see if current test file is found" => sub {
    my $this_test_file = catfile($Bin, $Script);
    my $iter = p5_source_file_iterator( $Bin );
    my $found = 0;
    while(my $f = $iter->()) {
        if ($f eq $this_test_file) {
            $found = 1;
            last;
        }
    }
    ok $found;
};

done_testing;
