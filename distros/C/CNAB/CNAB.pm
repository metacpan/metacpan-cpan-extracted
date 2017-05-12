#!/usr/local/bin/perl

package CNAB;
require 5.008;
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
our @ISA = qw(Exporter);

%EXPORT_TAGS = ( 'all' => [ qw(
	parse_cnab
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );


our @EXPORT = qw(
    parse_cnab
);

our $VERSION = '0.01';

###############################################################################
#
#	parseCNAB
#	
#	Expects the raw contents of a CNAB file and a hashref to store the parse result:
#	Returns 1 on success and 0 on failure
#
###############################################################################
sub parse_cnab{
	my @content = split("\n",shift @_); # transform input into array;
	my $output = shift @_; # get the reference for the array which should get the results
	
	if(scalar @content == 0){ return 0; }
	if(!defined($output)){ return 0; }
	
	my @records; # array of hashes with the information about the records
	
	# information taken from the headers
	my $cnab_version; # version of the CNAB standard
	my $file_type; # type of file being processed (1 = "Client->Bank", 2 = "Bank->Client")
	my $file_sequence; # sequence number for the whole file
	my $batch_type; # type of batch being processed ('R' = "Client->Bank", 'T' = "Bank->Client")
	my $total; # total number of records extracted from the footer

	while ( $_ = shift @content){
		my $line_type = substr($_,7,1); # type of line being processed
		my %record;

		# process special lines
		if($line_type == 0){ # file header
			$cnab_version = substr($_,163,3);
			$file_type = substr($_,142,1);
			$file_sequence = substr($_,157,6);
			next;
		}elsif($line_type == 1){ # batch header
			$batch_type = substr($_,8,1);
			next;
		}elsif($line_type == 5){ # batch footer
			next;
		}elsif($line_type == 9){ # file footer
			$total = substr($_,23,6);
			$total = ($total - 4)/2; # subtract the two headers and footers from the total number of lines and divide by two, since each record uses two lines
			next;
		}
		
		%record->{"bank_code"} = substr($_,0,3);
		%record->{"status_code"} = substr($_,15,2); # see CNAB documentation
		%record->{"status_reason_code"} = substr($_,213,10); # see CNAB documentation
		%record->{"bank_agency"} = substr($_,17,5);
		%record->{"bank_account"} = substr($_,23,12);
		%record->{"our_number"} = substr($_,44,13);
		%record->{"document_number"} = substr($_,58,15);
		%record->{"valid_date"} = substr($_,73,8);
		%record->{"value"} = substr($_,81,13) .".". substr($_,94,2);
		%record->{"currency_code"} = substr($_,130,2);
		$_ = shift @content; # go to the second line of the record (yes, we jump a line)
		if(substr($_,8,5) % 2 > 0){ return 0; } # abort if the sequence number on the second line is not a multiple of 2 (we must have missed a line somewhere!)
		%record->{"sequence"} = substr($_,8,5)/2;
		%record->{"value_interest"} = substr($_,17,13) .".". substr($_,30,2);
		%record->{"value_discount"} = substr($_,32,13) .".". substr($_,45,2);
		%record->{"value_discount2"} = substr($_,47,13) .".". substr($_,60,2);
		%record->{"value_payed"} = substr($_,77,13) .".". substr($_,90,2);
		%record->{"value_credited"} = substr($_,92,13) .".". substr($_,105,2);
		%record->{"date_payed"} = substr($_,137,8);
		%record->{"date_credited"} = substr($_,145,8);
		
		push @records, \%record;
	}
	
	if($cnab_version ne "030"){ return 0; } # invalid version of file
	if($file_type != 2){ return 0; } # we only parse "Bank->Client"
	if(scalar @records <= 0) { return 0; } # no records processed, fail
	if($total != scalar @records){ return 0; } # total number of processed records doesn't match number extracted from file
	
	%{$output}->{"sequence"} = $file_sequence;
	@{%{$output}->{"records"}} = @records;
	
	return 1;
}

__END__

=pod

=head1 NAME

 CNAB - Module for operating with CNAB files 

=head1 SYNOPSIS

 use CNAB;
  
 $bool = parse_cnab($string, $hashref); # read the raw text from the 
 CNAB file and put the contents inside the hash passed as reference

=head1 DESCRIPTION

 Exports functions for operating with CNAB files (Brazilian banks' 
 transaction file standard).

=head2 EXPORT

 parse_cnab

=head1 AUTHOR

 Leo Antunes, E<lt>costela@gmail.comE<gt>

=head1 COPYRIGHT

 CNAB.pm is Copyright (C) 2005 by Leo Antunes 
 All rights reserved. You may distribute this code under the terms 
 of either the GNU General Public License or the Artistic License, 
 as specified in the Perl README file.

=cut
