package ACH::Parser;

$VERSION = '0.01';

use strict;
use warnings;

use ACH;

sub _croak { require Carp; Carp::croak(@_) }

=head1 NAME

ACH::Parser - Parse an ACH formatted file to ACH perl object
	
=head1 VERSION

Version: 0.01
May 2006

=head1 DESCRIPTION

ACH::Parser is a simple, generic ACH file to ACH object parser.
It's intentional use is for testing purposes ONLY.  ACH-Parser will
allow a developer to look at the particular fields in an ACH formatted
file.

=head1 USING ACH-Parser

	use ACH::Parser;

	my $file = 'RETODC0104A.ACH';
	my $ach = new ACH;
	$ach->parse($file);

=head1 METHODS

=head2 parse

Parses the ACH data into the ACH object

=cut

# Parse the ACH file formatted text into an ACH object
sub ACH::parse {
  # Get the file name
  my $self = shift; 
  my $file = shift or _croak "Need an ACH file";
  
  # Open the file
  if ( open(INPUT, "$file") ) {}
  else { print "Error:  Couldn't open file $file\n"; die; }

  # Get the file contents
  my @data = <INPUT>;
  my $dataline = $data[0];
  my $pos = 0;
  
  # Loop Through all entries
  while ($pos < length($dataline)) {
    # Get the correct ACH format array and store all parsed data in a hash
    my $desc = substr($dataline, $pos, 1);
    my @dataArray = [];

    # Make sure file descriptor is valid
    if ($desc != 1 and $desc != 5 and $desc != 6 and $desc != 7 and $desc != 8 and $desc != 9) {
      die "File Error:  Code: $desc\n";
    }
    
    # Iterate through the appropriate ACH file format array and parse the data
    for (my $x=0; $x < @{$self->{_achFormats}{$desc}}; $x++) {
	  my $field = ${$self->{_achFormats}{$desc}}[$x];
            
	  # Get the field name and length
	  my ($field_name, $field_length);
	  while ( my ($key, $value) = each(%$field) ) { $field_name = $key;  $field_length = $value; }

      # Get the ACH Data from the file
      my $part = substr($dataline, $pos, $field_length);  chomp $part;
      my %hash = ($field_name => $part);
      $dataArray[$x] = \%hash;
      $pos += $field_length;    
    }
    
    # Save data to list
    @{$self->{_achData}}[scalar @{$self->{_achData}}] = \@dataArray; 
  }
  
  # Close the Input file
  close (INPUT);
}


=head2 CAVEATS

This package is created for testing purposes only.  It shouldn't be used 
for production programs or scripts.  There are other commercial products
out there that may be a more efficient solution for accomplishing your
goals.

All records in an ACH file must be formatted in the following sequence
of records.  IF the file is not formatted in this exact sequence, it
may be rejected.

ACH File Layout:
1 - File Header Record
5 - First Company/Batch Header Record
6 - First Entry Detail Record
7 - First Entry Detail Addenda Record (optional)
	|
Multiples of Entry Detail Records
	|
6 - Last Entry Detail Record
7 - Last Entry Detail Addenda Record (optional)
8 - First Company/Batch Control Record
	|
Multiples of Company/Batches
	|
5 - Last Company/Batch Header Record
6 - First Entry Detail Record
7 - First Entry Detail Addenda Record (optional)
	|
Multiples of Entry Detail Records
	|
6 - Last Entry Detail Record
7 - Last Entry Detail Addenda Record (optional)
8 - Last Company/Batch Control Record
9 - File Control Record
9999...9999 (optional)

=head1 AUTHOR

Author: Christopher Kois
Date: May, 2006
Contact: cpkois@cpan.org

=head1 COPYRIGHTS

The ACH-Parser module is Copyright (c) May, 2006 by Christopher Kois. 
http://www.christopherkois.com All rights reserved.  You may distribute this 
module under the terms of GNU General Public License (GPL). 

=head1 SUPPORT/WARRANTY

ACH-Parser is free Open Source software. IT COMES WITHOUT WARRANTY OR SUPPORT OF ANY KIND.

=head1 KNOWN BUGS

This is version 0.01 of ACH::Parser.  There are currently no known bugs.

=head1 SEE ALSO

L<ACH>. L<ACH::Generator>

=cut

1;
