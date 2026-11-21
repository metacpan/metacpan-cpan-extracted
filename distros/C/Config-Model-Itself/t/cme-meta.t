# -*- cperl -*-

use warnings;
use strict;
use 5.10.1;

use Test::More ;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;
use Path::Tiny;
use Test::File::Contents;

use App::Cmd::Tester;
use App::Cme ;

binmode STDOUT, ':encoding(UTF-8)';

my ($model, $trace) = init_test();

my $wr_test = setup_test_dir ;

subtest "help meta" => sub {
    my $result = test_app( 'App::Cme' => [ qw/help meta/]) ;
    like($result->stdout , qr/create configuration checker or editor/, "check help");
    is($result->stderr, '', 'nothing sent to sderr');
    is($result->error, undef, 'threw no exceptions');
};

subtest "meta check fstab" => sub {
    my $result = test_app( 'App::Cme' => [ qw/meta check fstab -system/]) ;
    like($result->stdout , qr/checking data/, "meta check fstab");
    is($result->stderr, '', 'nothing sent to sderr');
    is($result->error, undef, 'threw no exceptions');
};

subtest "dump fstab model as cds" => sub {
    my $cds_out = $wr_test->child('fstab.cds');
    my $result = test_app( 'App::Cme' => [ qw/meta dump fstab -system/, $cds_out->stringify ]) ;
    like($result->stdout , qr/Dumping Fstab/, "dump fstab model in $cds_out");
    is($result->stderr, '', 'nothing sent to sderr');
    is($result->error, undef, 'threw no exceptions');
    file_contents_like $cds_out,  qr/^class:Fstab/, "check content of $cds_out";
};

subtest "dump fstab model as YAML" => sub {
    my $yaml_out = $wr_test->child('fstab.yml');
    my $result = test_app( 'App::Cme' => [ qw/meta dump-yaml fstab -system/, $yaml_out->stringify ]) ;
    like($result->stdout , qr/Dumping Fstab/, "dump fstab model in $yaml_out");
    is($result->stderr, '', 'nothing sent to sderr');
    is($result->error, undef, 'threw no exceptions');
    file_contents_like $yaml_out,  qr/class:\n- Fstab\n/, "check content of $yaml_out";
};

subtest "dump fstab model as dot file" => sub {
    my $dot_out = $wr_test->child('fstab.dot');
    my $result = test_app( 'App::Cme' => [ qw/meta gen-dot fstab -system/, $dot_out->stringify ]) ;
    like($result->stdout , qr/Creating dot file/, "dot diagram of Fstab in $dot_out");
    is($result->stderr, '', 'nothing sent to sderr');
    is($result->error, undef, 'threw no exceptions');
    file_contents_like $dot_out,  qr/Fstab -> Fstab__FsLine/, "check content of $dot_out";
};

done_testing;
