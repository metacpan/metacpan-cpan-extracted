package Astro::VO::VOEvent;


=head1 NAME

Astro::VO::VOEvent - Object interface to parse and create VOEvent messages

=head1 SYNOPSIS

To parse a VOEvent file,

   $object = new Astro::VO::VOEvent( File => $file_name );
  
or    

   $object = new Astro::VO::VOEvent( XML => $scalar );
   
Or to build a VOEVENT file,   
 
   $xml = $object->build( %hash );
 

=head1 DESCRIPTION

The module can parse VOEvent messages, and serves as a limited convenience
layer for building new messages. Functionality is currently very limited.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION $SELF /;

#use XML::Parser;
use XML::Simple;
use XML::Writer;
use XML::Writer::String;

use Net::Domain qw(hostname hostdomain);
use File::Spec;
use Carp;
use Data::Dumper;

'$Revision: 1.29 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: VOEvent.pm,v 1.29 2006/11/17 16:54:40 voevent Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $object = new Astro::VO::VOEvent( );

returns a reference to an VOEvent object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { DOCUMENT => undef,
                      WRITER   => undef,
                      BUFFER   => undef }, $class;

  # Configure the object
  $block->configure( @_ ); 

  return $block;

}

# A C C E S S O R   M E T H O D S -------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<build>

Build a VOEvent document

  $xml = $object->build( Type       => $string,
                         Role       => $string,
                         ID         => $url,
                         Reference => { URL => $url, Type => $string } );

or 
  
  $xml = $object->build( Type        => $string,
                         Role        => $string,
                         ID          => $url,
                         Description => $string,
                         Citations   => [ { ID   => $strig,
                                            Cite => $string },
                                              .
                                              .
                                              .
                                          { ID   => $string,
                                            Cite => $string }],
                         Who        => { Publisher => $url,
                                          Contact => { Name      => $string,
                                                       Institution => $string,
                                                       Address   => $string,
                                                       Telephone => $string,
                                                       Email     => $string, },
                                          Date    => $string },
                         WhereWhen   => { RA    => $ra,
                                          Dec   => $dec,
                                          Error => $error,
                                          Time  => $time },
                         How         => { Name     => $string,
                                          Location => $string,
                                          RTML     => $url,
					  Reference => { URL => $url, 
					                 Type => $string,
							 Name => $string } }, 
                         What        => [ { Name  => $strig,
                                            UCD   => $string,
                                            Value => $string },
                                              .
                                              .
                                              .
                                          { Name  => $string,
                                            UCD   => $string,
                                            Value => $string } ],
                         Why  => [ {Inference => { 
                                                   Probability  => $string,
                                                   Relation     => $string,
                                                   Name         => string
                                                   Concept      => string }},
                                                       .
                                                       .
                                                       . 
                                   {Inference => { 
                                                   Probability  => $string,
                                                   Relation     => $string,
                                                   Name         => string
                                                   Concept      => string }},
                                                      .
                                                      .
                                                      . 
                                   {Name => $string},
                                   {Concept => $string }  }
                       );
                         
  
this will create a document from the options passed to the method, most
of the hash keys are optional and if missed out the relevant keywords will
be blank or missing entirely from the built document. Type, Role, ID and 
either Reference or WhereWhen (and their sub-tags) are mandatory.

The <Group> tag can be utilised from within the <What> tag as follows

                         What => [ { Group => [ { Name  => $string,
                                                UCD   => $string,
                                                Value => $string,
                                                Units => $string }, 
                                                  .
                                                  .
                                                  .
                                              { Name  => $string,
                                                UCD   => $string,
                                                Value => $string,
                                                Units => $string } ], },
                                  { Group => [ { Name  => $string,
                                                UCD   => $string,
                                                Value => $string,
                                                Units => $string },
                                                  .
                                                  .
                                                  .
                                              { Name  => $string,
                                                UCD   => $string,
                                                Value => $string,
                                                Units => $string } ], },
                                  { Name  => $string,
                                    UCD   => $string,
                                    Value => $string,
                                    Units => $string },
                                      .
                                      .
                                      .
                                  { Name  => $string,
                                    UCD   => $string,
                                    Value => $string,
                                    Units => $string } ],

this will probably NOT be the final API for the build() method, as it is
overly complex. It is probably one or more convenience methods will be
put ontop of this routine to make it easier to use. See the t/2_simple.t
file in the test suite for an example which makes use of the complex form
of the What tag above.

NB: This is the low level interface to build a message, this is subject
to change without notice as higher level "easier to use" accessor methods
are added to the module. It may eventually be reclassified as a PRIVATE
method.
 
=cut

