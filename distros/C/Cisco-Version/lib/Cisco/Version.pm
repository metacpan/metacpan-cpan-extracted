package Cisco::Version;

## ----------------------------------------------------------------------------------------------
## Cisco::Version
##
## Cisco "Show Version" parser.
## Try to parse some useful info from the "show version" output like memory, software, flash, etc.
##
## $Id: Version.pm 76 2007-07-23 21:05:02Z mwallraf $
## $Author: mwallraf $
## $Date: 2007-07-23 23:05:02 +0200 (Mon, 23 Jul 2007) $
##
## This program is free software; you can redistribute it and/or
## modify it under the same terms as Perl itself.
## ----------------------------------------------------------------------------------------------

use warnings;
use strict;
use Carp;
require 5.002;
#use Data::Dumper;

our $VERSION = '0.02';
my $AUTOLOAD;

my $DEBUG = 1;	# 0 = OFF,  1 = ERROR,   2 = WARN,   3 = INFO,   4 = DEBUG


my %CMD = (
		'bootstrap'			=>	'bootstrap',
		'sw_type'			=>	'sw-type',
		'sw_featureset'			=>	'sw-featureset',
		'sw_version'			=>	'sw-version',
		'bootldr_type'			=>	'bootldr-type',
		'bootldr_version'		=>	'bootldr-version',
		'bootldr_featureset'		=>	'bootldr-featureset',
		'hostname'			=>	'hostname',
		'uptime'			=>	'uptime',
		'reload_reason'			=>	'reload-reason',
		'reload_time'			=>	'reload-time',
		'image_file'			=>	'image-file',
		'chassis_type'			=>	'chassis-type',
		'memory'			=>	'memory',
		'confreg'			=>	'confreg',
		'pwdrecovery'			=>	'pwdrecovery',
		'flash_filesystems_sizes'	=>	'flash_filesystems_sizes',
		'flash_largest_size'		=>	'flash_largest_size',
	);



sub new()  {
	my ($this, $show_version) = @_;
	my  $class = ref($this) || $this;
	my  $self = {};	
	
	$self->{'show_version'} = $show_version;	# full output of "show version"
	
	$self->{'parsed'} = {};					#	this will contain hash of parsed parameters
	$self->{'not_found'} = '<NOT FOUND>';	#   this value is returned if a parameter was not found in show version

##      these are the possible values we can expect for now	
##
#	$self->{'parsed'}->{'bootstrap'};
#	$self->{'parsed'}->{'sw-type'};
#	$self->{'parsed'}->{'sw-featureset'};
#	$self->{'parsed'}->{'sw-version'};
#	$self->{'parsed'}->{'bootldr-type'};
#	$self->{'parsed'}->{'bootldr-version'};
#	$self->{'parsed'}->{'bootldr-featureset'};
#	$self->{'parsed'}->{'hostname'};
#	$self->{'parsed'}->{'uptime'};
#	$self->{'parsed'}->{'reload-reason'};
#	$self->{'parsed'}->{'reload-time'};
#	$self->{'parsed'}->{'image-file'};
#	$self->{'parsed'}->{'chassis-type'};
#	$self->{'parsed'}->{'memory'};
#	$self->{'parsed'}->{'confreg'};
#	$self->{'parsed'}->{'pwdrecovery'};
#	$self->{'parsed'}->{'flash_filesystems_sizes'} = [];
#	$self->{'parsed'}->{'flash_largest_size'};
	
	bless($self, $class);
	return($self);
}



