package ACH;

$VERSION   = '0.01';		# Version number

use strict;
use warnings;

=head1 NAME

ACH - ACH perl object
	
=head1 VERSION

Version: 0.01
May 2006

=head1 DESCRIPTION

ACH is a simple, generic perl object that contains the data necesary to
create an ACH file.  It's intentional use is for testing purposes ONLY.  
ACH will allow a developer to manipulate specific data fields in an ACH 
formatted object.

=head1 USING ACH

	my $ACH = new ACH;

=cut

### Variables and functions

## Arrays that store sizes of the various records in the ACH file ##
# File Header Format fields and field sizes
my @fileFormat = ({'File Header Record' => 1}, {'Priority Code' => 2}, 
{'Immediate Destination' => 10}, {'Immediate Origin' => 10}, {'File Creation Date' => 6},
{'Creation Time' => 4}, {'File ID Modifier' => 1}, {'Record size' => 3}, {'Blocking Factor' => 2},
{'Format Code' => 1}, {'Destination' => 23}, {'Origin' => 23}, {'Reference Code' => 8});

# Batch Record fields and field sizes
my @batchFormat = ({'Batch Header Record' => 1}, {'Service Class Code' => 3}, 
{'Company Name' => 16}, {'Company Discretionary Data' => 20}, {'Company Identification' => 10}, 
{'Standard Entry Classes' => 3}, {'Company Entry Description' => 10}, 
{'Company Descriptive Date' => 6}, {'Effective Entry Date' => 6}, {'Settlement Date' => 3},
{'Originator Status Code' => 1}, {'Originating DFI Identification' => 8}, {'Batch #' => 7});

# Detail Record fields and field sizes
my @detailFormat = ({'Entry Detail Record' => 1}, {'Transaction Code' => 2}, 
{'Individual Bank ID' => 8}, {'Check Digit' => 1}, {'Bank Acct. Number' => 17}, {'Amount' => 10},
{'Individual ID Number' => 15}, {'Individual Name' => 22}, {'Bank Discretionary Data' => 2},
{'Addenda Record Indicator' => 1}, {'Trace Number' => 15});

# Addenda Format fields and field sizes
my @addendaFormat = ({'Addenda Record' => 1}, {'Addenda Type Code' => 2}, 
{'Payment Related Information' => 80}, {'Special Addenda Sequence Number' => 4},
{'Entry Detail Sequence Number' => 7});

# Batch Control Format fields and field sizes
my @controlFormat = ({'Batch Control Record' => 1}, {'Service Class Codes' => 3},
{'Entry/Addenda Count' => 6}, {'Entry Hash' => 10}, {'Total Debit Entry Dollar Amount' => 12}, 
{'Total Credit Entry Dollar Amount' => 12}, {'Company Identification' => 10}, {'Blank' => 19},
{'Blank' => 6}, {'Originating Financial Institution' => 8}, {'Batch Number' => 7});

# File Control fields and field sizes
my @fileControl = ({'File Control Record' => 1}, {'Batch Count' => 6}, {'Block Count' => 6}, 
{'Entry/Addenda Count' => 8}, {'Entry Hash' => 10}, {'Total Debit Entry Dollar Amount' => 12}, 
{'Total Credit Entry Dollar Amount' => 12}, {'Reserved/Blank' => 39});

# All of the ACH File Formats
my %achFormats = (1 => \@fileFormat, 5 => \@batchFormat, 6 => \@detailFormat, 
7 => \@addendaFormat, 8 => \@controlFormat, 9 => \@fileControl);
##

# ACH data
my @achData;

=head1 METHODS

=head2 new

Creates a new ACH object

=cut

# Create a new ACH object
sub new  { 
    my $class = shift;
    my $self  = {};         # allocate new hash for object
    
    bless {
      _achData         => [],
      _achFormats      => \%achFormats,
    }, $class;
}

=head2 printAllData

Prints all the ACH data

=cut

# Print all data from the ACH object
sub printAllData {
  my $self = shift;
  foreach my $item (@{$self->{_achData}}) { # Array of ACH file Sections
    my @achSections = map { defined $_ ? $_ : '' } @{$item};
    foreach my $section (@achSections) { # Array of ACH file Section data
      my %hash = map { defined $_ ? $_ : '' } %{$section};
      foreach my $hashItem (keys (%hash)) { # Hash containing the ACH field name and value
        print "$hashItem: $hash{$hashItem}\n";
      }
    }
  }
}

=head2 getData

Returns the ACH data

=cut

# Get data
sub getData {
  my $self = shift;
  return \@{$self->{_achData}};
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

The ACH module is Copyright (c) May, 2006 by Christopher Kois. 
http://www.christopherkois.com All rights reserved.  You may distribute 
this module under the terms of GNU General Public License (GPL). 

=head1 SUPPORT/WARRANTY

ACH is free Open Source software. IT COMES WITHOUT WARRANTY OR SUPPORT OF ANY KIND.

=head1 KNOWN BUGS

This is version 0.01 of ACH.  There are currently no known bugs.

=head1 SEE ALSO

L<ACH::Generator>. L<ACH::Parser>

=cut

1;