sub build {
  my $self = shift;
  my %args = @_;

  # mandatory tags
  unless ( exists $args{Role} && exists $args{ID} ) {
     return undef;
  }         

  # open the document
  $self->{WRITER}->xmlDecl( 'UTF-8' );
   
  # BEGIN DOCUMENT ------------------------------------------------------- 
  if ( exists $args{UseHTN} ) {
     $self->{WRITER}->startTag( 'VOEvent', 
        #'type' => $args{Type},
        'role' => $args{Role},
        'id'   => $args{ID},
      	'version' => 'HTN/0.2' );  
  } elsif ( exists $args{UseQualified} ) {
        if ( exists $args{UseID} ) {
          $self->{WRITER}->startTag( 'VOEvent', 
             #'type' => $args{Type},
             'role' => $args{Role},
                'id'   => $args{ID},
	     'version' => '1.1',
	     'xmlns' => 'http://www.ivoa.net/xml/VOEvent/v1.1',
             'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
	     'xsi:schemaLocation' =>
	        'http://www.ivoa.net/xml/VOEvent/v1.1 ' . 
	        'http://www.ivoa.net/xml/VOEvent/VOEvent-v1.1.xsd'
	     );
        } else {
          $self->{WRITER}->startTag( 'VOEvent',
             #'type' => $args{Type},
             'role' => $args{Role},
             'ivorn'   => $args{ID},
             'version' => '1.1',
	     'xmlns' => 'http://www.ivoa.net/xml/VOEvent/v1.1',
             'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
	     'xsi:schemaLocation' =>
	        'http://www.ivoa.net/xml/VOEvent/v1.1 ' . 
	        'http://www.ivoa.net/xml/VOEvent/VOEvent-v1.1.xsd'
             ); 
        }
   } else {	
         $self->{WRITER}->startTag( 'voe:VOEvent',
             #'type' => $args{Type},
             'role' => $args{Role},
             'ivorn'   => $args{ID},
             'version' => '1.1',
	     'xmlns:voe' => 'http://www.ivoa.net/xml/VOEvent/v1.1',
             'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
	     'xsi:schemaLocation' =>
	        'http://www.ivoa.net/xml/VOEvent/v1.1 ' . 
	        'http://www.ivoa.net/xml/VOEvent/VOEvent-v1.1.xsd'
             ); 
	   
   }
                            
  # REFERENCE ONLY -------------------------------------------------------
                             
  if ( exists $args{Reference} ) {
     if ( exists $args{Description} ) {
        $self->{WRITER}->startTag( 'Description' );
        $self->{WRITER}->characters( $args{Description} );
        $self->{WRITER}->endTag( 'Description' );
     }
     
     $self->{WRITER}->emptyTag( 'Reference',
                                'uri' => ${$args{Reference}}{URL},
                                'type' => ${$args{Reference}}{Type} );
  
       
     if( exists $args{UseHTN} || exists $args{UseQualified} ) {
       $self->{WRITER}->endTag( 'VOEvent' );
     } else {
       $self->{WRITER}->endTag( 'voe:VOEvent' );
     }
     $self->{WRITER}->end();
     
     return $self->{BUFFER}->value();
  }

  # SKELETON DOCUMENT ----------------------------------------------------

  # DESCRIPTION
  if ( exists $args{Description} ) {
     $self->{WRITER}->startTag( 'Description' );
     $self->{WRITER}->characters( $args{Description} );
     $self->{WRITER}->endTag( 'Description' );
  }   
 
  # WHO
  if ( exists $args{Who} ) {
     $self->{WRITER}->startTag( 'Who' );
     
     if ( exists ${$args{Who}}{Publisher} && ${$args{Who}}{Publisher} =~ 'ivo:' ) {
      	$self->{WRITER}->startTag( 'AuthorIVORN' );
     	$self->{WRITER}->characters( ${$args{Who}}{Publisher} );
     	$self->{WRITER}->endTag( 'AuthorIVORN' );
     }
     
     my $author_flag = 0;
     if ( exists ${$args{Who}}{Publisher} && 
            ( ! (${$args{Who}}{Publisher} =~ 'ivo:') || exists ${$args{Who}}{Contact} ) )  {
        $self->{WRITER}->startTag( 'Author' );
	$author_flag = 1;
     }	  
     
     # Backward compatible interface to older API, translate as much as possible the
     # RTML based <Who> format into the new IVOA RM format used in v1.1
     if ( exists ${$args{Who}}{Publisher} && 
          ! ${$args{Who}}{Publisher} =~ 'ivo:' ) {
        $self->{WRITER}->startTag( 'title' );
        $self->{WRITER}->characters( ${$args{Who}}{Publisher} );
        $self->{WRITER}->endTag( 'title' );
     }
     if ( exists ${$args{Who}}{Contact} ) {         
       if ( exists ${${$args{Who}}{Contact}}{Institution} ) {
             $self->{WRITER}->startTag( 'shortName' );
	     $self->{WRITER}->characters( ${${$args{Who}}{Contact}}{Institution} ); 
             $self->{WRITER}->endTag( 'shortName' );
       } 
       if ( exists ${${$args{Who}}{Contact}}{Address} ) {
	     $self->{WRITER}->startTag( 'contributor' );
             $self->{WRITER}->characters( ${${$args{Who}}{Contact}}{Address}  );
             $self->{WRITER}->endTag( 'contributor' );                
       }   
       if ( exists ${${$args{Who}}{Contact}}{Name} ) {
             $self->{WRITER}->startTag( 'contactName' );
             $self->{WRITER}->characters( ${${$args{Who}}{Contact}}{Name} );
             $self->{WRITER}->endTag( 'contactName' );
       }  
       if ( exists ${${$args{Who}}{Contact}}{Telephone} ) {
             $self->{WRITER}->startTag( 'contactPhone' );
             $self->{WRITER}->characters( ${${$args{Who}}{Contact}}{Telephone} );
             $self->{WRITER}->endTag( 'contactPhone' );          
       }   
       if ( exists ${${$args{Who}}{Contact}}{Email} ) {
             $self->{WRITER}->startTag( 'contactEmail' );
             $self->{WRITER}->characters( ${${$args{Who}}{Contact}}{Email} );
             $self->{WRITER}->endTag( 'contactEmail' );         
       }    
   
     }
       
     if ( $author_flag == 1 ) {
        $self->{WRITER}->endTag( 'Author' );
     }    
          
     # The new 1.1 format
     if ( exists ${$args{Who}}{AuthorIVORN} ) {
          $self->{WRITER}->startTag( 'AuthorIVORN' );
          $self->{WRITER}->characters( ${$args{Who}}{AuthorIVORN} );
          $self->{WRITER}->endTag( 'AuthorIVORN' );     
     }
     if ( exists ${$args{Who}}{Author} ) {
       $self->{WRITER}->startTag( 'Author' );
          if( exists ${${$args{Who}}{Author}}{Title} ) { 
             $self->{WRITER}->startTag( 'title' );
             $self->{WRITER}->characters( ${${$args{Who}}{Author}}{Title} );
             $self->{WRITER}->endTag( 'title' );
          }
          if( exists ${${$args{Who}}{Author}}{ShortName} ) { 
             $self->{WRITER}->startTag( 'shortName' );
             $self->{WRITER}->characters( ${${$args{Who}}{Author}}{ShortName} );
             $self->{WRITER}->endTag( 'shortName' );
          }
          if( exists ${${$args{Who}}{Author}}{Contributor} ) { 
             $self->{WRITER}->startTag( 'contributor' );
             $self->{WRITER}->characters( ${${$args{Who}}{Author}}{Contributor} );
             $self->{WRITER}->endTag( 'contributor' );
          }
          if( exists ${${$args{Who}}{Author}}{LogoURL} ) { 
             $self->{WRITER}->startTag( 'logoURL' );
             $self->{WRITER}->characters( ${${$args{Who}}{Author}}{LogoURL} );
             $self->{WRITER}->endTag( 'logoURL' );
          }
          if( exists ${${$args{Who}}{Author}}{ContactName} ) { 
             $self->{WRITER}->startTag( 'contactName' );
             $self->{WRITER}->characters( ${${$args{Who}}{Author}}{ContactName} );
             $self->{WRITER}->endTag( 'contactName' );
          }
          if( exists ${${$args{Who}}{Author}}{ContactEmail}  ) { 
             $self->{WRITER}->startTag( 'contactEmail' );
             $self->{WRITER}->characters( ${${$args{Who}}{Author}}{ContactEmail} );
             $self->{WRITER}->endTag( 'contactEmail' );
          }
          if( exists ${${$args{Who}}{Author}}{ContactPhone} ) { 
             $self->{WRITER}->startTag( 'contactPhone' );
             $self->{WRITER}->characters( ${${$args{Who}}{Author}}{ContactPhone} );
             $self->{WRITER}->endTag( 'contactPhone' );
          }	  
       $self->{WRITER}->endTag( 'Author' );
     }
     
     # The <date> tag didn't change between 1.0 and 1.1     
     if ( exists ${$args{Who}}{Date} ) {
       $self->{WRITER}->startTag( 'Date' );
       $self->{WRITER}->characters( ${$args{Who}}{Date} );
       $self->{WRITER}->endTag( 'Date' );
     }   
     
     $self->{WRITER}->endTag( 'Who' );
  }
 
  # CITATIONS
  if ( exists $args{Citations} ) {
     $self->{WRITER}->startTag( 'Citations' );
     
     my @array = @{$args{Citations}};
     foreach my $i ( 0 ... $#array ) {
        if ( exists $args{UseID} ) {
           $self->{WRITER}->startTag( 'EventID','cite' => ${$array[$i]}{Cite} );
	   $self->{WRITER}->characters( ${$array[$i]}{ID} );
	   $self->{WRITER}->endTag( 'EventID' );
        } else {
           $self->{WRITER}->startTag( 'EventIVORN','cite' => ${$array[$i]}{Cite} );
	   $self->{WRITER}->characters( ${$array[$i]}{ID} );
	   $self->{WRITER}->endTag( 'EventIVORN' );	
	}
     }
     $self->{WRITER}->endTag( 'Citations' );
  }
   
  # WHERE & WHEN  
  if ( exists $args{WhereWhen} ) {
    unless ( exists $args{UseHTN} ) {
 
      $self->{WRITER}->startTag( 'WhereWhen' );
      $self->{WRITER}->startTag( 'ObsDataLocation', 
        'xmlns' => 'http://www.ivoa.net/xml/STC/stc-v1.30.xsd',  
        'xmlns:xlink' => 'http://www.w3.org/1999/xlink' );
      $self->{WRITER}->emptyTag( 'ObservatoryLocation',
        'id' => "GEOLUN",
	'xlink:type' => 'simple', 
        'xlink:href' => 'ivo://STClib/Observatories#GEOLUN' );
      $self->{WRITER}->startTag( 'ObservationLocation' );
      $self->{WRITER}->emptyTag( 'AstroCoordSystem',
        'id' => 'UTC-FK5-GEO',
	'xlink:type' => 'simple',  
	'xlink:href' => 'ivo://STClib/CoordSys#UTC-FK5-GEO/' );
      $self->{WRITER}->startTag( 'AstroCoords',
        'coord_system_id' => 'UTC-FK5-GEO' );
      $self->{WRITER}->startTag( 'Time', 'unit' => 's' );
      $self->{WRITER}->startTag( 'TimeInstant' );
      $self->{WRITER}->startTag( 'ISOTime' );
      $self->{WRITER}->characters( ${$args{WhereWhen}}{Time} );
      $self->{WRITER}->endTag( 'ISOTime' );
      $self->{WRITER}->endTag( 'TimeInstant' );
      $self->{WRITER}->endTag( 'Time' );						
      $self->{WRITER}->startTag( 'Position2D', 'unit' => 'deg' );
      $self->{WRITER}->startTag( 'Value2' );
      $self->{WRITER}->startTag( 'C1' );							
      $self->{WRITER}->characters( ${$args{WhereWhen}}{RA} );
      $self->{WRITER}->endTag( 'C1' );
      $self->{WRITER}->startTag( 'C2' );							
      $self->{WRITER}->characters( ${$args{WhereWhen}}{Dec} );
      $self->{WRITER}->endTag( 'C2' );
      $self->{WRITER}->endTag( 'Value2' );
      if ( exists ${$args{WhereWhen}}{Error} ) {
        $self->{WRITER}->startTag( 'Error2Radius' );
        $self->{WRITER}->characters( ${$args{WhereWhen}}{Error} );
        $self->{WRITER}->endTag( 'Error2Radius' );
      }  
      $self->{WRITER}->endTag( 'Position2D' );
      $self->{WRITER}->endTag( 'AstroCoords' );
      $self->{WRITER}->endTag( 'ObservationLocation' );
      $self->{WRITER}->endTag( 'ObsDataLocation' );
  
      #$self->{WRITER}->startTag( 'WhereWhen' );
      #$self->{WRITER}->startTag( 'stc:ObservationLocation' );
      #$self->{WRITER}->startTag( 'crd:AstroCoords',
      #  		      'coord_system_id' => 'FK5-UTC' );
      #$self->{WRITER}->startTag( 'crd:Time', 'unit' => 's' );
      #$self->{WRITER}->startTag( 'crd:TimeInstant' );
      #$self->{WRITER}->startTag( 'crd:TimeScale' );
      #$self->{WRITER}->characters( 'UTC' );
      #$self->{WRITER}->endTag( 'crd:TimeScale' );
      #$self->{WRITER}->startTag( 'crd:ISOTime' );
      #$self->{WRITER}->characters( ${$args{WhereWhen}}{Time} );
      #$self->{WRITER}->endTag( 'crd:ISOTime' );
      #$self->{WRITER}->endTag( 'crd:TimeInstant' );
      #$self->{WRITER}->endTag( 'crd:Time' );
      #$self->{WRITER}->startTag( 'crd:Position2D', 'unit' => 'deg' );
      #$self->{WRITER}->startTag( 'crd:Value2');
      #my $position = ${$args{WhereWhen}}{RA} . " " . ${$args{WhereWhen}}{Dec};
      #$self->{WRITER}->characters( $position );
      #$self->{WRITER}->endTag( 'crd:Value2' );
      #if ( exists ${$args{WhereWhen}}{Error} ) {
      #  $self->{WRITER}->startTag( 'crd:Error1Circle' );
      #  $self->{WRITER}->startTag( 'crd:Size' );
      #  $self->{WRITER}->characters( ${$args{WhereWhen}}{Error} );
      #  $self->{WRITER}->endTag( 'crd:Size' );
      #  $self->{WRITER}->endTag( 'crd:Error1Circle' );
      #}  
      #$self->{WRITER}->endTag( 'crd:Position2D' );
      #$self->{WRITER}->endTag( 'crd:AstroCoords' );
      #$self->{WRITER}->endTag( 'stc:ObservationLocation' );
    } else {
      $self->{WRITER}->startTag( 'WhereWhen', 
                                 'type' => 'simple', );
      $self->{WRITER}->startTag( 'RA', units => 'deg' );
      $self->{WRITER}->startTag( 'Coord' );
      $self->{WRITER}->characters( ${$args{WhereWhen}}{RA} );
      $self->{WRITER}->endTag( 'Coord' );
      if ( defined ${$args{WhereWhen}}{Error} ) {
         $self->{WRITER}->emptyTag( 'Error', 
                            value => ${$args{WhereWhen}}{Error},
			    units => "arcmin" );
      }
      $self->{WRITER}->endTag( 'RA' );
      $self->{WRITER}->startTag( 'Dec', units => 'deg' );
      $self->{WRITER}->startTag( 'Coord' );
      $self->{WRITER}->characters( ${$args{WhereWhen}}{Dec} );
      $self->{WRITER}->endTag( 'Coord' );
      
      if ( defined ${$args{WhereWhen}}{Error} ) {
         $self->{WRITER}->emptyTag( 'Error', 
                            value => ${$args{WhereWhen}}{Error},
			    units => "arcmin" );
      }                      
      $self->{WRITER}->endTag( 'Dec' );  
      $self->{WRITER}->emptyTag( 'Epoch', value => "J2000.0" );      
      $self->{WRITER}->emptyTag( 'Equinox', value => "2000.0" ); 

      $self->{WRITER}->startTag( 'Time' );
      $self->{WRITER}->startTag( 'Value' );
      $self->{WRITER}->characters( ${$args{WhereWhen}}{Time} );
      $self->{WRITER}->endTag( 'Value' );
      if ( exists ${$args{WhereWhen}}{TimeError} ) {
         $self->{WRITER}->emptyTag( 'Error', 
                            value => ${$args{WhereWhen}}{TimeError},
			    units => "s" );
      }		    
      $self->{WRITER}->endTag( 'Time' );  
       
    } 
    $self->{WRITER}->endTag( 'WhereWhen' );
  }
   
  # HOW
  if ( exists $args{How} ) {
     $self->{WRITER}->startTag( 'How' );
    
     #if ( exists ${$args{How}}{Name} ) {
     #  $self->{WRITER}->startTag( 'Name' );
     #  $self->{WRITER}->characters( ${$args{How}}{Name} );
     #  $self->{WRITER}->endTag( 'Name' );
     #}           
    
     #if ( exists ${$args{How}}{Location} ) {
     #  $self->{WRITER}->startTag( 'Location' );
     #  $self->{WRITER}->characters( ${$args{How}}{Location} );
     #  $self->{WRITER}->endTag( 'Location' );
     #}     
     if ( exists ${$args{How}}{RTML} ) {
       $self->{WRITER}->emptyTag( 'Reference' , 
                                   uri => ${$args{How}}{RTML}, 
                                   type => 'rtml',
				   name => 'Phase 0' );
     }
     if ( exists ${$args{How}}{Reference} ) {
       $self->{WRITER}->emptyTag( 'Reference' , 
                                   uri => ${${$args{How}}{Reference}}{URL}, 
                                   type => ${${$args{How}}{Reference}}{Type},
				   name => ${${$args{How}}{Reference}}{Name} );
     }
             
     $self->{WRITER}->endTag( 'How' );
  }

  # WHAT
  if ( exists $args{What} ) {
     $self->{WRITER}->startTag( 'What' );
     
     my @array = @{$args{What}};
     foreach my $i ( 0 ... $#array ) {
     
        my %hash = %{${$args{What}}[$i]};
        
        if ( exists $hash{Group} ) {
           $self->{WRITER}->startTag( 'Group' );
        
           my @subarray = @{$hash{Group}};
           foreach my $i ( 0 ... $#subarray ) {
           
              # Only UNITS is optional for Param tags
              if ( exists ${$subarray[$i]}{Units} ) {
                $self->{WRITER}->emptyTag('Param',
                                          'name'  => ${$subarray[$i]}{Name},
                                          'ucd'   => ${$subarray[$i]}{UCD},
                                          'value' => ${$subarray[$i]}{Value},
                                          'units' => ${$subarray[$i]}{Units} );
              } else {
                $self->{WRITER}->emptyTag('Param',
                                          'name'  => ${$subarray[$i]}{Name},
                                          'ucd'   => ${$subarray[$i]}{UCD},
                                          'value' => ${$subarray[$i]}{Value},
                                          'units' => ${$subarray[$i]}{Units} );
              }    
           }
                                         
           $self->{WRITER}->endTag( 'Group' );
        
        } else {
           # Only UNITS is optional for Param tags
           if ( exists $hash{Units} ) {
              $self->{WRITER}->emptyTag('Param',
                                        'name'  => $hash{Name},
                                        'ucd'   => $hash{UCD},
                                        'value' => $hash{Value},
                                        'units' => $hash{Units} ); 
           } else {
              $self->{WRITER}->emptyTag('Param',
                                        'name'  => $hash{Name},
                                        'ucd'   => $hash{UCD},
                                        'value' => $hash{Value} );  
           } 
        }                                                     
     }    
          
     $self->{WRITER}->endTag( 'What' );
  }
  
  # WHY
  if ( exists $args{Why} ) {
     $self->{WRITER}->startTag( 'Why' );
     
     my @array = @{$args{Why}};
     foreach my $i ( 0 ... $#array ) {
     
        my %hash = %{${$args{Why}}[$i]};
        if ( exists $hash{Inference} ) {
        
          if ( exists ${$hash{Inference}}{Relation} &&
               exists ${$hash{Inference}}{Probability}) {
            $self->{WRITER}->startTag( 'Inference',
                   'probability' => ${$hash{Inference}}{Probability},
                   'relation'    => ${$hash{Inference}}{Relation} );
          } elsif ( exists ${$hash{Inference}}{Probability}) {
            $self->{WRITER}->startTag( 'Inference',
                   'probability' => ${$hash{Inference}}{Probability} );          
          } elsif ( exists ${$hash{Inference}}{Relation} ) {
            $self->{WRITER}->startTag( 'Inference',
                   'relation'    => ${$hash{Inference}}{Relation} );               
          } else {
            $self->{WRITER}->startTag( 'Inference');          
          } 
          
          if( exists ${$hash{Inference}}{Concept} ) {
             $self->{WRITER}->startTag( 'Concept' );
             $self->{WRITER}->characters( ${$hash{Inference}}{Concept} );         
             $self->{WRITER}->endTag( 'Concept' );
          }
          
          if ( exists ${$hash{Inference}}{Name} ) {            
             $self->{WRITER}->startTag( 'Name' );
             $self->{WRITER}->characters( ${$hash{Inference}}{Name} );         
             $self->{WRITER}->endTag( 'Name' );                   
          }                              
          $self->{WRITER}->endTag( 'Inference' );
        
        } elsif( exists $hash{Name} ) {
          $self->{WRITER}->startTag( 'Name' );
          $self->{WRITER}->characters( $hash{Name} );         
          $self->{WRITER}->endTag( 'Name' );
          
        } elsif( exists $hash{Concept} ) {  
          $self->{WRITER}->startTag( 'Concept' );
          $self->{WRITER}->characters( $hash{Concept} );         
          $self->{WRITER}->endTag( 'Concept' );

        }                                                     
     }    
          
     $self->{WRITER}->endTag( 'Why' );  
 
  }  
  
  # END DOCUMENT --------------------------------------------------------- 
  if( exists $args{UseHTN} || exists $args{UseQualified} ) {
    $self->{WRITER}->endTag( 'VOEvent' );
  } else {
    $self->{WRITER}->endTag( 'voe:VOEvent' );
  }
  $self->{WRITER}->end();
  
  my $xml = $self->{BUFFER}->value();
  $self->_parse( XML => $xml );
  return $xml;  
   
     
}

