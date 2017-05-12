use Test::More qw/no_plan/;
BEGIN { use_ok('CGI::Application::Plugin::DBH') };

use lib './t';
use strict;


#### Test DBI environment variables


$ENV{CGI_APP_RETURN_ONLY} = 1;
$ENV{DBI_DSN}='dbi:Mock:';
$ENV{DBI_USER}='';
$ENV{DBI_PASS}='';

use TestAppAutoConfig;

my $t1_obj = TestAppAutoConfig->new();
my $t1_output = $t1_obj->run();

use UNIVERSAL;
ok($t1_obj->dbh->isa('DBI::db'), 'dbh() method returns DBI handle');

eval{ $t1_obj->dbh('blah') };
ok ($@ =~ /^must call dbh_config/ , 'only default handle is configured');

ok(
	$t1_obj->dbh(
		$t1_obj->dbh_default_name())
		->isa('DBI::db'), 'default handle is configured');


#### Test CGI::App instance parameters (default handle)

delete $ENV{DBI_DSN};

$t1_obj = TestAppAutoConfig->new();
$t1_obj->param('::Plugin::DBH::dbh_config' => [ 'dbi:Mock:', '', '', 
	{AutoCommit => 1, RaiseError => 1} ] );

$t1_output = $t1_obj->run();

ok($t1_obj->dbh->isa('DBI::db'), 'dbh() method returns DBI handle');

eval{ $t1_obj->dbh('blah') };
ok ($@ =~ /^must call dbh_config/ , 'only default handle is configured');

ok(
	$t1_obj->dbh(
		$t1_obj->dbh_default_name())
		->isa('DBI::db'), 'default handle is configured');
		
#### Test CGI::App instance parameters (two handles)

$t1_obj = TestAppAutoConfig->new();
$t1_obj->param('::Plugin::DBH::dbh_config' => 
 { handle1 => [ 'dbi:Mock:', '', '', {AutoCommit => 1, RaiseError => 1} ],
 	handle2 => [ 'dbi:Mock:', '', '', {AutoCommit => 1, RaiseError => 1} ]}
 	);

$t1_obj->dbh_default_name('handle1');

$t1_output = $t1_obj->run();

ok($t1_obj->dbh->isa('DBI::db'), 'dbh() method returns DBI handle');

eval{ $t1_obj->dbh('blah') };
ok ($@ =~ /^must call dbh_config/ , 'only handle1 and handle2 are configured');

ok(
	$t1_obj->dbh('handle1')
		->isa('DBI::db'), 'handle1 is configured');
		
ok(
	$t1_obj->dbh('handle2')
		->isa('DBI::db'), 'handle2 is configured');
		
		
		