# This routine parses "show version"
sub parse {
    my ($self, $sv) = @_;

	if (!$sv)  {
		($self->{'show_version'})?($sv = $self->{'show_version'}):(croak('Forgot to load "show config" output?'));
	}

    my @lines = split( /[\n\r]/, $sv);

    my ($line);

    foreach $line (@lines) {
    	next unless ($line);
		&_debug("new line found", $line);
    	if ($line =~ /^(?:Cisco|IOS).*Version ([^ ,]+)/)          {  $self->_process_software_version($line);  };
    	if ($line =~ /^ROM: /)                                    {  $self->_process_rom($line);  };
    	if ($line =~ /^BOOTLDR: /)                                {  $self->_process_bootloader($line);  };
    	if ($line =~ /uptime/i)                                   {  $self->_process_uptime($line);  };
    	if ($line =~ /System returned to ROM by /)                {  $self->_process_reload_reason($line); };
    	if ($line =~ /restarted/)                                 {  $self->_process_reload_time($line);  };
    	if ($line =~ /System image file is/)                      {  $self->_process_image_file($line);  };
    	if ($line =~ /^cisco.*[0-9]+K.*memory.$/i)                {  $self->_process_memory($line);  };
    	if ($line =~ /of physical memory \(DRAM\)$/)              {  $self->_process_additional_memory($line); };
    	if ($line =~ /^Configuration register is/i)               {  $self->_process_configuration_register($line);  };
    	if ($line =~ /password-recovery mechanism/)               {  $self->_process_password_recovery($line);  };
    	if ($line =~ /^[0-9]+K .*(?:PCMCIA |[fF]lash[^-]|ATA )/)  {  $self->_process_flash($line);  };
    }

}



sub AUTOLOAD()  {
	my ($self,@args) = @_;
	my $cmd = $Cisco::Version::AUTOLOAD;
	my $parm;
	
	$cmd =~ s/.*:://;
	$parm = $cmd;
	$parm =~ s/get_//;
	
	if ( ($cmd =~ /^get_/) && (defined($CMD{"$parm"})) )  {
		return $self->get_parameter($parm);
	}
	else {
		croak("function $cmd does not exist");
	}
}




sub get_parameter()  {
	my ($self, $parm) = @_;
	
	if (defined($self->{'parsed'}->{$CMD{"$parm"}}))  {
		return $self->{'parsed'}->{$CMD{"$parm"}};
	}
	else  {
		return  $self->{'not_found'};
	}
}


##
## returns a reference to the 'parsed' hash,
## this contains all the elements that were found in 'show version'
##
sub get_summary()  {
	my ($self) = shift;
	
	return $self->{'parsed'};
}


sub get_not_found_value()  {
	my ($self) = shift;
	
	return $self->{'not_found'};
}

sub set_not_found_value()  {
	my ($self, $value) = @_;
	
	$self->{'not_found'} = $value if (defined($value));
}


## look for bootstrap version
sub _process_rom()  {
	my ($self, $line) = @_;
	my $version;
	
	&_debug("parsing bootstrap", $line);
	
	if ( ($line !~ /(?:bootstrap|ROM: [0-9]+\.[0-9]+)/i) || ($line =~ /bootstrap program/i) )  {
		&_info("IGNORE - $line");
	}
	
	else  {
		$line =~ /(?:version ([^ ,]+)|ROM: ([0-9].*))/i;
		$version = $1 || $2;
		if ($version)  {
			$self->{'parsed'}->{'bootstrap'} = $version;
			
			&_debug("result = $version");
		}
		else  {
			&_warn("bootstrap version not found", $line);
		}
	}
}


sub _process_software_version()  {
	my ($self, $line) = @_;
	my ($sw_version, $sw_type, $sw_featureset);

	&_debug("parsing software version", $line);
	
	if ($line =~ /^(?:Cisco IOS Software|IOS \(tm\))[, ]+(.*) Software \((.*)\).*Version ([^ ,]+)/)  {
		$sw_type = $1;
		$sw_featureset = $2;
		$sw_version = $3;
		
		($sw_type)?($self->{'parsed'}->{'sw-type'} = $sw_type):(&_warn("software type not found", $line));
		($sw_featureset)?($self->{'parsed'}->{'sw-featureset'} = $sw_featureset):(&_warn("software featureset not found", $line));
		($sw_version)?($self->{'parsed'}->{'sw-version'} = $sw_version):(&_warn("software version not found", $line));
		
		&_debug("result = $sw_type");
		&_debug("result = $sw_featureset");
		&_debug("result = $sw_version");
	}
	else  {
		&_error("software version, type or featureset cannot be parsed", $line);
	}
}



