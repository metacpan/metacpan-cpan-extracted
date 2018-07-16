# -*- cperl -*-

use warnings;
use strict;
use 5.10.1;

use Test::More ;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;
use Path::Tiny;
use Test::File::Contents;
use Getopt::Long;

use App::Cmd::Tester;
use App::Cme ;
use Tk;

init_test();

# edit and plugin need to be in separate test files. Otherwise the 2
# Tk widgets created one after the other interacts badly and the save
# callback of -save-and-quit option is not called after the first test.

SKIP: {
    my $mw = eval { MainWindow-> new ; };

    # cannot create Tk window
    skip "Cannot create Tk window",1 if $@;
    $mw->destroy ;

    {
        my $result = test_app( 'App::Cme' => [ qw/meta edit fstab -system -test-and-quit q/ ]) ;
        like($result->stdout , qr/Reading model from/, "edit and quit");
        like($result->stdout , qr/Test mode: quit/, "edit is in test mode");
    }
}

done_testing;
