# -*- cperl -*-

use warnings;
use strict;
use 5.10.1;

use Test::More ;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;
use Path::Tiny;
use Test::File::Contents;

use App::Cmd::Tester;
use App::Cme ;
use Tk;

my ($model, $trace) = init_test();

# edit and plugin need to be in separate test files. Otherwise the 2
# Tk widgets created one after the other interacts badly and the save
# callback of -save-and-quit option is not called after the first test.

SKIP: {
    my $mw = eval { MainWindow-> new ; };

    # cannot create Tk window
    skip "Cannot create Tk window",1 if $@;
    $mw->destroy ;

    my $wr_test = path('wr_test/plugin-ui') ;

    $wr_test->remove_tree if $wr_test->is_dir;

    $wr_test->mkpath;
    $wr_test->child('models')->mkpath;

    {
        # test plugin
        my $plug_data = q!class:"Fstab::CommonOptions" element:async mandatory=1 !;
        my $plug = $wr_test->child('plug.cds');
        $plug->spew($plug_data);

        my @test_args = (
            qw/meta plugin fstab my-plugin/,
            '-test-and-quit' => 's',
            '-load' => $plug->stringify,
            '-dir' => $wr_test->stringify,
        );

        say "test command: cme @test_args" if $trace;
        my $result = test_app( 'App::Cme' => \@test_args ) ;

        is($result->error, undef, 'threw no exceptions');
        is($result->stderr, '', 'nothing sent to sderr');

        say "-- stdout --\n", $result->stdout,"-----"  if $trace;

        like($result->stdout , qr/Preparing plugin my-plugin for model Fstab/, "edit plugin and quit");
        like($result->stdout , qr/Test mode: save and quit/, "edit plugin is in test mode");
        my $plug_out = $wr_test->child('models/Fstab.d/my-plugin/Fstab/CommonOptions.pl');
        file_contents_like $plug_out,  qr/'mandatory' => '1'/, "check content of $plug_out";
    }
}

done_testing;