sub _process_bootloader()  {
	my ($self, $line) = @_;
	my ($bl_version, $bl_type, $bl_featureset);

	&_debug("parsing bootloader", $line);

	if ($line =~ /^BOOTLDR: (.*) (?:Software|Boot Loader) \((.*)\).*Version ([^ ,]+)/)  {
		$bl_type = $1;
		$bl_featureset = $2;
		$bl_version = $3;
		
		($bl_type)?($self->{'parsed'}->{'bootldr-type'} = $bl_type):(&_warn("bootloader type not found", $line));
		($bl_featureset)?($self->{'parsed'}->{'bootldr-featureset'} = $bl_featureset):(&_warn("bootloader featureset not found", $line));
		($bl_version)?($self->{'parsed'}->{'bootldr-version'} = $bl_version):(&_warn("bootloader version not found", $line));

		&_debug("result = $bl_type");
		&_debug("result = $bl_featureset");
		&_debug("result = $bl_version");
	}
	else  {
		&_error("bootloader version, type or featureset cannot be parsed", $line);
	}
}



sub _process_uptime()  {
	my ($self, $line) = @_;
	my ($host, $uptime);

	&_debug("parsing uptime", $line);
	
	if ($line =~ /^ *(?:(.*) uptime is|Switch Uptime|Uptime for this control processor is)[^0-9]+(.*minutes*)/)  {
		if ($1 && $2)  {
			$host = $1;
			$self->{'parsed'}->{'hostname'} = $host;
		}
		$uptime = $2;
		($uptime)?($self->{'parsed'}->{'uptime'} = $uptime):(&_warn("uptime was not found", $line));

		&_debug("result = $uptime");
	}
	else  {
		&_error("uptime cannot be parsed", $line);
	}
}



sub _process_reload_reason()  {
	my ($self, $line) = @_;
	my $reason;

	&_debug("parsing reload reason", $line);
	
	if ($line =~ /System returned to ROM by (.*)/)  {
		$reason = $1;
		($reason)?($self->{'parsed'}->{'reload-reason'} = $reason):(&_warn("reload reason was not found", $line));

		&_debug("result = $reason");
	}
	else  {
		&_error("reload reason cannot be parsed", $line);
	}
}


sub _process_reload_time()  {
	my ($self, $line) = @_;
	my $time;

	&_debug("parsing reload time", $line);
	
	if ($line =~ /restarted.* at (.*)/)  {
		$time = $1;
		($time)?($self->{'parsed'}->{'reload-time'} = $time):(&_warn("reload time was not found", $line));

		&_debug("result = $time");
	}
	else  {
		&_error("reload time cannot be parsed", $line);
	}
}


sub _process_image_file()  {
	my ($self, $line) = @_;
	my $image;

	&_debug("parsing image file info", $line);
	
	if ($line =~ /System image file is \"(.*)\"/)  {
		$image = $1;
		($image)?($self->{'parsed'}->{'image-file'} = $image):(&_warn("image file was not found", $line));

		&_debug("result = $image");
	}
	else  {
		&_error("system image file cannot be parsed", $line);
	}
}


##
## tries to calculate the memory
## This is no exact science so be careful ...
##  Here's how we do it by default to get memory in MB : (main memory + shared IO memory) / 1024
## But there are a few exceptions.
## 
sub _process_memory()  {
	my ($self, $line) = @_;
	my ($memory, $chassis);
	my ($main_mem, $io_mem);

	&_debug("parsing memory", $line);
	
	if ($line =~ /cisco ([^ ]+).*with (?:([0-9]+)K |([0-9]+)K\/([0-9]+)K).*memory.*/i)  {
		$chassis = $1;
		
		if ($3 && $4)  {
			$main_mem = $3;
			$io_mem = $4;
			
			### some exceptions
			
			# ex. for WS-C3550
			if ($chassis =~ /^WS-C35/)  {
				$memory = $main_mem;
			}
			
			### default calculation
			else {
				$memory = $main_mem + $io_mem;
			}
			
		}
		elsif ($2)  {
			$memory = $2;
		}
		# save memory in megabytes (try to round to decimal number)
		$memory = int(($memory / 1024) + .5); 

		($chassis)?($self->{'parsed'}->{'chassis-type'} = $chassis):(&_warn("chassis type was not found", $line));
		($memory)?($self->{'parsed'}->{'memory'} = $memory):(&_warn("memory was not found", $line));

		&_debug("result = $chassis");
		&_debug("result = $memory");
	}
	else  {
		&_error("memory or chassis type cannot be parsed", $line);
	}
}



