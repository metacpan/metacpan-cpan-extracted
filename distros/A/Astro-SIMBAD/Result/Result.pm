package Astro::SIMBAD::Result;

# ---------------------------------------------------------------------------

#+
#  Name:
#    Astro::SIMBAD::Result

#  Purposes:
#    Perl wrapper for the SIMBAD database

#  Language:
#    Perl module

#  Description:
#    This module wraps the SIMBAD online database.

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Result.pm,v 1.3 2001/11/28 17:43:34 aa Exp $

#  Copyright:
#     Copyright (C) 2001 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::SIMBAD::Result - Results from an SIMBAD Query

=head1 SYNOPSIS

  $result = new Astro::SIMBAD::Result( Objects => \@objects );

=head1 DESCRIPTION

Stores the results returned from an SIMBAD search as a hash of
Astro::SIMBAD::Result::Object objects with the objects being
indexed by Object Name.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use Astro::SIMBAD::Result::Object;

'$Revision: 1.3 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Result.pm,v 1.3 2001/11/28 17:43:34 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $result = new Astro::SIMBAD::Result( Objects => \@objects );

returns a reference to an SIMBAD Result object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { RESULTS => {},
                      SIZE    => 0 }, $class;

  # If we have arguments configure the object
  $block->configure( @_ ) if @_;

  return $block;

}

# A C C E S S O R  --------------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<sizeof>

Return the number of objects in the Astro::SIMBAD::Result object.

   $num = $result->sizeof();

=cut

sub sizeof {
  my $self = shift;  
  return $self->{SIZE};
}

=item B<addobject>

Push a new Astro::SIMBAD::Result::Object object onto the end of the
Astro::SIMBAD::Result object

   $result->addobject( $object );

returns the number of objects now in the Result object.

=cut

sub addobject {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;
  
  # grab the object reference
  my $new_object = shift;
    
  # increment the sizeof counter
  $self->{SIZE} = $self->{SIZE} + 1;
  
  # get the object name as a key for $self->{RESULTS} hash
  my $object_name = $new_object->name();
  $object_name = "Object " . $self->{SIZE} unless defined $object_name;
  ${$self->{RESULTS}}{$object_name} = $new_object;
  
  return $self->{SIZE};

}

=item B<objects>

Return an array of all the C<Astro::SIMBAD::Result::Object> objects
stored in the results object.

  @objects = $result->objects;

=cut

sub objects {
  my $self = shift;
  
  # build the return array from the Object hash
  my @array;
  for my $key ( keys %{$self->{RESULTS}} ) {
     push ( @array, ${$self->{RESULTS}}{$key} );
  }
  
  # return it
  return @array;
}

=item B<objectbyname>

Returns an list of C<Astro::SIMBAD::Result::Object> objects by name

  @objects = $result->objectbyname("IP Peg");

the name given does not have to be a full object name, only a sub-string. 
However, if multiple matches are found an array of possible matches will be
returned.

=cut

sub objectbyname {
  my $self = shift;
  
  my $search_string = shift;
  # build the return array from the Object hash
  my @array;
  for my $key ( keys %{$self->{RESULTS}} ) {
     push ( @array, ${$self->{RESULTS}}{$key} ) if $key =~ $search_string;
  }
  
  # return it
  return @array;
}


=item B<listofobjects>

Returns a list of all the stellar objects held in the Result object

    @object_name = $result->listofobjects();
    $number = $result->listofobjects();

if called in a scalar context it will return the number of objects in
the Result object.

=cut

sub listofobjects{
   my $self = shift;
   
   my @list;
   for my $key ( sort keys %{$self->{RESULTS}} ) {
     push ( @list, $key);
  }   
   
  return wantarray ? @list : scalar(@list);

}

# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an options hash as argument

  $result->configure( %options );

Takes a hash as argument with the following keywords:

=cut

sub configure {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  if (defined $args{Objects}) {

     # Go through each of the supplied stellar object and add it
     for my $i ( 0 ...$#{$args{Objects}} ) {
 
        # increment the hash counter
        $self->{SIZE} = $self->{SIZE} + 1;
        
        # extract the object name and index by it
        my $object_name = ${$args{Objects}}[$i]->name();
        $object_name = "Object " . $self->{SIZE} unless defined $object_name;
        ${$self->{RESULTS}}{$object_name} = ${$args{Objects}}[$i];

     }
  }

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
