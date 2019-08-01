# perl
use v5.18;
use File::Spec::Functions qw< catfile >;
use File::Basename qw< basename >;
use FindBin qw< $Bin $Script >;
use Test2::V0;

use App::p5find qw(p5_doc_iterator);

subtest "see p5find.pm is found" => sub {
    my $iter = p5_doc_iterator( catfile($Bin, "..")  );
    my $found = 0;
    while(my $dom = $iter->()) {
        my $fb = basename( $dom->filename );
        if ($fb eq "p5find.pm") {
            $found = 1;
            last;
        }
    }
    ok $found;
};

subtest "see if current test file is found" => sub {
    my $this_test_file = catfile($Bin, $Script);
    my $iter = p5_doc_iterator( $Bin );
    my $found = 0;
    while(my $dom = $iter->()) {
        if ($dom->filename eq $this_test_file) {
            $found = 1;
            last;
        }
    }
    ok $found;
};

done_testing;
