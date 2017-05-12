package Astro::ADS::Result;

# ---------------------------------------------------------------------------

#+
#  Name:
#    Astro::ADS::Result

#  Purposes:
#    Perl wrapper for the ADS database

#  Language:
#    Perl module

#  Description:
#    This module wraps the ADS online database.

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Result.pm,v 1.14 2001/12/03 03:41:45 aa Exp $

#  Copyright:
#     Copyright (C) 2001 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::ADS::Result - Results from an ADS Query

=head1 SYNOPSIS

  $result = new Astro::ADS::Result( Papers => \@papers );

=head1 DESCRIPTION

Stores the results returned from an ADS search as an array of
Astro::ADS::Result::Paper objects.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use warnings;
use vars qw/ $VERSION /;

# Overloading
use overload '""' => "stringify";

use Astro::ADS::Result::Paper;

'$Revision: 1.26 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Result.pm,v 1.14 2001/12/03 03:41:45 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $result = new Astro::ADS::Result( Papers => \@papers );

returns a reference to an ADS Result object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { RESULTS => [] }, $class;

  # If we have arguments configure the object
  $block->configure( @_ ) if @_;

  return $block;

}

# A C C E S S O R  --------------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<sizeof>

Return the number of papers in the Astro::ADS::Result object.

   $paper = $result->sizeof();

=cut

sub sizeof {
  my $self = shift;

  return scalar( @{$self->{RESULTS}} );
}

=item B<pushpaper>

Push a new paper onto the end of the Astro::ADS::Result object

   $result->pushpaper( $paper );

returns the number of papers now in the Result object.

=cut

sub pushpaper {
  my $self = shift;

  # return unless we have arguments
  return unless @_;

  my $paper = shift;
  my $bibcode = $paper->bibcode();

  # push the new hash item onto the stack 
  return push( @{$self->{RESULTS}}, $paper );
}

=item B<poppaper>

Pop a paper from the end of the Astro::ADS::Result object

   $paper = $result->poppaper();

the method deletes the paper and returns the deleted paper object.

=cut

sub poppaper {
  my $self = shift;
  my $bibcode = shift;

  # pop the paper out of the stack
  return pop( @{$self->{RESULTS}} );
}

=item B<papers>

Return a list of all the C<Astro::ADS::Result::Paper> objects
stored in the results object.

  @papers = $result->papers;

=cut

sub papers {
  my $self = shift;
  return @{ $self->{RESULTS} };
}

=item B<paperbyindex>

Return the Astro::ADS::Result::Paper object at index $index

   $paper = $result->paperbyindex( $index );

the first paper is at index 0 (not 1). Returns undef if no arguements 
are provided.

=cut

sub paperbyindex {
  my $self = shift;

  # return unless we have arguments
  return unless @_;

  my $index = shift;

  return ${$self->{RESULTS}}[$index];
}


# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an options hash as argument

  $result->configure( %options );

Takes a hash as argument with the following keywords:

=over 4

=item B<Papers>

An reference to an array of Astro::ADS::Result::Paper objects.


=back

Does nothing if these keys are not supplied.

=cut

sub configure {
  my $self = shift;

  # return unless we have arguments
  return unless @_;

  # grab the argument list
  my %args = @_;

  if (defined $args{Papers}) {

     # Go through each of the supplied paper objects
     for my $i ( 0 ...$#{$args{Papers}} ) {
        ${$self->{RESULTS}}[$i] = ${$args{Papers}}[$i];
     }
  }

}

=item B<summary>

Return a summary of the object as either plain text table or in XML.
Simply invokes the C<summary> method of each paper in turn and combines
the results as a single string.

The arguments are passed through to the C<summary> method unchanged.

=cut

sub summary {
  my $self = shift;
  my %args = @_;

  # Array for strings
  my @output;

  # If we are in XML mode we need to add a wrapper
  push(@output, "<ADSResult>") if exists $args{format} and 
    $args{format} eq 'XML';

  # loop over papers
  push(@output, map { $_->summary(%args) } $self->papers);

  # If we are in XML mode we need to add a wrapper
  push(@output, "</ADSResult>") if exists $args{format} and 
    $args{format} eq 'XML';

  return join("\n", @output). "\n";
}

=item B<stringify>

Method called automatically when the object is printed in
a string context. Simple invokes the C<summary()> method with
default arguments.

=cut

sub stringify {
  my $self = shift;
  return $self->summary();
}

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=head1 COPYRIGHT

Copyright (C) 2001 University of Exeter. All Rights Reserved.

This program was written as part of the eSTAR project and is free software; 
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;
