## ----------------------------------------------------------------------------------------------
## test_parse_show_version.pl
##
## Example file to demonstrate Cisco::Version
## This uses an existing "show version" output
##
## $Id: test_parse_show_version.pl 71 2007-07-23 20:26:08Z mwallraf $
## $Author: mwallraf $
## $Date: 2007-07-23 22:26:08 +0200 (Mon, 23 Jul 2007) $
##
## This program is free software; you can redistribute it and/or
## modify it under the same terms as Perl itself.
## ----------------------------------------------------------------------------------------------

use strict;

use lib '../lib';
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

