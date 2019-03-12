#!/usr/bin/env perl
package Bio::Sketch;
use strict;
use warnings;
use Class::Interface qw/interface/;
&interface;   # this actually declares the interface

# Note for developers who read source code: I am open to collaboration.
# Wishlist:
#   * Integration to the BioPerl project
#   * Other Sketch software implementation, e.g., Finch
#   * Ability to write different formats

our $VERSION = 0.1;

=pod

=head1 NAME

Sketch interface module

=head1 SYNOPSIS

An interface module for Sketches, e.g., Mash

		use strict;
		use warnings;
		use Bio::Sketch::Mash;
		
		# Produce a sketch file file.fastq.gz.msh
		system("mash sketch file.fastq.gz");
		# Read the sketch
		my $sketch = Bio::Sketch::Mash->new("file.fastq.gz.msh");
		$sketch->writeJson("file.fastq.gz.json");

=over

=cut

=pod

=item Bio::Sketch->new("file.msh", \%options);

Create a new Sketch instance.  One object per file.

  Arguments: Sketch filename
	           Hash of options
  Returns:   Sketch object

=back

=cut

sub new{...;};

=pod

=item $sketch->sketch("file.fastq.gz");

Sketch a raw reads or assembly file

  Arguments: Filename
  Returns:   1 for success or 0 for failure

=back

=cut

sub sketch{...;};

=pod

=item $sketch->dist($other);

Find the distance between two sketches

  Arguments: Bio::Sketch object
  Returns:   Distance in a float

=back

=cut

sub dist{...;};

=pod

=item $sketch->paste([$other, $other2...]);

Merge two sketches

  Arguments: List of Bio::Sketch objects
  Returns:   Bio::Sketch object of merged sketches

=back

=cut

sub paste{...;};

