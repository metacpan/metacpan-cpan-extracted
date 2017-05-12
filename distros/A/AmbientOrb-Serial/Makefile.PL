use strict;
use warnings;
use ExtUtils::MakeMaker;
use vars qw( $OS_win $serial_port_module $serial_port_module_version );

BEGIN {
    print "checking operating system to determine which serial port module to use...\n";
    $OS_win = ($^O eq "MSWin32") ? 1 : 0;
    if ($OS_win) {
	$serial_port_module = "Win32::SerialPort";
	$serial_port_module_version = "0.19";
	print "OS == MSWin32; module = $serial_port_module\n";
        }
	else
	{
	    $serial_port_module = "Device:SerialPort";
	    $serial_port_module_version = "0";
	    print "OS != MSWin32; module = $serial_port_module\n";
	}
} # End BEGIN


WriteMakefile(
    NAME                => 'AmbientOrb::Serial',
    AUTHOR              => 'Lyle Hayhurst <sozin@cpan.org>',
    VERSION_FROM        => 'lib/AmbientOrb/Serial.pm',
    ABSTRACT_FROM       => 'lib/AmbientOrb/Serial.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Carp' => 0,
	'Class::Accessor' => 0,
	$serial_port_module => $serial_port_module_version 
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AmbientOrb-Serial-*' },
);
