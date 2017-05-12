package ACH::Generator;

$VERSION = '0.01';

use strict;
use warnings;

use ACH;

sub _croak { require Carp; Carp::croak(@_) }

=head1 NAME

ACH::Generator - Generates an ACH formatted file from an ACH perl object
	
=head1 VERSION

Version: 0.01
May 2006

=head1 DESCRIPTION

ACH::Generator is a simple, generic subclass of ACH used to generate ACH files.
It's intentional use is for testing purposes ONLY.  ACH-Generator will allow a 
developer to create an ACH formatted file.

=head1 USING ACH-Generator

	use ACH::Generator;

	my $newACH = new ACH;
	my $newACHfile = 'newACHFile.ACH';	# The name of the ACH file to be generated
	
	...
	
	$newACH->generate($newACHfile);

=head1 METHODS

=head2 generate

Generates an ACH file from the data in the ACH object

=cut

# Generate the ACH file 
sub ACH::generate {
  # Get the file name
  my $self = shift; 
  my $file = shift or _croak "Need an ACH file";
  
  # File data
  my $data = "";
  
  # Iterate through the ACH Data
  foreach my $item (@{$self->{_achData}}) { # Array of ACH file Sections
    my @achSections = map { defined $_ ? $_ : '' } @{$item};
    my $sectionValue = 0;
    
    for (my $y=0; $y < @achSections; $y++) { # Array of ACH file Section data
      my %hash = map { defined $_ ? $_ : '' } %{$achSections[$y]};
      
      # Use the appropriate file Format size for the appropriate ACH file section
      foreach my $hashItem (keys (%hash)) { # Hash containing the ACH field name and value
        chomp $hash{$hashItem};
        my $dataValue = "";

		# Get the section header in the first field, else get the data        
        if ($y == 0) { $dataValue = $sectionValue = $hash{$hashItem}; }
        else { 
          # Get the field length and data
		  my $field = ${$self->{_achFormats}{$sectionValue}}[$y];
          my ($field_length);  while ( my ($key, $value) = each(%$field) ) { $field_length = $value; }
          $dataValue = substr($hash{$hashItem}, 0, $field_length); 
        }
        
        # Store the data in the file data variable
        $data .= $dataValue;
      }
    }
  }
  
  # Open the file
  if ( open(OUTPUT, ">$file") ) {}
  else { print "Error:  Couldn't open file $file\n"; die; }

  # Print data out to ACH file
  print OUTPUT "$data";

  # Close the ACH file
  close (OUTPUT);
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

The ACH-Generator module is Copyright (c) May, 2006 by Christopher Kois. 
http://www.christopherkois.com All rights reserved.  You may distribute this 
module under the terms of GNU General Public License (GPL). 

=head1 SUPPORT/WARRANTY

ACH-Generator is free Open Source software. IT COMES WITHOUT WARRANTY OR SUPPORT OF ANY KIND.

=head1 KNOWN BUGS

This is version 0.01 of ACH::Generator.  There are currently no known bugs.

=head1 SEE ALSO

L<ACH>. L<ACH::Parser>

=cut

1;
