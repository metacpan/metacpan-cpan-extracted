#!/usr/bin/perl

package MyObj {

	use Moose;

	  has foo => ( is => 'rw' );
	  has bar => ( is => 'rw' );

	  no Moose;

};

use Bread::Board;
use Test::More qw(no_plan);

my $log_conf = qq/ 
log4perl.rootLogger=INFO, main

log4perl.appender.main=Log::Log4perl::Appender::Screen
log4perl.appender.main.layout   = Log::Log4perl::Layout::SimpleLayout
/;

my $tmp            = $ENV{TMP} || '/tmp';
my $obj_store_file = "${tmp}/.app-services-obj-store-$$.db";

my $cntnr = container '01_basic_t' => as {

	service 'log_conf'       => \$log_conf;
	service 'obj_store_file' => $obj_store_file;
	service 'kdb_dsn' => "dbi:SQLite:dbname=$obj_store_file";

	service 'logger_svc' => (
		class        => 'App::Services::Logger::Service',
		lifecycle    => 'Singleton',
		dependencies => { log_conf => 'log_conf' },
	);

	service 'obj_store_svc' => (
		class        => 'App::Services::ObjStore::Service',
		dependencies => {
			logger_svc     => depends_on('logger_svc'),
			obj_store_file => 'obj_store_file',
			kbs_dsb        => 'kdb_dsn',
		},
	);

};

my $lsvc = $cntnr->resolve( service => 'logger_svc' );

ok( $lsvc, "Create logger service" );

my $svc = $cntnr->resolve( service => 'obj_store_svc' );

ok( $svc, "Create object store service" );

$svc->delete_object_store;
$svc->init_object_store;

ok( $svc->kdb, "initialized obj store" );

my $obj1 = MyObj->new( foo => 1, bar => 2 );

ok( $obj1, "obj created" );

my $oid = $svc->add_object($obj1);
ok( $oid, "inserted obj, got id" );

my $obj2 = $svc->get_object($oid);
ok( ( ref($obj2) eq 'MyObj' ), 'got object by id' );

ok( $obj2->foo == 1, 'foo expected value' );
ok( $obj2->bar == 2, 'bar expected value' );

my (@oids) = $svc->all_objects;

ok( @oids, "Got some objects from all_objects" );
ok( scalar(@oids) == 1, "Got expected \# of objects" );

my $obj3   = shift @oids;
my $r_obj3 = ref($obj3);

ok( $r_obj3 eq 'MyObj', "object is correct type: $r_obj3" );

ok( $obj3->foo == 1, 'foo expected value' );
ok( $obj3->bar == 2, 'bar expected value' );

