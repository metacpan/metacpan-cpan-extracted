use 5.010;
use strict;
use warnings;
use lib qw(t);

use Test::Most;
use Test::Trap;
use Test::File;
use testdata::setup;
use App::ArchiveDevelCover;

my $temp = testdata::setup::tmpdir();

{
    my $run = testdata::setup::run($temp,'run_1');

    my $a = App::ArchiveDevelCover->new(
        from=>$run->subdir('does_not_exists'),
        to=>$temp->subdir('archive'),
    );
    trap { $a->run; };
    is ( $trap->exit, 0, 'exit() == 0' );
    like($trap->stdout,qr/cannot find 'coverage.html'/i,'error message: cannot find coverage.html');
}

done_testing();
