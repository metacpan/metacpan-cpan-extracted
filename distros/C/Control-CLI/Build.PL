#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;

# Scan for TESTPORT argument
my $dpfile = "t/DefaultPort.pm";
my (@passargs, $serialPort);
if (@ARGV) {
	foreach my $arg (@ARGV) {
		my ($key,$value)=split /=/, $arg, 2;
		if ($key eq "TESTPORT") {
			$serialPort = $value;
		}
		else {
			push(@passargs,$arg);
		}
	}
}
@ARGV=@passargs;

if ($serialPort) {
	open (my $default, '>', $dpfile) or die "Can't create $dpfile: $!\n";
	print $default <<EOF;

# Created by Build.PL
package DefaultPort;
\$Serial_Test_Port = "$serialPort";
EOF

	close $default;
}
else {
	unlink $dpfile if -e $dpfile;
	print "\nTo enable serial port tests, use:\n";
	print "\tperl Build.PL TESTPORT=<DEVICE>\n";
	print "where <DEVICE> is the serial port to test with\n\n";
}


my $build = Module::Build->new(
		module_name => 'Control::CLI',
		license  => 'perl',
		requires => {
			'Exporter'		=> 0,
			'Term::ReadKey' 	=> 0,
			'Time::HiRes'		=> 0,
			'IO::Handle'		=> 0,
			'IO::Socket::INET'	=> 0,
			perl			=> '5.6.0',
		},
		build_requires => {
			'Net::Telnet'		=> 0,
			'IO::Interactive'	=> 0,
		},
		configure_requires => { 'Module::Build' => 0.36 },
		meta_merge => {
			resources => {
				repository => 'https://github.com/lgastevens/Control-CLI',
				bugtracker => 'https://github.com/lgastevens/Control-CLI/issues',
#				bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Control-CLI',
			}
		},
	);
$build->create_build_script;