=item B<id>

Return the id of the VOEvent document

  $object = new Astro::VO::VOEvent( XML => $scalar );
  $id = $object->id();
  
=cut

sub id {
  my $self = shift;

  my $id;
  if ( defined $self->{DOCUMENT}->{ivorn} ) {
    $id = $self->{DOCUMENT}->{ivorn};
  } else {
    $id = $self->{DOCUMENT}->{id};
  }
  return $id;
}

=item B<role>

Return the role of the VOEvent document

  $object = new Astro::VO::VOEvent( XML => $scalar );
  $id = $object->role();
  
=cut

sub role {
  my $self = shift;
  return $self->{DOCUMENT}->{role};
}

=item B<version>

Return the version of the VOEvent document

  $object = new Astro::VO::VOEvent( XML => $scalar );
  $version = $object->version();
  
=cut

sub version {
  my $self = shift;
  return $self->{DOCUMENT}->{version};
}


=item B<description>

Return the human readable description from the VOEvent document

  $object = new Astro::VO::VOEvent( XML => $scalar );
  $string = $object->description();
  
=cut

sub description {
  my $self = shift;
  return $self->{DOCUMENT}->{Description};
}

=item B{ra}

Return the RA of the object as given in the <WhereWhen> tag

  $object = new Astro::VO::VOEvent( XML => $scalar );
  $ra = $object->ra();

