package Astro::SIMBAD::Query;

# ---------------------------------------------------------------------------

#+ 
#  Name:
#    Astro::SIMBAD::Query

#  Purposes:
#    Perl wrapper for the SIMBAD database

#  Language:
#    Perl module

#  Description:
#    This module wraps the SIMBAD online database.

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Query.pm,v 1.14 2005/06/08 01:38:17 aa Exp $

#  Copyright:
#     Copyright (C) 2001 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::SIMBAD::Query - Object definining an prospective SIMBAD query.

=head1 SYNOPSIS

  $query = new Astro::SIMBAD::Query( Target  => $object,
                                     RA      => $ra,
                                     Dec     => $dec,
                                     Error   => $radius,
                                     Units   => $radius_units,
                                     Frame   => $coord_frame,
                                     Epoch   => $coord_epoch,
                                     Equinox => $coord_equinox,
                                     Proxy   => $proxy,
                                     Timeout => $timeout,
                                     URL     => $alternative_url );

  my $results = $query->querydb();

  $other = new Astro::SIMBAD::Query( Target  => $object );

=head1 DESCRIPTION

Stores information about an prospective SIMBAD query and allows the query to
be made, returning an Astro::SIMBAD::Result object. Minimum information needed
for a sucessful query is an R.A. and Dec. or an object Target speccification,
other variables will be defaulted.

The Query object supports two types of queries:  "list" (summary)
and "object" (detailed).  The list query usually returns multiple results;
the object query is expected to obtain only one result, but returns extra
data about that target.  An object query is performed if the target name
is specified and the Error radius is 0; otherwise, a list query is done.

The object will by default pick up the proxy information from the HTTP_PROXY 
and NO_PROXY environment variables, see the LWP::UserAgent documentation for
details.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use LWP::UserAgent;
use Net::Domain qw(hostname hostdomain);
use Carp;
use HTML::TreeBuilder;
use HTML::Entities;

use Astro::SIMBAD::Result;
use Astro::SIMBAD::Result::Object;

'$Revision: 1.14 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

sub trim {
  my $s = shift;
  $s =~ s/(^\s+)|(\s+$)//g;
  return $s;
}

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Query.pm,v 1.14 2005/06/08 01:38:17 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $query = new Astro::SIMBAD::Query( Target  => $object,
                                     RA      => $ra,
                                     Dec     => $dec,
                                     Error   => $radius,
                                     Units   => $radius_units,
                                     Frame   => $coord_frame,
                                     Epoch   => $coord_epoch,
                                     Equinox => $coord_equinox,
                                     Proxy   => $proxy,
                                     Timeout => $timeout,
                                     URL     => $alternative_url );

returns a reference to an SIMBAD query object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { OPTIONS   => {},
                      RA        => undef,
                      DEC       => undef,
                      URL       => undef,
                      QUERY     => undef,
                      USERAGENT => undef,
                      BUFFER    => undef,
                      LOOKUP    => {} }, $class;

  # Configure the object
  $block->configure( @_ );

  return $block;

}

# Q U E R Y  M E T H O D S ------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<querydb>

Returns an Astro::SIMBAD::Result object for an inital SIMBAD query

   $results = $query->querydb();

=cut

sub querydb {
  my $self = shift;

  # call the private method to make the actual SIMBAD query
  $self->_make_query();

  # check for failed connect
  return undef unless defined $self->{BUFFER};

  # return an Astro::SIMBAD::Result object
  return $self->_parse_query();

}

=item B<proxy>

Return (or set) the current proxy for the SIMBAD request.

   $query->proxy( 'http://wwwcache.ex.ac.uk:8080/' );
   $proxy_url = $query->proxy();

=cut

sub proxy {
   my $self = shift;

   # grab local reference to user agent
   my $ua = $self->{USERAGENT};

   if (@_) {
      my $proxy_url = shift;
      $ua->proxy('http', $proxy_url );
   }

   # return the current proxy
   return $ua->proxy('http');

}

=item B<timeout>

Return (or set) the current timeout in seconds for the SIMBAD request.

   $query->timeout( 30 );
   $proxy_timeout = $query->timeout();

=cut

sub timeout {
   my $self = shift;

   # grab local reference to user agent
   my $ua = $self->{USERAGENT};

   if (@_) {
      my $time = shift;
      $ua->timeout( $time );
   }

   # return the current timeout
   return $ua->timeout();

}

=item B<url>

Return (or set) the current base URL for the ADS query.

   $url = $query->url();
   $query->url( "simbad.u-strasbg.fr" );

if not defined the default URL is simbad.u-strasbg.fr

=cut

sub url {
  my $self = shift;

  # SETTING URL
  if (@_) { 

    # set the url option 
    my $base_url = shift; 
    if( defined $base_url ) {
       $self->{URL} = $base_url;
       $self->{QUERY} = "http://$base_url/sim-id.pl?";
    }
  }

  # RETURNING URL
  return $self->{URL};
}