##
## some smaller routers have extra line with 'additional' DRAM
## this should be added to the RAM we already found
##
sub _process_additional_memory() {
	my ($self, $line) = @_;
	my ($memory);
	
	if ($line =~ /([0-9]+)M .* of physical memory \(DRAM\)$/)  {
		$memory = int($1 + .5);

		($memory)?($self->{'parsed'}->{'memory'} = $self->{'parsed'}->{'memory'} + $memory):(&_warn("additional DRAM was not found", $line));
	}
	else  {
		&_error("unable to parse additional DRAM", $line);
	}
}




sub _process_configuration_register()  {
	my ($self, $line) = @_;
	my ($confreg);

	&_debug("parsing configuration register", $line);
	
	if ($line =~ /^Configuration register is (.*)/)  {
		$confreg = $1;
		
		($confreg)?($self->{'parsed'}->{'confreg'} = $confreg):(&_warn("configuration register was not found", $line));

		&_debug("result = $confreg");
	}
	else  {
		&_error("unable to parse configuration register", $line);
	}
}


sub _process_password_recovery()  {
	my ($self, $line) = @_;
	my ($recovery);

	&_debug("parsing password recovery mechanism", $line);
	
	if ($line =~ /password-recovery mechanism is ([a-zA-Z]+)/)  {
		$recovery = $1;

		($recovery)?($self->{'parsed'}->{'pwdrecovery'} = $recovery):(&_warn("password recovery mechanism was not found", $line));

		&_debug("result = $recovery");
	}
	else  {
		&_error("unable to parse password recovery mechanism", $line);
	}
}



##
## Flash info is also difficult to parse as a chassis may have multiple
## filesystems. Also not all chassis types report flash info.
## Usually we're only interested in largest filesystem only so this is what 
## we try to parse :
##
## List of all flash filesystem sizes is kept as flash_filesystems_sizes
## Largest flash filesystem is reported as flash_largest_size
##
sub _process_flash()  {
	my ($self, $line) = @_;
	my ($flash);
	
	&_debug("parsing flash info", $line);
	
	if ($line =~ /^([0-9]+)K .*(?:PCMCIA |[fF]lash[^-]|ATA )/)  {
		$flash = int(($1 / 1024) + .5);
		
		if ($flash)  {
			if (!defined($self->{'parsed'}->{'flash_filesystems_sizes'}))	{
				$self->{'parsed'}->{'flash_filesystems_sizes'} = [];
			}
			push (@{$self->{'parsed'}->{'flash_filesystems_sizes'}}, $flash);

			if (!defined($self->{'parsed'}->{'flash_largest_size'}) || ($self->{'parsed'}->{'flash_largest_size'} < $flash))  {
				$self->{'parsed'}->{'flash_largest_size'} = $flash;
			}

			&_debug("result = $flash");
		}
		else  {
			&_warn("flash was not found", $line);
		}
	}
	else  {
		&_error("unable to parse flash", $line);
	}
}



##
## carp a log message, regardless of $DEBUG value
##
sub _log()  {
	my ($msg, $line) = @_;
	
	if ($line)  {
		$msg = $msg . " [$line]";
	}
	
	&carp($msg);
}


##
## carp a log message, only if $DEBUG >= 1
##
sub _error()  {
	my ($msg, $line) = @_;
	
	if ($DEBUG >= 1)  {
		&_log("ERROR: ".$msg, $line);
	}
}


##
## carp a log message, only if $DEBUG >= 2
##
sub _warn()  {
	my ($msg, $line) = @_;
	
	if ($DEBUG >= 2)  {
		&_log("WARN: ".$msg, $line);
	}
}


##
## carp a log message, only if $DEBUG >= 3
##
sub _info()  {
	my ($msg, $line) = @_;
	
	if ($DEBUG >= 3)  {
		&_log("INFO: ".$msg, $line);
	}
}


##
## carp a log message, only if $DEBUG >= 3
##
sub _debug()  {
	my ($msg, $line) = @_;
	
	if ($DEBUG >= 4)  {
		&_log("DEBUG: ".$msg, $line);
	}
}

