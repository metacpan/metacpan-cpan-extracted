use Test::Simple 'no_plan';
use strict;
use lib './lib';
use CGI::Scriptpaths ':all';
use Cwd;

$CGI::Scriptpaths::DEBUG = 1;

my $cwd = cwd();

mkdir './t/public_html';
mkdir './t/cgi-bin';



ok(1,'loaded');




my $script_abs_loc = script_abs_loc();
ok($script_abs_loc,"script_abs_loc is [$script_abs_loc]");
ok($script_abs_loc eq "$cwd/t");


my $script_abs_path = script_abs_path();
ok($script_abs_path,"script_abs_path is [$script_abs_path]");
ok($script_abs_path eq "$cwd/t/00.t");

my $script_filename = script_filename();
ok($script_filename,"script_filename is [$script_filename]");
ok($script_filename eq "00.t");


my $script_filename_only = script_filename_only();
ok($script_filename_only,"script_filename_only is [$script_filename_only]");
ok($script_filename_only eq "00");


my $script_ext = script_ext();
ok($script_ext,"script_ext is [$script_ext]");
ok($script_ext eq "t");


my $DOCUMENT_ROOT = DOCUMENT_ROOT();
ok($DOCUMENT_ROOT,"DOCUMENT_ROOT is [$DOCUMENT_ROOT]");

my $cgibin = abs_cgibin();
ok($cgibin, "ok, got cgibin [$cgibin]");
ok($cgibin eq "$cwd/t/cgi-bin");

# ok set a real docroot that will work..

$ENV{DOCUMENT_ROOT} = "$cwd";


my $script_rel_loc = script_rel_loc();
ok($script_rel_loc,"script_rel_loc is [$script_rel_loc]");

my $script_rel_path = script_rel_path();
ok($script_rel_path,"script_rel_path is [$script_rel_path]");


my $script_is_in_cgibin = script_is_in_cgibin();
ok( ! $script_is_in_cgibin );

my $script_is_in_DOCUMENT_ROOT = script_is_in_DOCUMENT_ROOT();
ok( $script_is_in_DOCUMENT_ROOT );


rmdir './t/public_html';
rmdir './t/cgi-bin';
