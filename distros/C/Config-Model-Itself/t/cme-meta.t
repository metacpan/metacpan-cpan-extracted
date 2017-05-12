# -*- cperl -*-

use warnings;
use strict;
use 5.10.1;

use Test::More ;
use Config::Model;
use Path::Tiny;
use Test::File::Contents;

use App::Cmd::Tester;
use App::Cme ;

my $arg = shift || '';
my ( $log, $show ) = (0) x 2;

my $trace = $arg =~ /t/ ? 1 : 0;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

my $wr_test = path('wr_test/meta') ;

$wr_test->remove_tree if $wr_test->is_dir;

$wr_test->mkpath;

SKIP: {
    skip "dev list does not yet work" ,1 ;
    my $result = test_app( 'App::Cme' => [ qw/list/]) ;
    like($result->stdout , qr/meta/, "meta sub command is found in dev env");
}

{
   my $result = test_app( 'App::Cme' => [ qw/help meta/]) ;
   like($result->stdout , qr/create configuration checker or editor/, "check help");
}
{
   my $result = test_app( 'App::Cme' => [ qw/meta check fstab -system/]) ;
   like($result->stdout , qr/checking data/, "meta check fstab");
}

# TODO: group tests with Test::Class or Test::Group ?

{
   my $cds_out = $wr_test->child('fstab.cds');
   my $result = test_app( 'App::Cme' => [ qw/meta dump fstab -system/, $cds_out->stringify ]) ;
   like($result->stdout , qr/Dumping Fstab/, "dump fstab model in $cds_out");
   file_contents_like $cds_out,  qr/^class:Fstab/, "check content of $cds_out";
}

{
   my $yaml_out = $wr_test->child('fstab.yml');
   my $result = test_app( 'App::Cme' => [ qw/meta dump-yaml fstab -system/, $yaml_out->stringify ]) ;
   like($result->stdout , qr/Dumping Fstab/, "dump fstab model in $yaml_out");
   file_contents_like $yaml_out,  qr/class:\n\s+Fstab:\n/, "check content of $yaml_out";
}
{
   my $dot_out = $wr_test->child('fstab.dot');
   my $result = test_app( 'App::Cme' => [ qw/meta gen-dot fstab -system/, $dot_out->stringify ]) ;
   like($result->stdout , qr/Creating dot file/, "dot diagram of Fstab in $dot_out");
   file_contents_like $dot_out,  qr/Fstab -> Fstab__FsLine/, "check content of $dot_out";
}


done_testing;