1; # End of Cisco::Version


__END__

=head1 NAME

Cisco::Version - Cisco 'show version' parser

=head1 VERSION

version 0.02

=head1 SYNOPSIS

	use Cisco::Version;

	my $cv = new Cisco::Version($show_version);
	$cv->parse();
	
	print $cv->get_memory();
	print $cv->get_software_version();
	print $cv->get_chassis_type();
	print $cv->get_uptime();
	
	use Data::Dumper;
	print &Dumper($cv->get_summary());
	
	print $cv->get_not_found_value();
	$cv->set_not_found_value("<NOT FOUND>");
	etc.
	
=head1 DESCRIPTION

This module is a parser for Cisco 'show version'.

We try to parse as much useful information as possible from the 'show version' output :
software version, chassis type, memory information, flash information, uptime etc.

The 'show version' output may differ for each chassis type or software version so the parsed information
may look different as well.

=head1 PROCEDURES

=over 4

=item new() - constructor

This is the constructor.

	my $cv = new Cisco::Version($show_version)
	
This creates a new Cisco::Version object.
One parameter is required :

	$show_version = string that contains complete output of 'show version'

=item parse()

This function actually takes care of parsing the 'show version' information. 

	$cv->parse();

The following parameters are currently being parsed, depending on the chassis or software
it may actually find a value or not. 

	- software version information
	- bootstrap information
	- bootloader information
	- uptime
	- reload reason
	- reload time
	- software image file
	- DRAM memory information
	- flash information
	- configuration registry
	- password recovery mechanism

=item get_bootstrap()

Get bootstrap information.

	$cv->get_bootstrap();

example output = '12.4(1r)'

=item get_bootldr_type()

Get bootloader type information.

	$cv->get_bootldr_type();

=item get_bootldr_version()

Get bootloader version information.

	$cv->get_bootldr_version();

=item get_bootldr_featureset()

Get bootloader featureset information.

	$cv->get_bootldr_featureset();

=item get_sw_type()

Get software type information.

	$cv->get_sw_type();

example output = '2800'

=item get_sw_version()

Get software version information.

	$cv->get_sw_version();

example output = '12.4(8)'

=item get_sw_featureset()

Get software featureset information.

	$cv->get_sw_featureset();

example output = 'C2800NM-ADVIPSERVICESK9-M'

=item get_hostname()

Get hostname information. This is only found if the 'uptime' info exists and only for certain chassis types.

	$cv->get_hostname();

example output = 'ROUTERA'

=item get_uptime()

Get uptime information.

	$cv->get_uptime();

example output = '26 weeks, 5 days, 22 hours, 25 minutes'

=item get_reload_reason()

Get the reason for last reload.

	$cv->get_reload_reason();

example output = 'power-on'

=item get_reload_time()

Get the time and date of last reload.

	$cv->get_reload_time();

example output = '11:40:19 GMT+2 Sat Jan 13 2007'

=item get_image_file()

Get software image file information.

	$cv->get_image_file();

example output = 'flash:c2800nm-advipservicesk9-mz.124-8.bin'

=item get_chassis_type()

Get additional chassis type information.

	$cv->get_chassis_type();

example output = '2821'

=item get_memory()

Get DRAM memory information. Depending on the chassis type and IOS version this may be correct or not.
By default this is the sum of main memory and shared IO memory. But again, it depends a little bit on chassis type.

This value is in megabytes.

	$cv->get_memory();

example output = '256'

=item get_confreg()

Get the value of the config register.

	$cv->get_confreg();

example output = '0x2102'

=item get_pwdrecovery()

Get password recovery mechanism information if available.

	$cv->get_pwdrecovery();

example output = 'enabled'

=item get_flash_filesystems_sizes()

Get a list of the sizes of each filesystem found. Usually this is the flash filesystem, some chassis also have
additional filesystems like PCMCIA or ATA disk.
At this moment we're only interested in the size, maybe later also the type of filesystem.

This value is in megabytes.

	$cv->get_flash_filesystems_sizes();

example output = [ '32' , '64' ]

=item get_flash_largest_size()

This displays the value of the largest filesystem that can be used as flash.