=item B<agent>

Returns the user agent tag sent by the module to the ADS server.

   $agent_tag = $query->agent();

=cut

sub agent {
  my $self = shift;
  return $self->{USERAGENT}->agent();
}

# O T H E R   M E T H O D S ------------------------------------------------


=item B<RA>

Return (or set) the current target R.A. defined for the SIMBAD query

   $ra = $query->ra();
   $query->ra( $ra );

where $ra should be a string of the form "HH MM SS.SS", e.g. 21 42 42.66

=cut

sub ra {
  my $self = shift;

  # SETTING R.A.
  if (@_) { 
    
    # grab the new R.A.
    my $ra = shift;
    
    # mutilate it and stuff it and the current $self->{RA} 
    # into the ${$self->{OPTIONS}}{"Ident"} hash item.
    $ra =~ s/\s/\+/g;
    $self->{RA} = $ra;
    
    # grab the currently set DEC
    my $dec = $self->{DEC};
    
    # set the identifier
    ${$self->{OPTIONS}}{"Ident"} = "$ra+$dec";
  }
  
  # un-mutilate and return a nicely formated string to the user
  my $ra = $self->{RA};
  $ra =~ s/\+/ /g;
  return $ra;
}

=item B<Dec>

Return (or set) the current target Declination defined for the SIMBAD query

   $dec = $query->dec();
   $query->dec( $dec );

where $dec should be a string of the form "+-HH MM SS.SS", e.g. +43 35 09.5
or -40 25 67.89

=cut

sub dec { 
  my $self = shift;

  # SETTING DEC
  if (@_) { 

    # grab the new Dec
    my $dec = shift;
    
    # mutilate it and stuff it and the current $self->{DEC} 
    # into the ${$self->{OPTIONS}}{"Ident"} hash item.
    $dec =~ s/\+/%2B/g;
    $dec =~ s/\s/\+/g;
    $self->{DEC} = $dec;
    
    # grab the currently set RA
    my $ra = $self->{RA};
    
    # set the identifier
    ${$self->{OPTIONS}}{"Ident"} = "$ra+$dec";
  }
  
  # un-mutilate and return a nicely formated string to the user
  my $dec = $self->{DEC};
  $dec =~ s/\+/ /g;
  $dec =~ s/%2B/\+/g;
  return $dec;

}

=item B<Target>

Instead of querying SIMBAD by R.A. and Dec., you may also query it by object
name. Return (or set) the current target object defined for the SIMBAD query

   $ident = $query->target();
   $query->target( "HT Cas" );

using an object name will override the current R.A. and Dec settings for the
Query object (if currently set) and the next querydb() method call will query
SIMBAD using this identifier rather than any currently set co-ordinates.

=cut

sub target {
  my $self = shift;

  # SETTING IDENTIFIER
  if (@_) { 

    # grab the new object name
    my $ident = shift;
    
    # mutilate it and stuff it into ${$self->{OPTIONS}}{"Ident"} 
    $ident =~ s/\s/\+/g;
    ${$self->{OPTIONS}}{"Ident"} = $ident;

    # refigure object/list search type
    $self->_update_nbident();
  }
  
  return ${$self->{OPTIONS}}{"Ident"};

}

=item B<Error>

The error radius to be searched for SIMBAD objects around the target R.A. 
and Dec, the radius defaults to 10 arc seconds, with the radius unit being
set using the units() method.

   $error = $query->error();
   $query->error( 20 );

=cut

sub error {
  my $self = shift;

  if (@_) { 
    # If searching with a nonzero radius, do a list query.
    # If radius is zero, get a detailed object query.
    ${$self->{OPTIONS}}{"Radius"} = shift;

    # refigure object/list search type
    $self->_update_nbident();
  }
  
  return ${$self->{OPTIONS}}{"Radius"};

}

=item B<Units>

The unit for the error radius to be searched for SIMBAD objects around the
target R.A.  and Dec, the radius defaults to 10 arc seconds, with the radius itself being set using the error() method

   $error = $query->units();
   $query->units( "arcmin" );

valid unit types are "arcsec", "arcmin" and "deg".

=cut

sub units {
  my $self = shift;

  if (@_) {
  
    my $unit = shift; 
    if( $unit eq "arcsec" || $unit eq "arcmin" || $unit eq "deg" ) {
       ${$self->{OPTIONS}}{"Radius.unit"} = $unit;
    }   
  }
  
  return ${$self->{OPTIONS}}{"Radius.unit"};

}

=item B<use_list_query>

When searching by coordinates, or if the radius is nonzero, we perform a
"list query" that is expected to return multiple results.  However, if
searching for a target by name, and the error radius is zero, it is pretty
clear that we want a specific target.  In that case, we use a more detailed
"object query."

