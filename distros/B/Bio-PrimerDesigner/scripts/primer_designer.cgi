#!/usr/bin/perl

# $Id: primer_designer.cgi 6 2008-11-06 21:34:01Z kyclark $

use strict;
use warnings;
use CGI ':standard';
use CGI::Carp 'fatalsToBrowser';
use Bio::PrimerDesigner;
use Readonly;

Readonly my %BINARY => (
    primer3 => \&primer3,
    ePCR    => \&ePCR,
);

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
my $method = $BINARY{ $binary } or die "Invalid binary '$binary'";

delete $config{'program'};

$method->( %config );

# -------------------------------------------------------------------
sub primer3 {
    my %config  = @_ or die "no primer3 input";
    my $primer3 = Bio::PrimerDesigner->new or die Bio::PrimerDesigner->error;
    my $result  = $primer3->design( %config )
                  or die $primer3->error;
    print $result->raw_output;
}

# -------------------------------------------------------------------
sub ePCR {
    my %config = @_;

    my $local_epcr = Bio::PrimerDesigner->new( program => 'epcr')
      or die Bio::PrimerDesigner->error;

    my $result = $local_epcr->run( %config )
      or die $local_epcr->error;

    print $result->raw_output;
}

exit 0;

# -------------------------------------------------------------------

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

=head1 AUTHORS

Copyright (C) 2003-2009 Sheldon McKay E<lt>mckays@cshl.eduE<gt>,
Ken Youens-Clark E<lt>kclark@cpan.orgE<gt>.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 3 or any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301
USA.

=head1 SEE ALSO

Bio::PrimerDesigner, Bio::PrimerDesigner::primer3, Bio::PrimerDesigner::e-PCR.

=cut