=cut

sub ra {
  my $self = shift;
  
  my %ra;  
  if ( defined $self->{DOCUMENT}->{WhereWhen}->{type} &&
       $self->{DOCUMENT}->{WhereWhen}->{type} eq "simple" ) {
       
     if( defined $self->{DOCUMENT}->{WhereWhen}->{RA}->{Coord} ) {
        $ra{value} = $self->{DOCUMENT}->{WhereWhen}->{RA}->{Coord};
     } elsif ( defined $self->{DOCUMENT}->{WhereWhen}->{Ra}->{Coord} ) {
         $ra{value} = $self->{DOCUMENT}->{WhereWhen}->{Ra}->{Coord};
     }       
     $ra{units} = $self->{DOCUMENT}->{WhereWhen}->{RA}->{units};
     $ra{error} = {"value" => $self->{DOCUMENT}->{WhereWhen}->{RA}->{Error}{value},
                   "units" => $self->{DOCUMENT}->{WhereWhen}->{RA}->{Error}{units}};
  } else {
  
    #print Dumper( $self->{DOCUMENT}->{WhereWhen} );
  
    # Try old style eSTAR default
    my $string = $self->{DOCUMENT}->{WhereWhen}->{"stc:ObservationLocation"}->
                        {"crd:AstroCoords"}->{"crd:Position2D"}->{"crd:Value2"};
    my ($ra, $dec) = split " ", $string if defined $string;
    
    $ra{value} = $ra;
    $ra{units} =  $self->{DOCUMENT}->{WhereWhen}->{"stc:ObservationLocation"}->
                        {"crd:AstroCoords"}->{"crd:Position2D"}->{unit};

    # Try RAPTOR default
    unless ( defined $ra{value} ) {
      $ra{value} = $self->{DOCUMENT}->{WhereWhen}->{"stc:ObsDataLocation"}
       ->{"stc:ObservationLocation"}->{"stc:AstroCoords"}->{"stc:Position2D"}
       ->{"stc:Value2"}->{"stc:C1"};
       
      $ra{units} = $self->{DOCUMENT}->{WhereWhen}->{"stc:ObsDataLocation"}
       ->{"stc:ObservationLocation"}->{"stc:AstroCoords"}->{"stc:Position2D"}
       ->{unit};       
    }   
    
    # Try new style v1.1 default
    unless ( defined $ra{value} ) {
      $ra{value} = $self->{DOCUMENT}->{WhereWhen}->{'ObsDataLocation'}
        ->{'ObservationLocation'}->{'AstroCoords'}->{'Position2D'}
	->{'Value2'}->{'C1'}; 

      $ra{units} = $self->{DOCUMENT}->{WhereWhen}->{'ObsDataLocation'}
        ->{'ObservationLocation'}->{'AstroCoords'}->{'Position2D'}
	->{unit};     
    }

    # Try new style v1.1 default with the <ObservatoryLocation> 
    # and the <AstroCoordsSystem> tags added into the path.
    unless ( defined $ra{value} ) {
      $ra{value} = $self->{DOCUMENT}->{WhereWhen}->{'ObsDataLocation'}
        ->{'ObservatoryLocation'}->{'ObservationLocation'}
	->{'AstroCoordSystem'}->{'AstroCoords'}
	->{'Position2D'}->{'Value2'}->{'C1'}; 

      $ra{units} = $self->{DOCUMENT}->{WhereWhen}->{'ObsDataLocation'}
        ->{'ObservatoryLocation'}->{'ObservationLocation'}
	->{'AstroCoordSystem'}->{'AstroCoords'}
	->{'Position2D'}->{unit};     
    }

  }  
  
  return ( wantarray ? %ra : $ra{"value"} );
}