This value is in megabytes.

	$cv->get_flash_largest_size();

example output = '64'

=item get_summary()

This returns a reference to the hash that contains all parsed elements. This can be useful to find out
which parameters were found for a specific device.

	$ref = $cv->get_summary()
	print &Dumper($ref);

=item get_not_found_value()

It may be useful to know if a certain parameter was not found in the show version. Instead of returning an empty value
a special "not found value" is used.

By default this value = <NOT FOUND>

	print $cv->get_not_found_value()

=item set_not_found_value()

The special "not found value" can be changed to anything you want.

	$cv->set_not_found_value("__not_found__");

=back

=head1 SUPPORTED DEVICES

Cisco::Version has been verified on the combination of following chassis types and OS versions. 
For these combinations the output is what was expected. 

But hey, my expectations may be different than yours :-)

	chassis	software	type
	1711	12.3(11)T2	C1700
	1720	12.3(6c)	C1700
	1721	12.2(15)T12	C1700
	1721	12.2(15)T14	C1700
	1721	12.2(15)T17	C1700
	1721	12.2(15)T5	C1700
	1721	12.3(12e)	C1700
	1721	12.3(1a)	C1700
	1721	12.3(2)XE	C1700
	1812	12.4(6)T5	C181X
	1841	12.4(12a)	1841
	1841	12.4(3f)	1841
	1841	12.4(8)	1841
	1841	12.4(8a)	1841
	1841	12.4(8b)	1841
	1841	12.4(8c)	1841
	2500	12.0(22)	2500
	2610	12.0(21a)	C2600
	2610	12.1(13)	C2600
	2610	12.2(24a)	C2600
	2610	12.2(27)	C2600
	2610	12.2(29)	C2600
	2610	12.2(37)	C2600
	2610	12.3(12b)	C2600
	2610	12.3(12e)	C2600
	2611	12.2(27)	C2600
	2612	12.1(13)	C2600
	2612	12.2(29a)	C2600
	2612	12.3(12e)	C2600
	2613	12.2(24a)	C2600
	2613	12.3(12e)	C2600
	2620	12.1(13)	C2600
	2620	12.1(5)T10	C2600
	2620	12.1(5)T12	C2600
	2620	12.3(12e)	C2600
	2651	12.1(5)T12	C2600
	2651	12.2(15)T17	C2600
	2651	12.3(12e)	C2600
	2691	12.3(10)	2600
	2691	12.3(10a)	2600
	2691	12.3(10c)	2600
	2691	12.3(12d)	2600
	2691	12.3(12e)	2600
	2691	12.4(8)	2600
	2801	12.4(3f)	2801
	2811	12.4(3d)	2800
	2811	12.4(3d)	2800
	2821	12.4(12)	2800
	2821	12.4(8)	2800
	2821	12.4(8a)	2800
	2821	12.4(8c)	2800
	2821	12.4(9)T1	2800
	3620	12.1(5)T12	3600
	3620	12.2(21a)	3600
	3620	12.2(24a)	3600
	3620	12.2(27)	3600
	3620	12.2(29a)	3600
	3620	12.2(37)	3600
	3640	11.2(15a)P	3600
	3640	12.1(21)	3600
	3640	12.1(5)T12	3600
	3640	12.2(13)	3600
	3640	12.2(17a)	3600
	3640	12.2(24a)	3600
	3640	12.2(27)	3600
	3640	12.3(12e)	3600
	3725	12.2(15)T12	3700
	3725	12.3(10a)	3700
	3725	12.3(10c)	3700
	3725	12.3(12b)	3700
	3745	12.3(12b)	3700
	3825	12.4(8a)	3800
	3825	12.4(8b)	3800
	7206	12.1(20020531:181751)	7200
	2610XM	12.2(12a)	C2600
	2610XM	12.3(10d)	C2600
	2610XM	12.3(12e)	C2600
	2611XM	12.3(12e)	C2600
	2620XM	12.3(12e)	C2600
	2621XM	12.2(24a)	C2600
	2621XM	12.3(12e)	C2600
	2621XM	12.3(12e)	C2600
	2651XM	12.2(29a)	C2600
	2651XM	12.2(37)	C2600
	2651XM	12.3(10)	C2600
	2651XM	12.3(10d)	C2600
	2651XM	12.3(10e)	C2600
	2651XM	12.3(12)	C2600
	2651XM	12.3(12b)	C2600
	2651XM	12.3(13)	C2600
	2651XM	12.3(16)	C2600
	2651XM	12.3(4)T3	C2600
	2651XM	12.4(8c)	C2600
	3640-A	12.2(11)T6	3600
	3660-telco	12.2(29)	3600
	7204VXR	12.2(29a)	7200
	7204VXR	12.3(12e)	7200
	7206VXR	12.2(17a)	7200
	7206VXR	12.2(29)	7200
	7206VXR	12.3(12e)	7200
	c3660	12.1(5)T12	3600
	c3660	12.1(5)T12	3600
	C803	12.2(13)	C800
	Cat2948G	12.0(14)W5(20)	L3 Switch/Router
	Cat4232L3	12.0(18)W5(22b)	L3 Switch/Router
	Cat4232L3	12.0(25)W5(27)	L3 Switch/Router
	Cat6k-MSFC	12.1(8b)E9	MSFC
	Cat6k-MSFC2	12.1(11b)E	MSFC2
	Cat6k-MSFC2	12.1(12c)E2	MSFC2
	Cat6k-MSFC2	12.1(13)E2	MSFC2
	Cat6k-MSFC2	12.1(8b)E9	MSFC2
	MSFC2	12.1(20)E	MSFC2
	MSFC2	12.1(23)E3	MSFC2
	MSFC2	12.1(26)E5	MSFC2
	MSFC2A	12.2(17d)SXB7	MSFC2A
	MSFC3	12.2(17d)SXB10	MSFC3
	MSFC3	12.2(17d)SXB3	MSFC3
	MSFC3	12.2(17d)SXB9	MSFC3
	RSP8	12.2(29)	RSP
	WS-C3550-12G	12.1(13)EA1a	C3550
	WS-C3550-12G	12.1(20)EA2	C3550
	WS-C3550-12G	12.1(22)EA1	C3550
	WS-C3550-12G	12.1(22)EA1a	C3550
	WS-C3550-12G	12.1(22)EA2	C3550
	WS-C3550-12G	12.1(9)EA1c	C3550
	WS-C3550-24	12.1(13)EA1a	C3550
	WS-C3550-24	12.1(14)EA1a	C3550
	WS-C3550-48	12.1(11)EA1a	C3550
	WS-C3550-48	12.1(13)EA1a	C3550
	WS-C3550-48	12.1(22)EA4a	C3550
	WS-C3750-24TS	12.2(25)SEB2	C3750
	WS-C3750-24TS	12.2(25)SEB4	C3750
	WS-C3750-48TS	12.2(25)SEB4	C3750
	WS-C3750G-12S	12.2(20)SE4	C3750
	WS-C3750G-12S	12.2(25)SEB1	C3750
	WS-C3750G-12S	12.2(25)SEB2	C3750
	WS-C3750G-12S	12.2(25)SEE2	C3750
	WS-C3750G-24PS	12.2(25)SEB4	C3750
	WS-C3750G-24TS-1U	12.2(25)SEB4	C3750
	WS-C3750G-48PS	12.2(25)SEE2	C3750
	WS-C4006	12.2(20)EWA	Catalyst 4000 L3 Switch
	WS-C4006	12.2(25)EWA4	Catalyst 4000 L3 Switch
	WS-C4503	12.2(25)EWA6	Catalyst 4000 L3 Switch
	WS-C4506	12.1(23)E	Catalyst 4000 L3 Switch
	WS-C4506	12.2(20)EWA	Catalyst 4000 L3 Switch
	WS-C4506	12.2(25)EWA4	Catalyst 4000 L3 Switch
	WS-C4506	12.2(25)EWA6	Catalyst 4000 L3 Switch
	WS-C4507R	12.2(25)EWA5	Catalyst 4000 L3 Switch
	WS-C6506	12.2(17d)SXB	s72033_rp
	WS-C6506-E	12.2(18)SXF4	s72033_rp
	WS-C6506-E	12.2(18)SXF7	s3223_rp
	WS-C6509	12.2(18)SXF6	s72033_rp
	WS-C6509-E	12.2(18)SXF4	s72033_rp
	WS-C6509-E	12.2(18)SXF6	s72033_rp

