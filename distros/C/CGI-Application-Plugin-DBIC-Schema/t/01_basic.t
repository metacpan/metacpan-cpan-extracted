use Test::More;

#
# See t/sql for ddl to create test table.
#

if (!defined($ENV{DSN}) || !defined($ENV{DBUSER}) || !defined($ENV{DBPW})){
   plan skip_all => '$ENV{DSN}, $ENV{DBUSER}, $ENV{DBPW} must be set to run these tests.';
}else{
   plan tests => 9;
}

use lib './t';


use_ok('CGI::Application::Plugin::DBIC::Schema');
use_ok('DBICT'); 
use_ok('DBICT::Result::Test');       

use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
use TestApp;


my $t1_obj =
  TestApp->new(
	PARAMS=>{dsn=>$ENV{DSN},dbuser=>$ENV{DBUSER},dbpw=>$ENV{DBPW} },
	QUERY => CGI->new("rm=test_create") );
    
my $t1_output = $t1_obj->run();
like($t1_output, qr/successful test: default config/,'output successful for default config');

ok($t1_obj->schema()->isa('DBIx::Class::Schema'), 'schema isa DBIx::Class::Schema');


my $t2_obj =
  TestApp->new(
	PARAMS=>{dsn=>$ENV{DSN},dbuser=>$ENV{DBUSER},dbpw=>$ENV{DBPW} },
	QUERY => CGI->new("rm=test_create_named_config") );
    
my $t2_output = $t2_obj->run();
like($t2_output, qr/successful test: named config/,'output successful for named config');

ok($t2_obj->schema('test_config')->isa('DBIx::Class::Schema'), 'schema isa DBIx::Class::Schema');




my $t3_obj =
  TestApp->new(
	PARAMS=>{dsn=>$ENV{DSN},dbuser=>$ENV{DBUSER},dbpw=>$ENV{DBPW} },
	QUERY => CGI->new("rm=test_rs_shortform") );
    
my $t3_output = $t3_obj->run();
like($t3_output, qr/successful test: rs shortform default/,'output successful for rs with default');




my $t4_obj =
  TestApp->new(
	PARAMS=>{dsn=>$ENV{DSN},dbuser=>$ENV{DBUSER},dbpw=>$ENV{DBPW} },
	QUERY => CGI->new("rm=test_rs_shortform_named") );
    
my $t4_output = $t4_obj->run();
like($t4_output, qr/successful test: rs shortform named/,'output successful for rs with named');



done_testing(9);