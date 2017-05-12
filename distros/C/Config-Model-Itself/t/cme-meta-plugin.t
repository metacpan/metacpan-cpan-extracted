# -*- cperl -*-

use warnings;
use strict;
use 5.10.1;

use Test::More ;
use Config::Model;
use Path::Tiny;
use Test::File::Contents;

use File::Copy::Recursive qw(fcopy rcopy dircopy);

use App::Cmd::Tester;
use App::Cme ;
use Tk;

my $arg = shift || '';
my ( $log, $show ) = (0) x 2;

my $trace = $arg =~ /t/ ? 1 : 0;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

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

    {
        # test plugin
        my $plug_data = q!class:"Fstab::CommonOptions" element:async mandatory=1 !;
        my $plug = $wr_test->child('plug.cds');
        $plug->spew($plug_data);

        my $result = test_app(
            'App::Cme' => [
                qw/meta plugin fstab my-plugin/,
                '-test-and-quit' => 's',
                '-load' => $plug->stringify,
                '-dir' => $wr_test->stringify,
            ]
        ) ;

        say $result->stdout if $trace;

        like($result->stdout , qr/Preparing plugin my-plugin for model Fstab/, "edit plugin and quit");
        like($result->stdout , qr/Test mode: save and quit/, "edit plugin is in test mode");
        my $plug_out = $wr_test->child('models/Fstab.d/my-plugin/Fstab/CommonOptions.pl');
        file_contents_like $plug_out,  qr/'mandatory' => '1'/, "check content of $plug_out";
    }
}

done_testing;
