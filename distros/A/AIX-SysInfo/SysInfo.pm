######################################################
package AIX::SysInfo;
######################################################
#
# Author: Sergey Leonovich, sleonov@cpan.org
# Architecture: AIX
#

use strict;
our (@ISA, @EXPORT, $VERSION);
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw( get_sysinfo );
$VERSION = "1.2";

#--------------------------------------------------------
# Module code begins
#--------------------------------------------------------
# 
my $UNAME='/usr/bin/uname';
my $OSLEVEL='/usr/bin/oslevel';

my $PRTCONF='/usr/sbin/prtconf';
my %sysinfo = ();
my @pconf_array;

#--------------------------------------------------------
# Simple functions to populate the hash
#--------------------------------------------------------
sub prtconf_param {
        my $param = shift @_;
        my @result = grep {/$param/} @pconf_array;
        return undef unless ( scalar @result );
        ($_ = pop @result) =~ /:\s*(.*)/;
        return $1;
}
sub get_total_ram {
        my $hash = shift @_;
        my $memory = prtconf_param( '^Memory Size:' );
        $memory =~ /(\d+)\D+/; $hash->{total_ram} = $1;
        return 1;
}
sub get_hostname {
        my $hash = shift @_;
        chomp ( $hash->{hostname} = `$UNAME -n` );
        return 1;
}
sub get_aix_version {
        my $hash = shift @_;
        chomp ( $hash->{aix_version} = `$OSLEVEL -r` );
        return 1;
}
sub get_serial_num {
        my $hash = shift @_;
        $hash->{serial_num} = prtconf_param( '^Machine Serial Number:' );
        return 1;
}
sub get_total_swap {
        my $hash = shift @_;
        my $swap = prtconf_param( 'Total Paging Space:' );
        $swap =~ /(\d+)\D+/; $hash->{total_swap} = $1;
        return 1;
}
sub get_hardware_info {
        my $hash = shift @_;
        chomp ( my $model_data = `$UNAME -M` );
        $model_data =~ /(.*),(.*)/;
        ( $hash->{sys_arch}, $hash->{model_type} ) = ( $1, $2 );
        return 1;
}
sub get_proc_data {
	my $hash = shift @_;
        $hash->{num_procs} = prtconf_param( '^Number Of Processors:' );
        my $speed = prtconf_param( '^Processor Clock Speed:' );
        $speed =~ /(\d+)\D+/; $hash->{proc_speed} = $1;
	$hash->{proc_type} = prtconf_param( '^Processor Type:' );
	return 1;
}
sub get_lpar_info {
        my $hash = shift @_;
        my $lpar = prtconf_param( '^LPAR Info:' );
        $lpar =~ /(\S+)\s+(\S+)/;
        $hash->{lpar_id} = $1;
        $hash->{lpar_name} = $2;
        return 1;
}
sub get_firmware_ver {
	my $hash = shift @_;
	$hash->{firmware_ver} = prtconf_param( '^Firmware Version:' );
	return 1;
}
sub get_kernel_type {
        my $hash = shift @_;
        $hash->{kernel_type} = prtconf_param( '^Kernel Type:' );
        return 1;
}

#-------------------------------------------------------------
# Module's function - get_sysinfo
#-------------------------------------------------------------
sub get_sysinfo {
	%sysinfo = ();
        my $s_ref = \%sysinfo;
        return () unless( $^O eq 'aix');
	return () unless ( open PCONF, "$PRTCONF |" );

	chomp (@pconf_array = <PCONF>);

        &get_hostname     ( $s_ref );
        &get_aix_version  ( $s_ref );
        &get_hardware_info( $s_ref );
        &get_serial_num   ( $s_ref );
        &get_proc_data    ( $s_ref );
	&get_firmware_ver ( $s_ref );
        &get_total_ram    ( $s_ref );
        &get_total_swap   ( $s_ref );
        &get_lpar_info    ( $s_ref );
	&get_kernel_type  ( $s_ref );
        return %sysinfo;
}
1;
#------------------------------------------------------
# Module code ends
#------------------------------------------------------

__END__

=pod
=head1 NAME

AIX::SysInfo - A Perl module for retrieving information about an AIX pSeries system

=head1 SYNOPSIS

  use AIX::SysInfo;
  my %sysinfo = get_sysinfo;

=head1 DESCRIPTION

You can install it using the usual Perl fashion:

  perl Makefile.PL
  make
  make test
  make install

This module provides a Perl interface for accessing information about a pSeries machine running the AIX operating system.  It makes available a single function, B<get_sysinfo>, which returns a hash containing the following keys:

=over

=item B<hostname>

The value of this key contains the hostname of the system.

=item B<serial_num>

The value of this key contains the unique ID number for the system.

=item B<num_procs>

The value of this key contains the number of processors in the system.

=item B<proc_speed>

The value of this key contains the speed of the processors in the system.

=item B<proc_type>

The value of this key contains the processor type (PowerPC_POWER5)

=item B<total_ram>

The value of this key contains the total amount of RAM in the system, in megabytes.

=item B<total_swap>

The value of this key contains the total amount of swap space in the system, in megabytes.

=item B<aix_version>

The value of this key contains the version of AIX and the latest complete maintenance level on ths system, in the form "VRMF-ML".

=item B<model_type>

The value of this key contains the hardware model as reported by uname -M (9117-570)


=item B<sys_arch>

The value of this key contains information on hrdware architecture. It is taken from uname -M and on most modern systems it is simply IBM

=item B<firmware_ver>

The value of this key contains version of the firmware (IBM,SF240_358)

=item B<lpar_name>

The value of this key is LPAR name. If LPAR does not exist it is 'NULL'

=item B<lpar_id>

The value of this key is LPAR number. If LPAR does not exist it is '-1'

=back

=head1 NOTE

Most of the data is obtained by parsing output of these three AIX commands:  B</usr/bin/uname>, B</usr/bin/oslevel>, B</usr/sbin/prtconf>

=head1 VERSION

   1.1.1 (released on Wed Jun 17 15:07:35 CDT 2009)
   1.1   (released on Tue Jun 16 16:39:00 CDT 2009)
   1.0   (released 2000-07-03)

=head1 BUGS

With version 1.1 this module was rewritten from scratch. It has been tested on p570/p595 LPAR hardware and on several older stand-alone servers. This version works slower that version 1.0 because it relies on prtconf command which takes several seconds to run, but it is more reliable method ( than others ) to query system parameters.

=head1 TO-DO

=over 2

=item *  Add an object-oriented interface.

=item *  Add many more functions.

=back

=head1 AUTHOR

  Sandor W. Sklar
  <mailto:ssklar@stanford.edu>
  <http://whippet.stanford.edu/~ssklar/>

  Version 1.1 is a complete re-write of the module
  Sergey Leonovich
  sleonov@cpan.org
  
=head1 COPYRIGHT/LICENSE

   Copyright (c) 2009, Sergey Leonovich
   Copyright (c) 2001, Sandor W. Sklar.

   This module is free software.
   It may be used, redistributed, and/or modified under the terms of the Perl Artistic License.

=cut
