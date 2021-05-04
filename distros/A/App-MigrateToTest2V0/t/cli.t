use strict;
use warnings;
use App::MigrateToTest2V0::CLI;
use File::Temp;
use FindBin;
use Test::More;

# prepare test script
my $fh = File::Temp->new;
my $test_content = do {
    open my $test_fh, "$FindBin::Bin/../share/test.t" or BAIL_OUT $!;
    local $/;
    my $content = <$test_fh>;
    close $test_fh;
    $content;
};
$fh->print($test_content);

App::MigrateToTest2V0::CLI->process($fh->filename);

pass 'CLI run successfully';

done_testing;