=item B{dec}

Return the Dec of the object as given in the <WhereWhen> tag

  $object = new Astro::VO::VOEvent( XML => $scalar );
  $dec = $object->dec();

=cut

sub dec {
  my $self = shift;
  
  my %dec;  
  if ( defined $self->{DOCUMENT}->{WhereWhen}->{type} &&
       $self->{DOCUMENT}->{WhereWhen}->{type} eq "simple" ) {
       

     $dec{value} = $self->{DOCUMENT}->{WhereWhen}->{Dec}->{Coord};
     $dec{units} = $self->{DOCUMENT}->{WhereWhen}->{Dec}->{units};
     $dec{error} = {"value"=>$self->{DOCUMENT}->{WhereWhen}->{Dec}->{Error}{value},
                   "units"=>$self->{DOCUMENT}->{WhereWhen}->{Dec}->{Error}{units}};
  } else {
  
    # Try old style eSTAR default
    my $string = $self->{DOCUMENT}->{WhereWhen}->{"stc:ObservationLocation"}->
                        {"crd:AstroCoords"}->{"crd:Position2D"}->{"crd:Value2"};
    my ($ra, $dec) = split " ", $string if defined $string;
    
    $dec{value} = $dec;
    $dec{units} = $self->{DOCUMENT}->{WhereWhen}->{"stc:ObservationLocation"}->
                        {"crd:AstroCoords"}->{"crd:Position2D"}->{unit};


    # Try RAPTOR default
    unless ( defined $dec{value} ) {
      $dec{value} = $self->{DOCUMENT}->{WhereWhen}->{"stc:ObsDataLocation"}
       ->{"stc:ObservationLocation"}->{"stc:AstroCoords"}->{"stc:Position2D"}
       ->{"stc:Value2"}->{"stc:C2"};
       
      $dec{units} = $self->{DOCUMENT}->{WhereWhen}->{"stc:ObsDataLocation"}
       ->{"stc:ObservationLocation"}->{"stc:AstroCoords"}->{"stc:Position2D"}
       ->{unit};
       
    } 
    
    # Try new style v1.1 default
    unless ( defined $dec{value} ) {
      $dec{value} = $self->{DOCUMENT}->{WhereWhen}->{'ObsDataLocation'}
        ->{'ObservationLocation'}->{'AstroCoords'}->{'Position2D'}
	->{'Value2'}->{'C2'}; 

      $dec{units} = $self->{DOCUMENT}->{WhereWhen}->{'ObsDataLocation'}
        ->{'ObservationLocation'}->{'AstroCoords'}->{'Position2D'}
	->{unit};     
    }


    # Try new style v1.1 default with the <ObservatoryLocation> 
    # and the <AstroCoordsSystem> tags added into the path.
    unless ( defined $dec{value} ) {
      $dec{value} = $self->{DOCUMENT}->{WhereWhen}->{'ObsDataLocation'}
        ->{'ObservatoryLocation'}->{'ObservationLocation'}
	->{'AstroCoordSystem'}->{'AstroCoords'}
	->{'Position2D'}->{'Value2'}->{'C2'}; 

      $dec{units} = $self->{DOCUMENT}->{WhereWhen}->{'ObsDataLocation'}
        ->{'ObservatoryLocation'}->{'ObservationLocation'}
	->{'AstroCoordSystem'}->{'AstroCoords'}
	->{'Position2D'}->{unit};     
    }

  }  
  
  return ( wantarray ? %dec : $dec{"value"} );
}   