This method returns true if the criteria are such that we will use a list
query and false if it is an object query.

=cut
sub use_list_query {
  my $self = shift;
  return ((${$self->{OPTIONS}}{"Ident"} =~ m/^(\d{1,3}\+){2}/) || (${$self->{OPTIONS}}{"Radius"} > 0));
}

=item B<Frame>

The frame in which the R.A. and Dec co-ordinates are given

   $frame = $query->frame();
   $query->frames( "FK5" );

valid frames are "FK5" and "FK4", if not specified it will default to FK5.

=cut

sub frame {
  my $self = shift;

  if (@_) {
  
    my $frame = shift; 
    if( $frame eq "FK5" || $frame eq "FK4"  ) {
       ${$self->{OPTIONS}}{"CooFrame"} = $frame;
    }   
  }
  
  return ${$self->{OPTIONS}}{"CooFrame"};

}

=item B<Epoch>

The epoch for the R.A. and Dec co-ordinates

   $epoch = $query->epoch();
   $query->epoch( "1950" );

defaults to 2000

=cut

sub epoch {
  my $self = shift;

  if (@_) { 
    ${$self->{OPTIONS}}{"CooEpoch"} = shift;
  }
  
  return ${$self->{OPTIONS}}{"CooEpoch"};

}

=item B<Equinox>

The equinox for the R.A. and Dec co-ordinates

   $equinox = $query->equinox();
   $query->equinox( "2000" );

defaults to 2000

=cut

sub equinox {
  my $self = shift;

  if (@_) { 
    ${$self->{OPTIONS}}{"CooEqui"} = shift;
  }
  
  return ${$self->{OPTIONS}}{"CooEqui"};

}

=item B<Queryurl>

Returns the URL used to query the Simbad database

=cut

sub queryurl {
   my $self = shift;

   # grab the base URL
   my $URL = $self->{QUERY};
   my $options = "";

   # loop round all the options keys and build the query
   foreach my $key ( keys %{$self->{OPTIONS}} ) {
      $options = $options . "&$key=${$self->{OPTIONS}}{$key}";
   }

   # build final query URL
   $URL = $URL . $options;
   
   return $URL;
}

# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an options hash as an argument

  $query->configure( %options );

Does nothing if the array is not supplied.

=cut