=head1 EXAMPLE

Here is a short example that can be found in the test directory as well.

	use strict;
	use Cisco::Version;
	use Data::Dumper;

	## load the output of 'show version' in a string
	my $show_version = &sample_show_version();

	## crate a new Cisco::Version object 
	my $sv = Cisco::Version->new($show_version);

	## parse the output
	$sv->parse();

	## and get some results
	# print the amount of RAM found
	print "total DRAM memory = ", $sv->get_memory(), "\n";
	# pwdrecovery was not found in this 'show version', what now ?
	print "pwdrecovery = ", $sv->get_pwdrecovery(), "\n";
	# print the current 'not found value'
	print "'not found value' = ", $sv->get_not_found_value(), "\n";
	# let's change this value
	$sv->set_not_found_value("-----");
	# and see what happens
	print "pwdrecovery = ", $sv->get_pwdrecovery(), "\n";
	# and print it out once more
	print "'not found value' = ", $sv->get_not_found_value(), "\n";

	## let's print a dump of all the parameters we found
	print &Dumper($sv->get_summary());


	##
	## this is an example output of a Cisco router 'show version'
	## put your own version to test
	##
	sub sample_show_version()  {
	return <<END

	Cisco IOS Software, 2800 Software (C2800NM-ADVIPSERVICESK9-M), Version 12.4(8), RELEASE SOFTWARE (fc1)
	Technical Support: http://www.cisco.com/techsupport
	Copyright (c) 1986-2006 by Cisco Systems, Inc.
	Compiled Mon 15-May-06 14:54 by prod_rel_team

	ROM: System Bootstrap, Version 12.4(1r) [hqluong 1r], RELEASE SOFTWARE (fc1)

	ROUTERA uptime is 26 weeks, 5 days, 22 hours, 25 minutes
	System returned to ROM by power-on
	System restarted at 11:40:19 GMT+2 Sat Jan 13 2007
	System image file is "flash:c2800nm-advipservicesk9-mz.124-8.bin"


	This product contains cryptographic features and is subject to United
	States and local country laws governing import, export, transfer and
	use. Delivery of Cisco cryptographic products does not imply
	third-party authority to import, export, distribute or use encryption.
	Importers, exporters, distributors and users are responsible for
	compliance with U.S. and local country laws. By using this product you
	agree to comply with applicable laws and regulations. If you are unable
	to comply with U.S. and local laws, return this product immediately.

	A summary of U.S. laws governing Cisco cryptographic products may be found at:
	http://www.cisco.com/wwl/export/crypto/tool/stqrg.html

	If you require further assistance please contact us by sending email to
	export\@cisco.com.

	Cisco 2821 (revision 53.51) with 249856K/12288K bytes of memory.
	Processor board ID FCZ102772EM
	2 Gigabit Ethernet interfaces
	1 Serial interface
	1 Channelized E1/PRI port
	1 Virtual Private Network (VPN) Module
	DRAM configuration is 64 bits wide with parity enabled.
	239K bytes of non-volatile configuration memory.
	62720K bytes of ATA CompactFlash (Read/Write)

	Configuration register is 0x2102

	END
	;
	}

=head1 DEBUGGING

If you're having problems parsing show version or you don't understand why you get 
wrong data - or no data at all - then try to set $DEBUG to a higher value
on top of Version.pm.

$DEBUG = 0 (off),  1 (ERROR),  2 (WARN),  3 (INFO),  4 (DEBUG)

=head1 TODO

Probably add more chassis types like firewalls, loadbalancers etc.

Let me know what else.

=head1 CAVEATS

The output of 'show version' is very much dependant of software versions and chassis types. Don't be 
surprised if the output is not the same for each chassis !

Calculations like memory or flash sizes may be incorrect as well. Again, don't be surprised if the figures
are not what you would expect.

Make sure the show version output is used exactly as the Cisco devices returns it to the screen. Don't add leading blanks
or tabs.

=head1 AUTHOR

Maarten Wallraf E<lt>perl@2nms.comE<gt>

=cut
    