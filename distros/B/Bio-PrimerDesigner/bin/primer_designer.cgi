#!/usr/bin/perl

=pod

=head1 NAME

primer_designer.cgi -- server-side wrapper for the primer3 and e-PCR binaries

=head1 SYNOPSIS

  #
  # Design request is made client-side.
  #
  use Bio::PrimerDesigner;
 
  my $local_obj  =  Bio::PrimerDesigner ( 
         method  => 'remote',
         program => 'primer3',
  ) or die Bio::PrimerDesigner->error;

  #
  # Get the program input options.
  # (See Bio::PrimerDesigner docs for input options.)
  #
  my %options = %hash_of_input_options;
 
  #
  # make request and retrieve results of server-side processing
  #
  my $result = design( %options );

=head1 SUBROUTINES

=cut

use CGI ':standard';
use CGI::Carp 'fatalsToBrowser';
use Bio::PrimerDesigner;
use strict;

print header;

check(param('check'));

#
# Get remote config info and re-hashify it.
#
my $input  = param('config') or die "No config info provided";
my @config = split '#', $input;
my %config = ();

for (@config) {
    my ($key, $value) = split '=', $_;
    $config{$key} = $value;
}

#
# Get binary name.
#
my $binary = $config{'program'} or die "No program defined";
delete $config{'program'};

#
# Pass the request and parameters to the local Bio::PrimerDesigner.
#
$binary eq 'primer3' ? primer3( %config ) : ePCR( %config );

# -------------------------------------------------------------------
sub check{

=head2 check

Verifies that this CGI is active and supports the requested binary.

=cut

    my $program = shift;
    if ($program) {
        print "$program OK\n" if $program =~ /e-PCR|primer3/;
        exit;
    }
}

# -------------------------------------------------------------------
sub primer3 {

=head2 primer3

A primer3 wrapper.

=cut

    my %config  = @_ or die "no primer3 input";
    my $primer3 = Bio::PrimerDesigner->new or die Bio::PrimerDesigner->error;
    my $result  = $primer3->design( %config )
                  or die $primer3->error;
    print $result->raw_output;
}

# -------------------------------------------------------------------
sub ePCR {

=head2 ePCR

An e-PCR wrapper.

=cut

    my %config = @_;

    my $local_epcr = Bio::PrimerDesigner->new( program => 'epcr')
      or die Bio::PrimerDesigner->error;

    my $result = $local_epcr->run( %config )
      or die $local_epcr->error;

    print $result->raw_output;
}

# -------------------------------------------------------------------

=pod

=head1 AUTHORS

Copyright (C) 2003-4 Sheldon McKay E<lt>smckay@bcgsc.bc.caE<gt>,
                   Ken Y. Clark E<lt>kclark@cpan.orgE<gt>.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA.

=head1 SEE ALSO

Bio::PrimerDesigner, Bio::PrimerDesigner::primer3, Bio::PrimerDesigner::e-PCR.

=cut