sub configure {
  my $self = shift;

  # CONFIGURE DEFAULTS
  # ------------------

  # default the R.A. and DEC to blank strings to avoid uninitialized 
  # value problems when creating the object
  $self->{RA} = "";
  $self->{DEC} = "";

  # define the default base URLs
  $self->{URL} = "simbad.u-strasbg.fr";
  
  # define the query URLs
  my $default_url = $self->{URL};
  $self->{QUERY} = "http://$default_url/sim-id.pl?";

  # Setup the LWP::UserAgent
  my $HOST = hostname();
  my $DOMAIN = hostdomain();
  $self->{USERAGENT} = new LWP::UserAgent( timeout => 30 ); 
  $self->{USERAGENT}->agent("Astro::SIMBAD/$VERSION ($HOST.$DOMAIN)");

  # Grab Proxy details from local environment
  $self->{USERAGENT}->env_proxy();

  # configure the default options
  ${$self->{OPTIONS}}{"protocol"}           = "html";
  ${$self->{OPTIONS}}{"Ident"}              = undef;
  ${$self->{OPTIONS}}{"NbIdent"}            = "around";
  ${$self->{OPTIONS}}{"Radius"}             = "10";
  ${$self->{OPTIONS}}{"Radius.unit"}        = "arcsec";
  ${$self->{OPTIONS}}{"CooFrame"}           = "FK5";
  ${$self->{OPTIONS}}{"CooEpoch"}           = "2000";
  ${$self->{OPTIONS}}{"CooEqui"}            = "2000";
  ${$self->{OPTIONS}}{"output.max"}         = "all";
  ${$self->{OPTIONS}}{"o.catall"}           = "on";
  ${$self->{OPTIONS}}{"output.mesdisp"}     = "A";
  ${$self->{OPTIONS}}{"Bibyear1"}           = "1983";
  ${$self->{OPTIONS}}{"Bibyear2"}           = "2001";

  # Frame 1, FK5 2000/2000
  ${$self->{OPTIONS}}{"Frame1"}             = "FK5";
  ${$self->{OPTIONS}}{"Equi1"}              = "2000.0";
  ${$self->{OPTIONS}}{"Epoch1"}             = "2000.0";
  
  # Frame 2, FK4 1950/1950
  ${$self->{OPTIONS}}{"Frame2"}             = "FK4";
  ${$self->{OPTIONS}}{"Equi2"}              = "1950.0";
  ${$self->{OPTIONS}}{"Epoch2"}             = "1950.0";
  
  # Frame 3, Galactic
  ${$self->{OPTIONS}}{"Frame3"}             = "G";
  ${$self->{OPTIONS}}{"Equi3"}              = "2000.0";
  ${$self->{OPTIONS}}{"Epoch3"}             = "2000.0";

  # TYPE LOOKUP HASH TABLE
  # ----------------------
 
  # build the data table
  ${$self->{LOOKUP}}{"?"}    =     "Object of unknown nature";
  ${$self->{LOOKUP}}{"Rad"}  =     "Radio-source";
  ${$self->{LOOKUP}}{"mR"}   =     "metric Radio-source";
  ${$self->{LOOKUP}}{"cm"}   =     "centimetric Radio-source";
  ${$self->{LOOKUP}}{"mm"}   =     "millimetric Radio-source";
  ${$self->{LOOKUP}}{"Mas"}  =     "Maser";
  ${$self->{LOOKUP}}{"IR"}   =     "Infra-Red source";
  ${$self->{LOOKUP}}{"IR1"}  =     "IR source at lambda > 10 microns";
  ${$self->{LOOKUP}}{"IR0"}  =     "IR source at lambda < 10 microns";
  ${$self->{LOOKUP}}{"red"}  =     "Very red source";
  ${$self->{LOOKUP}}{"blu"}  =     "Blue object";
  ${$self->{LOOKUP}}{"UV"}   =     "UV-emission source";
  ${$self->{LOOKUP}}{"X"}    =     "X-ray source";
  ${$self->{LOOKUP}}{"gam"}  =     "gamma-ray source";
  ${$self->{LOOKUP}}{"gB"}   =     "gamma-ray Burster";
  ${$self->{LOOKUP}}{"grv"}  =     "Gravitational Source";
  ${$self->{LOOKUP}}{"Lev"}  =     "(Micro)Lensing Event";
  ${$self->{LOOKUP}}{"mul"}  =     "Composite object";
  ${$self->{LOOKUP}}{"reg"}  =     "Region defined in the sky";
  ${$self->{LOOKUP}}{"vid"}  =     "Underdense region of the Universe";
  ${$self->{LOOKUP}}{"SCG"}  =     "Supercluster of Galaxies";
  ${$self->{LOOKUP}}{"ClG"}  =     "Cluster of Galaxies";
  ${$self->{LOOKUP}}{"GrG"}  =     "Group of Galaxies";
  ${$self->{LOOKUP}}{"CGG"}  =     "Compact Group of Galaxies";
  ${$self->{LOOKUP}}{"PaG"}  =     "Pair of Galaxies";
  ${$self->{LOOKUP}}{"Gl?"}  =     "Possible Globular Cluster";
  ${$self->{LOOKUP}}{"Cl*"}  =     "Cluster of Stars";
  ${$self->{LOOKUP}}{"GlC"}  =     "Globular Cluster";
  ${$self->{LOOKUP}}{"OpC"}  =     "Open (galactic) Cluster";
  ${$self->{LOOKUP}}{"As*"}  =     "Association of Stars";
  ${$self->{LOOKUP}}{"**"}   =     "Double or multiple star";
  ${$self->{LOOKUP}}{"EB*"}  =     "Eclipsing binary";
  ${$self->{LOOKUP}}{"Al*"}  =     "Eclipsing binary of Algol type";
  ${$self->{LOOKUP}}{"bL*"}  =     "Eclipsing binary of beta Lyr type";
  ${$self->{LOOKUP}}{"WU*"}  =     "Eclipsing binary of W UMa type";
  ${$self->{LOOKUP}}{"SB*"}  =     "Spectrocopic binary";
  ${$self->{LOOKUP}}{"CV*"}  =     "Cataclysmic Variable Star";
  ${$self->{LOOKUP}}{"DQ*"}  =     "Cataclysmic Var. DQ Her type";
  ${$self->{LOOKUP}}{"AM*"}  =     "Cataclysmic Var. AM Her type";
  ${$self->{LOOKUP}}{"NL*"}  =     "Nova-like Star";
  ${$self->{LOOKUP}}{"No*"}  =     "Nova";
  ${$self->{LOOKUP}}{"DN*"}  =     "Dwarf Nova";
  ${$self->{LOOKUP}}{"XB*"}  =     "X-ray Binary";
  ${$self->{LOOKUP}}{"LXB"}  =     "Low Mass X-ray Binary";
  ${$self->{LOOKUP}}{"HXB"}  =     "High Mass X-ray Binary";
  ${$self->{LOOKUP}}{"Neb"}  =     "Nebula of unknown nature";
  ${$self->{LOOKUP}}{"PoC"}  =     "Part of Cloud";
  ${$self->{LOOKUP}}{"PN?"}  =     "Possible Planetary Nebula";
  ${$self->{LOOKUP}}{"CGb"}  =     "Cometary Globule";
  ${$self->{LOOKUP}}{"EmO"}  =     "Emission Object";
  ${$self->{LOOKUP}}{"HH"}   =     "Herbig-Haro Object";
  ${$self->{LOOKUP}}{"Cld"}  =     "Cloud of unknown nature";
  ${$self->{LOOKUP}}{"GNe"}  =     "Galactic Nebula";
  ${$self->{LOOKUP}}{"BNe"}  =     "Bright Nebula";
  ${$self->{LOOKUP}}{"DNe"}  =     "Dark Nebula";
  ${$self->{LOOKUP}}{"RNe"}  =     "Reflection Nebula";
  ${$self->{LOOKUP}}{"HI"}   =     "HI (neutral) region";
  ${$self->{LOOKUP}}{"MoC"}  =     "Molecular Cloud";
  ${$self->{LOOKUP}}{"HVC"}  =     "High-velocity Cloud";
  ${$self->{LOOKUP}}{"HII"}  =     "HII (ionized) region";
  ${$self->{LOOKUP}}{"PN"}   =     "Planetary Nebula";
  ${$self->{LOOKUP}}{"sh"}   =     "HI shell";
  ${$self->{LOOKUP}}{"SR?"}  =     "SuperNova Remnant Candidate";
  ${$self->{LOOKUP}}{"SNR"}  =     "SuperNova Remnant";
  ${$self->{LOOKUP}}{"*"}    =     "Star";
  ${$self->{LOOKUP}}{"*iC"}  =     "Star in Cluster";
  ${$self->{LOOKUP}}{"*iN"}  =     "Star in Nebula";
  ${$self->{LOOKUP}}{"*iA"}  =     "Star in Association";
  ${$self->{LOOKUP}}{"*i*"}  =     "Star in double system";
  ${$self->{LOOKUP}}{"V*?"}  =     "Star suspected of Variability";
  ${$self->{LOOKUP}}{"Pe*"}  =     "Peculiar Star";
  ${$self->{LOOKUP}}{"HB*"}  =     "Horizontal Branch Star";
  ${$self->{LOOKUP}}{"Em*"}  =     "Emission-line Star";
  ${$self->{LOOKUP}}{"Be*"}  =     "Be Star";
  ${$self->{LOOKUP}}{"WD*"}  =     "White Dwarf";
  ${$self->{LOOKUP}}{"ZZ*"}  =     "Variable White Dwarf of ZZ Cet type";
  ${$self->{LOOKUP}}{"C*"}   =     "Carbon Star";
  ${$self->{LOOKUP}}{"S*"}   =     "S Star";
  ${$self->{LOOKUP}}{"OH*"}  =     "Star with envelope of OH/IR type";
  ${$self->{LOOKUP}}{"CH*"}  =     "Star with envelope of CH type";
  ${$self->{LOOKUP}}{"pr*"}  =     "Pre-main sequence Star";
  ${$self->{LOOKUP}}{"TT*"}  =     "T Tau-type Star";
  ${$self->{LOOKUP}}{"WR*"}  =     "Wolf-Rayet Star";
  ${$self->{LOOKUP}}{"PM*"}  =     "High proper-motion Star";
  ${$self->{LOOKUP}}{"HV*"}  =     "High-velocity Star";
  ${$self->{LOOKUP}}{"V*"}   =     "Variable Star";
  ${$self->{LOOKUP}}{"Ir*"}  =     "Variable Star of irregular type";
  ${$self->{LOOKUP}}{"Or*"}  =     "Variable Star in Orion Nebula";
  ${$self->{LOOKUP}}{"V* RI*"} =   "Variable Star with rapid variations";
  ${$self->{LOOKUP}}{"Er*"}  =     "Eruptive variable Star";
  ${$self->{LOOKUP}}{"Fl*"}  =     "Flare Star";
  ${$self->{LOOKUP}}{"FU*"}  =     "Variable Star of FU Ori type";
  ${$self->{LOOKUP}}{"RC*"}  =     "Variable Star of R CrB type";
  ${$self->{LOOKUP}}{"Ro*"}  =     "Rotationally variable Star";
  ${$self->{LOOKUP}}{"a2*"}  =     "Variable Star of alpha2 CVn type";
  ${$self->{LOOKUP}}{"El*"}  =     "Elliptical variable Star";
  ${$self->{LOOKUP}}{"Psr"}  =     "Pulsars";
  ${$self->{LOOKUP}}{"BY*"}  =     "Variable of BY Dra type";
  ${$self->{LOOKUP}}{"RS*"}  =     "Variable of RS CVn type";
  ${$self->{LOOKUP}}{"Pu*"}  =     "Pulsating variable Star";
  ${$self->{LOOKUP}}{"Mi*"}  =     "Variable Star of Mira Cet type";
  ${$self->{LOOKUP}}{"RR*"}  =     "Variable Star of RR Lyr type";
  ${$self->{LOOKUP}}{"Ce*"}  =     "Classical Cepheid variable Star";
  ${$self->{LOOKUP}}{"eg sr*"} =  "Semi-regular pulsating Star";
  ${$self->{LOOKUP}}{"dS*"}  =     "Variable Star of delta Sct type";
  ${$self->{LOOKUP}}{"RV*"}  =     "Variable Star of RV Tau type";
  ${$self->{LOOKUP}}{"WV*"}  =     "Variable Star of W Vir type";
  ${$self->{LOOKUP}}{"SN*"}  =     "SuperNova";
  ${$self->{LOOKUP}}{"Sy*"}  =     "Symbiotic Star";
  ${$self->{LOOKUP}}{"G"}    =     "Galaxy";
  ${$self->{LOOKUP}}{"PoG"}  =     "Part of a Galaxy";
  ${$self->{LOOKUP}}{"GiC"}  =     "Galaxy in Cluster of Galaxies";
  ${$self->{LOOKUP}}{"GiG"}  =     "Galaxy in Group of Galaxies";
  ${$self->{LOOKUP}}{"GiP"}  =     "Galaxy in Pair of Galaxies";
  ${$self->{LOOKUP}}{"HzG"}  =     "Galaxy with high redshift";
  ${$self->{LOOKUP}}{"ALS"}  =     "Absorption Line system";
  ${$self->{LOOKUP}}{"LyA"}  =     "Ly alpha Absorption Line system";
  ${$self->{LOOKUP}}{"DLy"}  =     "Dumped Ly alpha Absorption Line system";
  ${$self->{LOOKUP}}{"mAL"}  =     "metallic Absorption Line system";
  ${$self->{LOOKUP}}{"rG"}   =     "Radio Galaxy";
  ${$self->{LOOKUP}}{"H2G"}  =     "HII Galaxy";
  ${$self->{LOOKUP}}{"Q?"}   =     "Possible Quasar";
  ${$self->{LOOKUP}}{"EmG"}  =     "Emission-line galaxy";
  ${$self->{LOOKUP}}{"SBG"}  =     "Starburst Galaxy";
  ${$self->{LOOKUP}}{"BCG"}  =     "Blue compact Galaxy";
  ${$self->{LOOKUP}}{"LeI"}  =     "Gravitationnaly Lensed Image";
  ${$self->{LOOKUP}}{"LeG"}  =     "Gravitationnaly Lensed Image of a Galaxy";
  ${$self->{LOOKUP}}{"LeQ"}  =     "Gravitationnaly Lensed Image of a Quasar";
  ${$self->{LOOKUP}}{"AGN"}  =     "Active Galaxy Nucleus";
  ${$self->{LOOKUP}}{"LIN"}  =     "LINER-type Active Galaxy Nucleus";
  ${$self->{LOOKUP}}{"SyG"}  =     "Seyfert Galaxy";
  ${$self->{LOOKUP}}{"Sy1"}  =     "Seyfert 1 Galaxy";
  ${$self->{LOOKUP}}{"Sy2"}  =     "Seyfert 2 Galaxy";
  ${$self->{LOOKUP}}{"Bla"}  =     "Blazar";
  ${$self->{LOOKUP}}{"BLL"}  =     "BL Lac - type object";
  ${$self->{LOOKUP}}{"OVV"}  =     "Optically Violently Variable object";
  ${$self->{LOOKUP}}{"QSO"}  =     "Quasar";

  # CONFIGURE FROM ARGUMENTS
  # -------------------------

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options, note
  # that due to the order these are called in supplying both and RA and Dec
  # and an object Identifier (e.g. HT Cas) will cause the query to default
  # to using the identifier rather than the supplied co-ordinates.
  for my $key (qw / RA Dec Target Error Units Frame Epoch Equinox 
                    Proxy Timeout URL / ) {
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }

}

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=begin __PRIVATE_METHODS__

