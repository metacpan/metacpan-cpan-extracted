use strict;
use warnings;
use Test::More;

use App::MigrateToTest2V0::CLI;
use App::Prove;
use File::Temp ();
use FindBin;
use PPI;

sub prove {
    my (@args) = @_;
    my $prove = App::Prove->new;
    $prove->process_args(@args);
    return $prove->run;
}

# prepare test script
my $fh = File::Temp->new;
my $test_content = do {
    open my $test_fh, "$FindBin::Bin/../share/stringify.t" or BAIL_OUT $!;
    local $/;
    my $content = <$test_fh>;
    close $test_fh;
    $content;
};
$fh->print($test_content);
$fh->flush;

# migrate to Test2::V0
App::MigrateToTest2V0::CLI->process($fh->filename);

{
    local $ENV{PERL5OPT} = '-MTest2::Plugin::Wrap2ndArgumentOfFailedCompareTestWithString';
    ok ! prove($fh->filename);
}
ok prove($fh->filename);

done_testing;
