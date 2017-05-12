#!/usr/bin/perl

use Modern::Perl;
use warnings FATAL => 'all';
use Test::More;
use Backup::Duplicity::YADW;
use File::RandomGenerator;
use File::Path;
use Cwd;
use File::Copy;
use File::Basename;
use File::Which;

###### CONSTANTS ######

use constant TESTDIR => '/tmp/yadwtest';

###### GLOBAL VARS ######

use vars qw();

###### MAIN ######

system( 'rm -rf ' . TESTDIR );

if ( !which('duplicity') ) {
	plan skip_all => 'unable to find duplicity on PATH';
}

generate_test_dir();

my $pidfile = get_pidfile();
ok( !-e $pidfile,  );

my @cmd = qw( perl -I./lib ./bin/yadw full -c ./t/etc/test.conf);
system @cmd;
my $exit = $? >> 8;
ok !$exit;
ok( !-e $pidfile );

@cmd = qw( perl -I./lib ./bin/yadw inc -c ./t/etc/test.conf);
system @cmd;
$exit = $? >> 8;
ok !$exit;
ok( !-e $pidfile );

@cmd = qw( perl -I./lib ./bin/yadw verify -c ./t/etc/test.conf);
system @cmd;
$exit = $? >> 8;
ok !$exit;
ok( !-e $pidfile );

@cmd = qw( perl -I./lib ./bin/yadw expire -c ./t/etc/test.conf);
system @cmd;
$exit = $? >> 8;
ok !$exit;
ok( !-e $pidfile );

done_testing();

###### END MAIN ######

sub get_pidfile {

	my $yadw = get_new_obj();
	ok $yadw;
	my $pidfile = $yadw->_conf->get('pidfile');
	ok( -e $pidfile );
	
	return $pidfile;
}

sub get_new_obj {
	my $yadw = Backup::Duplicity::YADW->new(
		conf_dir   => './t/etc',
		conf_file  => 'test.conf',
		dry_run    => 0,
		use_syslog => 1,
		verbose    => 0
	);

	return $yadw;
}

END {

	unless ( $ENV{DEBUG} ) {
		system( 'rm -rf ' . TESTDIR );
	}
}

sub generate_test_dir {
	my $frg = File::RandomGenerator->new(
		root_dir => TESTDIR . "/testdata",
		unlink   => 0,
		depth    => 2
	);

	$frg->generate;
}