=head2 Private methods

These methods are for internal use only.

=over 4

=item B<_make_query>

Private function used to make an SIMBAD query. Should not be called directly,
since it does not parse the results. Instead use the querydb() assessor method.

=cut

sub _make_query {
   my $self = shift;

   # grab the user agent
   my $ua = $self->{USERAGENT};

   # clean out the buffer
   $self->{BUFFER} = "";

   # grab the base URL
   my $URL = $self->queryurl();
   
   # build request
   my $request = new HTTP::Request('GET', $URL);

   # grab page from web
   my $reply = $ua->request($request);

   if ( ${$reply}{"_rc"} eq 200 ) {
      # stuff the page contents into the buffer
      $self->{BUFFER} = ${$reply}{"_content"};
   } else {
      $self->{BUFFER} = undef;
      croak("Error ${$reply}{_rc}: Failed to establish network connection");
   }
}

=item B<_parse_query>

Private function used to parse the results returned in an SIMBAD query. Should 
not be called directly. Instead use the querydb() assessor method to make and
parse the results.

=cut

sub _parse_query {
  my $self = shift;
  my $tree = HTML::TreeBuilder->new_from_content($self->{BUFFER});
  $tree->elementify();
  my $result;
  if ($self->use_list_query()) {
      $result = $self->_parse_list_query($tree);
  } else {
      $result = $self->_parse_object_query($tree);
  }
  $tree->delete(); # yes, this is necessary
  return $result;
}

