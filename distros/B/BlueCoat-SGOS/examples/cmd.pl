#!/usr/bin/perl
#
#
#
use strict;
use lib qw#../lib #;
use BlueCoat::SGOS 1.00;
use Getopt::Long;
use Data::Dumper;

my %c = (
	'appliancehost'     => '',
	'applianceport'     => 8082,
	'applianceusername' => 'admin',
	'appliancepassword' => '',
	'command'			=>	"exit\nsho ver",  # remember, we start out in config mode
);

my $d = GetOptions(
	'appliancehost=s'     => \$c{'appliancehost'},
	'applianceport=i'     => \$c{'applianceport'},
	'applianceusername=s' => \$c{'applianceusername'},
	'appliancepassword=s' => \$c{'appliancepassword'},
	'command=s' => \$c{'command'}
);

my $bc = BlueCoat::SGOS->new(
	'appliancehost'     => $c{'appliancehost'},
	'applianceport'     => $c{'applianceport'},
	'applianceuser'     => $c{'applianceusername'},
	'appliancepassword' => $c{'appliancepassword'},
	'debuglevel'		=>	1
);

$bc->send_command($c{'command'});