=item B{epoch}

Return the Dec of the object as given in the <WhereWhen> tag

  $object = new Astro::VO::VOEvent( XML => $scalar );
  $epoch = $object->epoch();

=cut

sub epoch {
  my $self = shift;
  
  if ( defined $self->{DOCUMENT}->{WhereWhen}->{type} &&
       $self->{DOCUMENT}->{WhereWhen}->{type} eq "simple" ) {
       return $self->{DOCUMENT}->{WhereWhen}->{Epoch}->{value};
  } else {
 
    # old style eSTAR default
    my $string = $self->{DOCUMENT}->{WhereWhen}->{"stc:ObservationLocation"}->
                        {"crd:AstroCoords"}->{"coord_system_id"};
	
    # RAPTOR default
    unless (defined $string ) {
       $string =  $self->{DOCUMENT}->{WhereWhen}->{"stc:ObsDataLocation"}
                   ->{"stc:ObservationLocation"}->{"stc:AstroCoords"}
		   ->{"coord_system_id"};
    }
    
    # new style v1.1 default
    unless ( defined $string ) {
      $string = $self->{DOCUMENT}->{WhereWhen}->{'ObsDataLocation'}
        ->{'ObservationLocation'}->{'AstroCoords'}->{"coord_system_id"};
    }

    # Try new style v1.1 default with <ObservatoryLocation> and
    # <AstroCoordSystem> tags
    unless ( defined $string ) {
      $string = $self->{DOCUMENT}->{WhereWhen}->{'ObsDataLocation'}
        ->{'ObservatoryLocation'}->{'ObservationLocation'}
	->{'AstroCoordSystem'}->{'AstroCoords'}
	->{"coord_system_id"};
    }
        		   			
    if( $string =~ "FK5" ) {
       return "J2000.0";
    } else {
       return undef;
    }      
  }  
} 