=item B<_parse_list_query>

Private method to parse the results of a list query.  Should not be called
directly. Instead use the querydb() assessor method to make and parse the
results.

=cut

sub _parse_list_query {
  my $self = shift;
  my $tree = shift;

  my $pretag = $tree->find_by_tag_name('pre'); # find the <pre> element
  my $idtext = decode_entities($pretag->as_HTML());
  chomp($idtext);

  my @buffer = split( /\n/, $idtext);

  # create an Astro::SIMBAD::Result object to hold the search results
  my $result = new Astro::SIMBAD::Result();

  # loop round the returned buffer
  foreach my $linepos (2 .. $#buffer-1) {
      my $starline = $buffer[$linepos];

      # create a temporary place holder object
      my $object = new Astro::SIMBAD::Result::Object();  
     
      # split each line using the "pipe" symbol separating the table columns
      my @separated = split( /\|/, $starline );
     

      $self->_insert_query_params($object);
     
      # URL
      # ---
 
      # grab the url based on quotes around the string
      my $start_index = index( $separated[0], q/"/ );
      my $last_index = rindex( $separated[0], q/"/ );
      my $url = substr( $separated[0], $start_index+1, 
			$last_index-$start_index-1);

      # push it into the object
      $object->url( $url );
     
      # NAME
      # ----
     
      # get the object name from the same section
      my $final_index = rindex( $separated[0], "<" ) - 1;
      my $name = substr($separated[0],$last_index+2,$final_index-$last_index-1);
     
      # push it into the object
      $object->name( $name );
    
      # TYPE
      # ----
      my $type = trim($separated[1]);
      
      # push it into the object
      $object->type( $type );
      
      # LONG TYPE
      # ---------
     
      # do the lookup
      for my $key (keys %{$self->{LOOKUP}}) {
        
	  if( $object->type() eq $key ) {
        
	      # push it into the object
	      my $long = ${$self->{LOOKUP}}{$key};
	      $object->long( $long );
	      last;
	  }
      }     
     
      # RA and DEC
      my ($ra, $dec) = $self->_coordinates($separated[2]);
      $object->ra($ra);
      $object->dec($dec);
      
      # B, V magnitudes; field may contain none, one or both
      my ($bmag, $vmag) = split /\s+/, trim($separated[3]);
      if ($bmag && $bmag ne ":") {
	  $object->bmag($bmag);
      }
      $object->vmag($vmag);
    
      # SPECTRAL TYPE
      # -------------
      my $spectral = trim($separated[4]);
      
      # push it into the object
      $object->spec($spectral);
      
      # Add the target object to the Astro::SIMBAD::Result object
      # ---------------------------------------------------------
      $result->addobject( $object );
  }
  
  # return an Astro::SIMBAD::Result object, or undef if no abstracts returned
  return $result;
}

=item B<_parse_object_query>

Private method to parse the results of an object query.  Should not be called
directly. Instead use the querydb() assessor method to make and parse the
results.

=cut

sub _parse_object_query {
  my $self = shift;
  my $tree = shift;

  my $result = new Astro::SIMBAD::Result();
  my $object = new Astro::SIMBAD::Result::Object();

  # The object's detail URL is the query URL
  $object->url($self->queryurl());

  # Find the <a> tag named lab_basic1
  my $basic_anchor = $tree->look_down("_tag", "a", sub { $_[0]->attr("name") eq "lab_basic1"} );

  # Under lab_basic1, find the table cell containing name and long description
  my $objtitle = $basic_anchor->look_down("_tag", "td", sub { $_[0]->as_text() =~ /^Basic data :/ })->as_text();
  my ($label, $name, $long) = split /:|--/, $objtitle;
  $object->name($name);
  $object->long($long);

  # "Basic data" table
  my $bdtable = $basic_anchor->look_down("_tag", "table", sub { $_[0]->attr("cols") eq "3" });

  # Grab the left-hand column of table cells
  my @bdlabels = $bdtable->look_down("_tag", "td", sub { $_[0]->right() });

  my %basic_data = {};
  foreach my $bdlabel (@bdlabels) {
      my $key = trim($bdlabel->as_text());
      my $value = trim($bdlabel->right()->as_text());
      $basic_data{$key} = $value;
  }

  $self->_insert_query_params($object);

  # Set RA and DEC
  my @coord_types = ( ["ICRS", 2000, 2000, "ICRS 2000.0 coordinates"],
		      ["FK5", 2000, 2000, "FK5 2000.0/2000.0 coordinates"],
		      ["FK4", 1950, 1950, "FK4 1950.0/1950.0 coordinates"],
		      );
  foreach my $row (@coord_types) {
      if (join('*', @{$row}[0..2]) eq join('*', $object->frame())) {
	  $label = @{$row}[3];
	  my $coord_string = $basic_data{$label};
	  my ($ra, $dec) = $self->_coordinates($coord_string);
	  $object->ra($ra);
	  $object->dec($dec);
	  last;
      }
  }

  # Spectral type
  $object->spec($basic_data{"Spectral type"});

  # B, V magnitudes
  my ($bmag, $vmag) = split ',', $basic_data{"B magn, V magn, Peculiarities"};
  $object->bmag($bmag);
  $object->vmag($vmag);

  # Proper motion
  if ((my $pm = $basic_data{"Proper motion (mas/yr) [error ellipse]"})) {
    $object->pm(split /\s+/, $pm);
  }

  # Parallax
  if ((my $plx = $basic_data{"Parallaxes (mas)"})) {
    $object->plx(split /\s+/, $plx);
  }

  # Radial velocity/redshift
  if ((my $rvterm = $basic_data{"Radial velocity (v:Km/s) or Redshift (z)"})) {
    my ($type, $mag) = split /\s+/, $rvterm;
    if ($type eq "v") {
      $object->radial($mag);
    } elsif ($type eq "z") {
      $object->redshift($mag);
    }
  }

  # Build an array of designations for this object
  my @idents;
  # Find the <pre> block under the 'lab_ident1' anchor
  my $iptag = $tree->look_down("_tag", "a", sub { $_[0]->attr("name") eq "lab_ident1"} )->find('pre');
  foreach my $idref ($iptag->find("a")) {
    push @idents, trim($idref->as_text());
    $idref = $idref->right();
  }
  $object->ident(\@idents);

  $result->addobject( $object );
  return $result;
}

=item B<_insert_query_params>

Copies frame, epoch and equinox and target from the query params into
the result object.

=cut
sub _insert_query_params {
  my $self = shift;
  my $object = shift;

  # FRAME
  # -----
     
  # grab the current co-ordinate frame from the query object itself
  my @coord_frame = ( ${$self->{OPTIONS}}{"CooFrame"},
		      ${$self->{OPTIONS}}{"CooEpoch"},
		      ${$self->{OPTIONS}}{"CooEqui"} );
  # push it into the object
  $object->frame( \@coord_frame );

  # TARGET
  $object->target($self->target());
}

=item B<_update_nbident>

If the search is for a specific object and the radius is 0, do a detailed
(i.e., object) query, rather than a more general list (summary) query
that is expected to return multiple results.

=cut
sub _update_nbident {
  my $self = shift;
  if ($self->use_list_query()) {
    ${$self->{OPTIONS}}{"NbIdent"} = "around";
  } else {
    ${$self->{OPTIONS}}{"NbIdent"} = "1";
  }
}

=item B<_coordinates>

Private function used to split a coordinate line into RA and DEC values

=cut
sub _coordinates {
     my $self = shift;

     # RA
     # --
     
     my $coords = trim(shift);
     
     # split the RA and Dec line into an array elements
     my @radec = split( /\s+/, $coords );
     
     # ...and then rebuild it
     my $ra;
     unless( $radec[2] =~ '\+' || $radec[2] =~ '-' ) {
       $ra = "$radec[0] $radec[1] $radec[2]";
     } else {
       $ra = "$radec[0] $radec[1] 00.0";
     }
      
     
     # DEC
     # ---
     
     # ...and rebuild the Dec
     my $dec;
     unless ( $radec[2] =~ '\+' || $radec[2] =~ '-' ) {
       $dec = "$radec[3] $radec[4] $radec[5]";
     } else {
       $dec = "$radec[2] $radec[3] 00.0";
     }

     return ($ra, $dec);
}

=item B<_dump_raw>

Private function for debugging and other testing purposes. It will return
the raw output of the last SIMBAD query made using querydb().

=cut

sub _dump_raw {
   my $self = shift;
   
   # split the BUFFER into an array
   my @portable = split( /\n/,$self->{BUFFER});
   chomp @portable;

   return @portable;
}

=item B<_dump_options>

Private function for debugging and other testing purposes. It will return
the current query options as a hash.

=cut

sub _dump_options {
   my $self = shift;

   return %{$self->{OPTIONS}};
}

=back

=end __PRIVATE_METHODS__

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
