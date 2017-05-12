#!/usr/bin/perl

package MyObj {

	use Moose;

	  has foo => ( is => 'rw' );
	  has bar => ( is => 'rw' );

	  no Moose;

};

use Bread::Board;
use Test::More qw(no_plan);

use App::Services::ObjStore::Container;

my $log_conf = qq/ 
log4perl.rootLogger=INFO, stdout
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=%-6p| %m%n

/;

my $cntnr = App::Services::ObjStore::Container->new( log_conf => \$log_conf, );

my $svc = $cntnr->resolve( service => 'obj_store_svc' );

ok( $svc, "Create object store service" );

$svc->delete_object_store;
sleep 1;
$svc->init_object_store;

ok( $svc->kdb, "initialized obj store" );

my $pid;
my @child_pids;

$svc->log->info("BEGIN");

foreach my $i ( 1 .. 10 ) {

	$pid = fork;

	unless ($pid) {
		my $obj = MyObj->new( foo => $i, bar => $i + $i );
		$svc->label("Child $i ($$)");

		my $oid = $svc->add_object($obj);

		print "Child $i ($$): inserted obj\n";

		exit 0;

	}
	else {
		push @child_pids, $pid;
	}

}

use POSIX ":sys_wait_h";

my $kid;
$svc->log->info("$$: Waiting for children");

foreach my $pid (@child_pids) {
	waitpid( $pid, 0 );
}

$svc->log->info("Children all reaped");

my $i = 1;
my @obj_vals;

foreach my $obj ( $svc->all_objects ) {

	ok( ( ref($obj) eq 'MyObj' ), "parent ($$): Got object ($i)" );

	push @obj_vals, $obj->foo;
	$svc->log->info( "$$: Found obj with foo: " . $obj->foo );

	$i++;
}