=item B{equinox}

Return the Dec of the object as given in the <WhereWhen> tag

  $object = new Astro::VO::VOEvent( XML => $scalar );
  $equinox = $object->equinox();

=cut

sub equinox {
  my $self = shift;
  
  if ( defined $self->{DOCUMENT}->{WhereWhen}->{type} &&
       $self->{DOCUMENT}->{WhereWhen}->{type} eq "simple" ) {
       return $self->{DOCUMENT}->{WhereWhen}->{Equinox}->{value};
  } else {
 
    # eSTAR default
    my $string = $self->{DOCUMENT}->{WhereWhen}->{"stc:ObservationLocation"}->
                        {"crd:AstroCoords"}->{"coord_system_id"};
			
    # RAPTOR default
    unless (defined $string ) {
       $string =  $self->{DOCUMENT}->{WhereWhen}->{"stc:ObsDataLocation"}
                   ->{"stc:ObservationLocation"}->{"stc:AstroCoords"}
		   ->{"coord_system_id"};
    }
    
    # new style v1.1 default
    unless ( defined $string ) {
      $string = $self->{DOCUMENT}->{WhereWhen}->{'ObsDataLocation'}
        ->{'ObservationLocation'}->{'AstroCoords'}->{"coord_system_id"};
    }

    # Try new style v1.1 default with <ObservatoryLocation> and
    # the <AstroCoordSystem> tags
    unless ( defined $string ) {
      $string = $self->{DOCUMENT}->{WhereWhen}->{'ObsDataLocation'}
        ->{'ObservatoryLocation'}->{'ObservationLocation'}
	->{'AstroCoordSystem'}->{'AstroCoords'}
	->{"coord_system_id"};
    }
            			
    if( $string =~ "FK5" ) {
       return "2000.0";
    } else {
       return undef;
    }      
  }  
} 

