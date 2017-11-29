#!/usr/bin/perl

=head1 NAME

runDiscovery.pl This program runs literature based discovery with the 
parameters specified in the input file. Please see samples/lbd or 
samples/thresholding for sample input files and descriptions of parameters
and full details on what can be in an LBD input file.

=head1 SYNOPSIS

This utility takes an lbd configuration file and outputs the results
of lbd

=head1 USAGE

Usage: umls-assocation.pl [OPTIONS] LBD_CONFIG_FILE

=head1 INPUT

=head2 LBD_CONFIG_FILE

Configuration file specifying the parameters of LBD. 
See '../config/lbd' for an example

=head1 OPTIONS

Optional command line arguements

=head2 General Options:

=head3 --help

displays help, a quick summary of program options

=head3 --assocConfig

path to a UMLS::Association configuration file. Default location is 
'../config/association'. Replace this file for your computer to avoid having
to specify each time.

=head3 --interfaceConfig

path to a UMLS::Interface configuration file. Default location is 
'../config/interface'. Replace this file for your computer to avoid having
to specify each time.

=head3 --debug

enter debug mode

=head3 --version

display the version number

=head1 OUTPUT

A file containing the results of LBD

=head1 SYSTEM REQUIREMENTS

=over

=item * Perl (version 5.16.5 or better) - http://www.perl.org

=item * UMLS::Interface - http://search.cpan.org/dist/UMLS-Interface

=item * UMLS::Association - http://search.cpan.org/dist/UMLS-Association

=back

=head1 CONTACT US
   
  If you have any trouble installing and using ALBD, 
  You may contact us directly :
    
      Sam Henry: henryst at vcu.edu 

=head1 AUTHOR

 Sam Henry, Virginia Commonwealth University

=head1 COPYRIGHT

Copyright (c) 2017

 Sam Henry, Virginia Commonwealth University 
 henryst at vcu.edu

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to:

 The Free Software Foundation, Inc.,
 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.

=cut

###############################################################################
#                               THE CODE STARTS HERE
###############################################################################

use strict;
use warnings;

use Getopt::Long;
use ALBD;

###############################################################################
# CONSTANT STRINGS
###############################################################################

my $usage = "Error Running LBD, Usage Instructions:\n\n"
."   runDiscovery LBD_CONFIG_FILE [OPTIONS]\n\n"
."FLAGS\n"
."   --debug       Print EVERYTHING to STDERR.\n"
."   --help        Print this help screen.\n"
."   --version     Print the version number\n"
."\nOPTIONS\n"
."   --assocConfig        path to the UMLS::Association Config File\n"
."   --interfaceConfig    path to the UMLS::Interface Config File\n"
."\nUSAGE EXAMPLES\n"
."   runDiscovery lbdConfigFile\n";
;

#############################################################################
#                       Parse command line options 
#############################################################################
my $DEBUG = 0;      # Prints EVERYTHING. Use with small testing files.        
my $HELP = '';      # Prints usage and exits if true.
my $VERSION;

#set default param values
my %options = ();
$options{'assocConfig'}  = '';
$options{'interfaceConfig'} = '';

#grab all the options and set values
GetOptions( 'debug'             => \$DEBUG, 
            'help'              => \$HELP,
	    'version'           => \$VERSION,
            'assocConfig=s'     => \$options{'assocConfig'},
            'interfaceConfig=s' => \$options{'interfaceConfig'},
);
 
#Check for version or help
if ($VERSION) {
    print "current version is ".(ALBD->version())."\n";
    exit;
}     
if ($HELP) {
    &showHelp();
    exit;
}    


############################################################################
#                          Begin Running LBD
############################################################################

$options{'lbdConfig'} = shift;
defined $options{'lbdConfig'} or die ($usage);

my $lbd = ALBD->new(\%options);
$lbd->performLBD();

############################################################################
#  function to output help messages for this program
############################################################################
sub showHelp() {
        
    print "This utility takes an lbd configuration file and outputs\n";
    print "the results of lbd to file. The parameters for LBD are\n";
    print "specified in the input file. Please see samples/lbd or\n";
    print "samples/thresholding for sample input files and descriptions\n";
    print "of parameters and full details on what can be in an LBD input\n";
    print "file.\n";
    
    print "\n";
    print "Usage: runDiscovery.pl LBD_CONFIG_FILE [OPTIONS]\n";
    
    print "\n";
    print "General Options:\n\n";
    print "--help               displays help, a quick summary of program\n"; 
    print "                     options\n";
    print "--assocConfig        path to a UMLS::Association configuration\n";
    print "                     file. Default location is \n";
    print "                     '../config/association'. Replace this file\n";
    print "                     for your computer to avoid having to specify\n";
    print "                     each time.\n";
    print "--interfaceConfig    path to a UMLS::Interface configuration\n";
    print "                     file. Default location is \n";
    print "                     '../config/interface'. Replace this file \n";
    print "                     for your computer to avoid having to specify\n";
    print "                     each time.\n";
    print "--debug              enter debug mode\n";
    print "--version            prints the current version to screen\n";
};
