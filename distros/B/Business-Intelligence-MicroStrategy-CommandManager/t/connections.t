use strict;
use warnings;

use Test::More;

my $tests;

BEGIN {
    $tests = 14;
    plan tests => $tests;
    chdir 't' if -d 't';
    use lib '../lib';
}

BEGIN { use_ok('Business::Intelligence::MicroStrategy::CommandManager'); }

ok(
    my $foo = Business::Intelligence::MicroStrategy::CommandManager->new(),
    'can create object MicroStrategy::Cmdmgr'
);

$foo->set_cmdmgr_exe("path_to_executable");
is( $foo->get_cmdmgr_exe, 'path_to_executable',"get_cmdmgr_exe");

$foo->set_connect(
	    PROJECTSOURCENAME => "project_source_name", 
	    USERNAME          => "userid", 
	    PASSWORD          => "password"
);
	

my ($prj, $u, $pw) = $foo->get_connect;	
is($prj, '-n project_source_name', "get_connect1");
is($u, '-u userid', "get_connect2");
is($pw, '-p password', "get_connect3");

$foo->set_project_source_name("mt");
is($foo->get_project_source_name, '-n mt',"get_project_source_name");

$foo->set_user_name("joe");
is($foo->get_user_name, '-u joe', "get_user_name");

$foo->set_password("foobar");
is($foo->get_password, '-p foobar',"get_password");

$foo->set_inputfile("IN");
is($foo->get_inputfile,'-f IN',"get_inputfile");

$foo->set_outputfile("OUT");
is($foo->get_outputfile, '-o OUT',"get_outputfile");

$foo->set_resultsfile(
	    RESULTSFILE => "results file",
	    FAILFILE    => "fail file",
	    SUCCESSFILE => "success file"
);

my($r, $f, $s) = $foo->get_resultsfile;
is($r, "-or results file", "results file");
is($f, "-of fail file", "fail file");
is($s, "-os success file", "success file");

$foo->set_instructions;
$foo->set_header;
$foo->set_showoutput;
$foo->set_stoponerror;
$foo->set_skipsyntaxcheck;
$foo->set_error;
$foo->set_break;