=item B{time}

Return the Time of the object as given in the <WhereWhen> tag

  $object = new Astro::VO::VOEvent( XML => $scalar );
  $time = $object->time();

=cut

sub time {
  my $self = shift;
  
  my $time;  
  if ( defined $self->{DOCUMENT}->{WhereWhen}->{type} &&
       $self->{DOCUMENT}->{WhereWhen}->{type} eq "simple" ) {
       
    $time = $self->{DOCUMENT}->{WhereWhen}->{Time}->{Value};
    
  } else { 
  
    # old style eSTAR default
    $time = $self->{DOCUMENT}->{WhereWhen}->{"stc:ObservationLocation"}->
      {"crd:AstroCoords"}->{"crd:Time"}->{"crd:TimeInstant"}->{"crd:ISOTime"};
    
    # RAPTOR default  
    unless ( defined $time ) {
        
       $time = $self->{DOCUMENT}->{WhereWhen}->{"stc:ObsDataLocation"}
                    ->{"stc:ObservationLocation"}->{"stc:AstroCoords"}
		    ->{"stc:Time"}->{"stc:TimeInstant"}->{"stc:ISOTime"};
	      
    }		        
    
    # new style v1.1 default
    unless ( defined $time ) {
      $time = $self->{DOCUMENT}->{WhereWhen}->{'ObsDataLocation'}
        ->{'ObservationLocation'}->{'AstroCoords'}->{"Time"}
	->{"TimeInstant"}->{"ISOTime"};
    }
    

    # Try new style v1.1 default with <ObservatoryLocation> and
    # the <AstroCoordSystem> tags
    unless ( defined $time ) {
      $time = $self->{DOCUMENT}->{WhereWhen}->{'ObsDataLocation'}
        ->{'ObservatoryLocation'}->{'ObservationLocation'}
	->{'AstroCoordSystem'}->{'AstroCoords'}
	->{"Time"}->{"TimeInstant"}->{"ISOTime"};
    }    
  }  
  
  # There isn't a (valid?) <WhereWhen> see if there is a timestamp in
  # the <Who> tag as this might also carry a publication datestamp.
  unless ( defined $time ) {
    $time = $self->{DOCUMENT}->{Who}->{Date};
  }
  
  return $time;
}


=item B{what}

Return the <Param> and <Group>'s of <Param>s in the <What> tag,

  $object = new Astro::VO::VOEvent( XML => $scalar );
  %what = $object->what();

=cut

sub what {
  my $self = shift;
  if ( defined $self->{DOCUMENT}->{What} ) { 
     return %{$self->{DOCUMENT}->{What}};
  } else {
     return undef;
  }
}

# C O N F I G U R E ---------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an options hash as an argument

  $rtml->configure( %options );

does nothing if the hash is not supplied.

=cut

sub configure {
  my $self = shift;

  # BLESS XML WRITER
  # ----------------
  $self->{BUFFER} = new XML::Writer::String();  
  $self->{WRITER} = new XML::Writer( OUTPUT      => $self->{BUFFER},
                                     DATA_MODE   => 1, 
                                     DATA_INDENT => 4 );
				     
  # CONFIGURE FROM ARGUEMENTS
  # -------------------------

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;
				        
  # Loop over the allowed keys
  for my $key (qw / File XML / ) {
     if ( lc($key) eq "file" && exists $args{$key} ) { 
        $self->_parse( File => $args{$key} );
	last;
	
     } elsif ( lc($key) eq "xml"  && exists $args{$key} ) {
        $self->_parse( XML => $args{$key} );
	last;
	      
     }  
  }				     

  # Nothing to configure...
  return undef;

}

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=head1 COPYRIGHT

Copyright (C) 2002 University of Exeter. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=cut

# P R I V A T E   M E T H O D S ------------------------------------------

=begin __PRIVATE_METHODS__

=head2 Private Methods

These methods are for internal use only.

=over 4

=item B<_parse>

Private method to parse a VOEvent document

  $object->_parse( File => $file_name );
  $object->_parse( XML => $scalar );

this should not be called directly
=cut

sub _parse {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  my $xs = new XML::Simple( );

  # Loop over the allowed keys
  for my $key (qw / File XML / ) {
     if ( lc($key) eq "file" && exists $args{$key} ) { 
	$self->{DOCUMENT} = $xs->XMLin( $args{$key} );
	last;
	
     } elsif ( lc($key) eq "xml"  && exists $args{$key} ) {
	$self->{DOCUMENT} = $xs->XMLin( $args{$key} );
	last;
	
     }  
  }
  
  #print Dumper( $self->{DOCUMENT} );      
  return;
}

# L A S T  O R D E R S ------------------------------------------------------

1;                                                                  
