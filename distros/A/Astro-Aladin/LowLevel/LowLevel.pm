package Astro::Aladin::LowLevel;

# ---------------------------------------------------------------------------

#+ 
#  Name:
#    Astro::Aladin::LowLevel

#  Purposes:
#    Perl class designed to drive the standalone CDS Aladin Application

#  Language:
#    Perl module

#  Description:
#    This module drives the CDS Aladin Java application through an
#    anonymous pipe. 
#
#    This isn't an optimal solution, its a kludge hack and I hope
#    nobody I know is reading the code. There is a higher level class
#    full of convience methods for a reason. Use it!

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: LowLevel.pm,v 1.2 2003/02/24 22:45:56 aa Exp $

#  Copyright:
#     Copyright (C) 2003 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::Aladin::LowLevel - Perl class designed to drive CDS Aladin Application

=head1 SYNOPSIS

  my $aladin = new Astro::Aladin::LowLevel( );


=head1 DESCRIPTION

Drives the CDS Aladin Application through a anonymous pipe, expects the
a copy of the standalone Aladin application to be installed locally
and pointed to by the ALADIN_JAR environment variable.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use File::Spec;
use Carp;

'$Revision: 1.2 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# G L O B A L  V A R I A B L E ---------------------------------------------

# Don't know off the top of my head how to bless a typeglob into an
# class. For now we're going to use a global scalar and carry the
# filehandle around in that. This is a not nice kludge, but then
# the entire modle is fairly icky so do I really care at this point?
my $ALADIN = undef;

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: LowLevel.pm,v 1.2 2003/02/24 22:45:56 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $aladin = new Astro::Aladin::LowLevel( );

returns a reference to an Aladin object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { DUMMY  => undef }, $class;

  # Configure the object
  $block->configure( @_ );

  return $block;

}

# Q U E R Y  M E T H O D S ------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<close>

Closes the anonymous pipe to the aladin application

   $aladin->close();

it should be noted that if you DON'T do this after finishing with
the object you're going to have zombie Java VM hanging around eating
up all your CPU. This is amougst the many reasons why you should
use Astro::Aladin rather than Astro::Aladin::LowLevel to drive the
Aladin Application.

=cut

sub close {
  my $self = shift;

  # set the "quit" command to Aladin
  print $ALADIN "quit\n";
  
  # close the pipe
  close( $ALADIN );
  $ALADIN = undef;

}

=item B<reopen>

Reopen the anonymous pipe to the aladin application

   my $status = $aladin->reopen()

returns undef if the pipe if defined and (presumably) already active.

=cut

sub reopen {
  my $self = shift;

  # check that the pipe is closed and undefined
  unless ( defined $self->{PIPE} ) {
     
     my $aladin_jar;
     if ( defined $ENV{"ALADIN_JAR"} ) { 
         $aladin_jar = File::Spec->catfile($ENV{"ALADIN_JAR"});
     } else {
         croak( "Error: Environment variable \$ALADIN_JAR not defined".
                " see package README file");
     }
  
     # open the pipe to the application
     $ENV{ALADIN_MEM} = "128m" unless defined $ENV{ALADIN_MEM};
     open( $ALADIN ,"| java -mx$ENV{ALADIN_MEM} -jar $ENV{ALADIN_JAR} -script" );
     return;  
  }   

  return undef;
}

=item B<status>

Prints out the status of the current stack.

   $aladin->status()

=cut

sub status {
  my $self = shift;

  # set the "status" command to Aladin
  print $ALADIN "status\n";

}

=item B<sync>

Waits until all planes are ready

   $aladin->sync()

=cut

sub sync {
  my $self = shift;

  # set the "sync" command to Aladin
  print $ALADIN "sync\n";

}

=item B<export>

Export a plane to a file

   $aladin->sync( $plane_number, $filename )

=cut

sub export {
  my $self = shift;
  my $number = shift;
  my $file = shift;

  # set the "export" command to Aladin
  print $ALADIN "export $number $file\n";

}

=item B<get>

Gets images and catalogues from the server

   $aladin->get( $server, \@args, $object, $radius );
   $aladin->get( $server, $object );

For example

   $aladin->get( "aladin", ["DSS1"], $object_name, $radius );
   $aladin->get( "aladin", ["DSS1", "LOW"], $object_name, $radius );  
   $aladin->get( "aladin", [""], $object_name, $radius );  

the radius arguement can be omitted

   $aladin->get( "aladin", ["DSS1"], $object_name );
   
or even more simply
   
   $aladin->get( "simbad", $object_name );

always remember to sync after a series of request, or you might end 
up closing Aladin before its actually finished download the layers.

=cut

sub get {
  my ( $self, $server, $args_ref, $object, $radius );

  # Parse the incoming arguements and see whether we have
  # any arguements to pass to the image/catalog server
  if( scalar @_  == 5 ) {
    ( $self, $server, $args_ref, $object, $radius ) = @_;
  } elsif( scalar @_  == 4 ) {
    ( $self, $server, $args_ref, $object ) = @_;
  } elsif (  scalar @_  == 3 ) {
    ( $self, $server, $object ) = @_;
    $args_ref = [""];
  }
    
  # Call the _get() private method
  _get( $server, $args_ref, $object, $radius );

}


# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object

  $aladin->configure( );

=cut

sub configure {
  my $self = shift;

  # Call the reopen() method to open the anonymous pipe
  reopen();

}

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=begin __PRIVATE_METHODS__

=head2 Private methods

These methods are for internal use only.

=over 4

=item B<get>

Get an image or catalogue

  $aladin->get( $server, \@args, $object );

=cut

sub _get {
  my ( $server, $args_ref, $object, $radius ) = @_;
  
  # Grab the args array 
  my @args = @{$args_ref};
  
  # process the args array
  my $args_string = "";
  
  for my $i ( 0 .. $#args ) {
    if( $i == 0 ) {
       $args_string = $args[$i];
    } else {
       $args_string = "," . $args[$i];
    }      
  }
  
  
  # set the "status" command to Aladin
  if( $args_string eq "" ) {
     unless ( $radius ) {
        print "Sending: get $server() $object\n";
        print $ALADIN "get $server() $object\n";
     } else {
        print "Sending: get $server() $object $radius"."arcmin\n";
        print $ALADIN "get $server() $object $radius"."arcmin\n";
     }  
  } else {
     unless ( $radius ) {
        print "Sending: get $server($args_string) $object\n";
        print $ALADIN "get $server($args_string) $object\n";
     } else {
        print "Sending: get $server($args_string) $object $radius"."arcmin\n";
        print $ALADIN "get $server($args_string) $object $radius"."arcmin\n";
     } 
  }
  
}

=end __PRIVATE_METHODS__

=head1 COPYRIGHT

Copyright (C) 2003 University of Exeter. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;                                                                  
