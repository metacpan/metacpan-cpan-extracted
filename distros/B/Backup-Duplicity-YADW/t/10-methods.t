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
use Data::Dumper;
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

my $y = method_test_backup();
method_test_verify($y);
method_test_restore($y);
method_test_expire($y);
method_test_status($y);
verify_pidfile_check();
$y = undef;
method_test_backup_bad();

done_testing();

###### END MAIN ######

END {

	unless ( $ENV{DEBUG} ) {
		system( 'rm -rf ' . TESTDIR );
	}
}

sub method_test_status {
	my $y = shift;

	ok( $y->status );
}

sub method_test_restore {
	my $y = shift;

	my $file = find_rand_file();
	unlink $file or die "failed to unlink $file: $!";

	ok( $y->restore( location => $file ) );
	ok( -e $file );
}

sub find_rand_file {
	my @cmd = ( 'find', TESTDIR . '/testdata', '-type', 'f' );

	my @output = `@cmd`;

	my $i = int( rand(@output) );

	my $file = $output[$i];
	chomp $file;

	return $file;
}

sub method_test_expire {
	my $y = shift;

	ok( $y->expire );
}

sub method_test_backup {

	my $dir = generate_test_dir();

	my $y =
		Backup::Duplicity::YADW->new( conf_dir  => "t/etc",
									  conf_file => "test.conf",
									  verbose   => $ENV{VERBOSE}
		);

	eval { $y->backup('bogus') };
	ok($@);
	ok( $y->backup('full') );
	ok( $y->backup('inc') );

	return $y;
}

sub verify_pidfile_check {
	eval {
		my $y =
			Backup::Duplicity::YADW->new( conf_dir  => "t/etc",
										  conf_file => "test_bad.conf",
										  verbose   => $ENV{VERBOSE}
			);
	};
	ok($@);
	ok( $Backup::Duplicity::YADW::ErrCode
		== Backup::Duplicity::YADW::PID_EXISTS() );
}

sub method_test_backup_bad {

	my $y =
		Backup::Duplicity::YADW->new( conf_dir  => "t/etc",
									  conf_file => "test_bad.conf",
									  verbose   => $ENV{VERBOSE}
		);

	eval { $y->backup('full') };
	ok($@);
}

sub method_test_verify {
	my $y = shift;
	ok( $y->verify );
}

sub replace_src_dir {

	my $conf_orig   = shift;
	my $new_src_dir = shift;

	my $tmp = $conf_orig . $$;

	open my $read,  $conf_orig or die;
	open my $write, ">$tmp"    or die;

	while ( my $l = <$read> ) {
		if ( $l =~ /SourceDir/ ) {
			$l = "SourceDir $new_src_dir\n";
		}

		print $write $l;
	}

	close $read;
	close $write;

	move( $tmp, $conf_orig ) or die $!;
}

sub generate_test_dir {
	my $frg =
		File::RandomGenerator->new( root_dir => TESTDIR . "/testdata",
									unlink   => 0,
									depth    => 2
		);
	return $frg->generate;
}
