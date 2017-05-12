package Astro::DSS;

# ---------------------------------------------------------------------------

#+ 
#  Name:
#    Astro::DSS

#  Purposes:
#    Perl wrapper for the Digital Sky Survey (DSS)

#  Language:
#    Perl module

#  Description:
#    This module wraps the DSS online database.

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: DSS.pm,v 1.7 2003/02/21 18:52:15 aa Exp $

#  Copyright:
#     Copyright (C) 2001 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::DSS - An Object Orientated interface to the Digital Sky Survey

=head1 SYNOPSIS

  $dss = new Astro::DSS( RA        => $ra,
                         Dec       => $dec,
                         Target    => $object_name,
                         Equinox   => $equinox,
                         Xsize     => $x_arcmin,
                         Ysize     => $y_arcmin,
                         Survey    => $dss_survey,
                         Format => $type );

  my $file_name = $dss->querydb();

=head1 DESCRIPTION

Stores information about an prospective DSS query and allows the query to
be made, returning a filename pointing to the file returned.

The object will by default pick up the proxy information from the HTTP_PROXY 
and NO_PROXY environment variables, see the LWP::UserAgent documentation for
details.

It will save returned files into the ESTAR_DATA directory or to TMP if
the ESTAR_DATA environment variable is not defined.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use LWP::UserAgent;
use Net::Domain qw(hostname hostdomain);
use File::Spec;
use Carp;

'$Revision: 1.7 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: DSS.pm,v 1.7 2003/02/21 18:52:15 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $dss = new Astro::DSS( RA        => $ra,
                         Dec       => $dec,
                         Target    => $object_name,
                         Equinox   => $equinox,
                         Xsize     => $x_arcmin,
                         Ysize     => $y_arcmin,
                         Survey    => $dss_survey,
                         Format    => $image_type );

returns a reference to an DSS query object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { OPTIONS   => {},
                      URL       => undef,
                      QUERY     => undef,
                      USERAGENT => undef,
                      DATADIR   => undef }, $class;

  # Configure the object
  $block->configure( @_ );

  return $block;

}

# Q U E R Y  M E T H O D S ------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<querydb>

Returns a filename of the image returned from a DSS query.

   $filename = $dss->querydb();

=cut

sub querydb {
  my $self = shift;

  # call the private method to make the actual ADS query
  my $file_name = $self->_make_query();

  # check for failed connect
  return undef unless defined $file_name;

  # return the file name
  return $file_name;

}

=item B<proxy>

Return (or set) the current proxy for the ADS request.

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

Return (or set) the current timeout in seconds for the DSS request.

   $dss->timeout( 30 );
   $proxy_timeout = $dss->timeout();

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

Return (or set) the current base URL for the DSS query.

   $url = $dss->url();
   $query->url( "archive.eso.org" );

if not defined the default URL is archive.eso.org

=cut

sub url {
  my $self = shift;

  # SETTING URL
  if (@_) { 

    # set the url option 
    my $base_url = shift; 
    $self->{URL} = $base_url;
    if( defined $base_url ) {
       $self->{QUERY} = "http://$base_url/dss/dss/image?";
    }
  }

  # RETURNING URL
  return $self->{URL};
}

=item B<agent>

Returns the user agent tag sent by the module to the ADS server.

   $agent_tag = $dss->agent();

=cut

sub agent {
  my $self = shift;
  return $self->{USERAGENT}->agent();
}

# O T H E R   M E T H O D S ------------------------------------------------


=item B<RA>

Return (or set) the current target R.A. defined for the DSS query

   $ra = $dss->ra();
   $dss->ra( $ra );

where $ra should be a string of the form "HH MM SS.SS", e.g. 21 42 42.66

=cut

sub ra {
  my $self = shift;

  # SETTING R.A.
  if (@_) { 
    
    # grab the new R.A.
    my $ra = shift;
    
    # mutilate it and stuff it and the current $self->{RA} 
    $ra =~ s/\s/\+/g;
    ${$self->{OPTIONS}}{"ra"} = $ra;
  }
  
  # un-mutilate and return a nicely formated string to the user
  my $ra = ${$self->{OPTIONS}}{"ra"};
  $ra =~ s/\+/ /g;
  return $ra;
}

=item B<Dec>

Return (or set) the current target Declination defined for the DSS query

   $dec = $dss->dec();
   $dss->dec( $dec );

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
    $dec =~ s/\+/%2B/g;
    $dec =~ s/\s/\+/g;
    ${$self->{OPTIONS}}{"dec"} = $dec;
  }
  
  # un-mutilate and return a nicely formated string to the user
  my $dec = ${$self->{OPTIONS}}{"dec"};
  $dec =~ s/\+/ /g;
  $dec =~ s/%2B/\+/g;
  return $dec;

}


=item B<Equinox>

The equinox for the R.A. and Dec co-ordinates

   $equinox = $dss->equinox();
   $dss->equinox( "2000" );

defaults to 2000.

=cut

sub equinox {
  my $self = shift;

  if (@_) { 
    ${$self->{OPTIONS}}{"equinox"} = shift;
  }
  
  return ${$self->{OPTIONS}}{"equinox"};

}

=item B<Target>

Instead of querying DSS by R.A. and Dec., you may also query it by object
name. Return (or set) the current target object defined for the DSS query,
will query SIMBAD for object name resolution.

   $ident = $dss->target();
   $dss->target( "HT Cas" );

using an object name will override the current R.A. and Dec settings for the
Query object (if currently set) and the next querydb() method call will query
DSS using this identifier rather than any currently set co-ordinates.

=cut

sub target {
  my $self = shift;

  # SETTING IDENTIFIER
  if (@_) { 

    # grab the new object name
    my $ident = shift;
    
    # mutilate it and stuff it into $self->{TARGET}
    $ident =~ s/\s/\+/g;
    ${$self->{OPTIONS}}{"name"} = $ident;
    ${$self->{OPTIONS}}{"ra"} = undef;
    ${$self->{OPTIONS}}{"dec"} = undef;
  }
  
  return ${$self->{OPTIONS}}{"name"};

}

=item B<Xsize>

The x extent of the DSS image to be retrieved in arcmin.

   $xsize = $dss->xsize();
   $dss->xsize( 20 );

Image sizes for FITS, gzipped FITS and GIF are 260kB, 
110kB and 70 kB respectively for a field of 10*10 arc minutes. 
There's a limit of around 4 MB for the largest image to be delivered. 
Images from the DSS2 are bigger, because the pixel size is smaller. 

=cut

sub xsize {
  my $self = shift;

  if (@_) { 
    ${$self->{OPTIONS}}{"x"} = shift;
  }
  
  return ${$self->{OPTIONS}}{"x"};

}

=item B<Ysize>

The y extent of the DSS image to be retrieved in arcmin.

   $xsize = $dss->ysize();
   $dss->ysize( 20 );

Image sizes for FITS, gzipped FITS and GIF are 260kB, 110kB and 70 kB respectively for a field of 10*10 arc minutes. There's a limit of around 4 MB for the largest image to be delivered. Images from the DSS2 are bigger, because the pixel size is smaller. 

=cut

sub ysize {
  my $self = shift;

  if (@_) { 
    ${$self->{OPTIONS}}{"y"} = shift;
  }
  
  return ${$self->{OPTIONS}}{"y"};

}

=item B<Survey>

The survey to return

   $survey = $dss->survey();
   $dss->survey( "DSS1" );

valid choices are DSS1, DSS2-red, DSS2-blue, DSS2-infrared. The entire DSS1 data is stored on magnetic disks at the ESO-ECF Archive. DSS2 is stored on DVD-ROM in a juke box. Retrieval time takes about less than 5 seconds for a DSS1 field and less than 20 seconds for a random DSS2 field in the juke box. 

The DSS1 survey is 100% complete, while the DSS2-red now covers 98% of the sky; DSS2-blue 45% of the sky and DSS2-infrared 27% of the sky.

=cut

sub survey {
  my $self = shift;

  if (@_) { 
    ${$self->{OPTIONS}}{"Sky-Survey"} = shift;
  }
  
  return ${$self->{OPTIONS}}{"Sky-Survey"};

}

=item B<Format>

The image format required

   $format = $dss->format();
   $dss->format( "FITS" );

valid format types are FITS and GIF and FITS.gz. The default is to return 
a GIF Image.

=cut

sub format {
  my $self = shift;

  if (@_) { 
    my $format = shift;
    if( $format eq "FITS" ) {
       ${$self->{OPTIONS}}{"mime-type"} = "download-fits";
    } elsif ( $format eq "FITS.gz" ) {
       ${$self->{OPTIONS}}{"mime-type"} = "download-gz-fits";
    } else {
       ${$self->{OPTIONS}}{"mime-type"} = "download-gif";
    } 
  }
  
  return $self->{FORMAT};

}

# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an options hash as an argument

  $dss->configure( %options );

Does nothing if the array is not supplied.

=cut

sub configure {
  my $self = shift;

  # CONFIGURE DEFAULTS
  # ------------------

  # define the default base URL
  $self->{URL} = "archive.eso.org";
  
  # define the query URLs
  my $default_url = $self->{URL};
  $self->{QUERY} = "http://$default_url/dss/dss/image?";
   
  # Setup the LWP::UserAgent
  my $HOST = hostname();
  my $DOMAIN = hostdomain();
  $self->{USERAGENT} = new LWP::UserAgent( timeout => 30 ); 
  $self->{USERAGENT}->agent("Astro::DDS/$VERSION ($HOST.$DOMAIN)");

  # Grab Proxy details from local environment
  $self->{USERAGENT}->env_proxy();  
  
  # Grab something for DATA directory
  if ( defined $ENV{"ESTAR_DATA"} ) {
     if ( opendir (DIR, File::Spec->catdir($ENV{"ESTAR_DATA"}) ) ) {
        # default to the ESTAR_DATA directory
        $self->{DATADIR} = File::Spec->catdir($ENV{"ESTAR_DATA"});
        closedir DIR;
     } else {
        # Shouldn't happen?
       croak("Cannot open $ENV{ESTAR_DATA} for incoming files.");
     }        
  } elsif ( opendir(TMP, File::Spec->tmpdir() ) ) {
        # fall back on the /tmp directory
        $self->{DATADIR} = File::Spec->tmpdir();
        closedir TMP;
  } else {
     # Shouldn't happen?
     croak("Cannot open any directory for incoming files.");
  }   
  
  # configure the default options
  ${$self->{OPTIONS}}{"ra"}          = undef;
  ${$self->{OPTIONS}}{"dec"}         = undef;
  ${$self->{OPTIONS}}{"name"}        = undef;
  
  ${$self->{OPTIONS}}{"equinox"}     = 2000;
  ${$self->{OPTIONS}}{"x"}           = 10;
  ${$self->{OPTIONS}}{"y"}           = 10;
  ${$self->{OPTIONS}}{"Sky-Survey"}  = "DSS1";
  ${$self->{OPTIONS}}{"mime-type"}   = "download-gif";

  # CONFIGURE FROM ARGUEMENTS
  # -------------------------

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / RA Dec Target Equinox Xsize Ysize Survey Format
                    URL Timeout Proxy / ) {
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

Private function used to make an DSS query. Should not be called directly,
since it does not parse the results. Instead use the querydb() assessor method.

=cut

sub _make_query {
   my $self = shift;

   # grab the user agent
   my $ua = $self->{USERAGENT};

   # clean out the buffer
   $self->{BUFFER} = "";

   # grab the base URL
   my $URL = $self->{QUERY};
   my $options = "";

   # loop round all the options keys and build the query
   foreach my $key ( keys %{$self->{OPTIONS}} ) {
      $options = $options . 
        "&$key=${$self->{OPTIONS}}{$key}" if defined ${$self->{OPTIONS}}{$key};
   }

   # build final query URL
   $URL = $URL . $options;

   # build request
   my $request = new HTTP::Request('GET', $URL);

   # grab page from web
   my $reply = $ua->request($request);

   # declare file name
   my $file_name;
   
   if ( ${$reply}{"_rc"} eq 200 ) {
      if ( ${${$reply}{"_headers"}}{"content-type"} 
            eq "application/octet-stream" ) {
            
         # mangle filename from $ENV and returned unique(?) filename   
         $file_name = ${${$reply}{"_headers"}}{"content-disposition"};
         my $start_index = index( $file_name, q/"/ );
         my $last_index = rindex( $file_name, q/"/ );
         $file_name = substr( $file_name, $start_index+1, 
                              $last_index-$start_index-1);
         
         $file_name = File::Spec->catfile( $self->{DATADIR}, $file_name);                       
         # Open output file
         unless ( open ( FH, ">$file_name" )) {
            croak("Error: Cannont open output file $file_name");
         }   

         # Needed for Windows (yuck!)
         binmode FH;
         
         # Write to output file
         my $length = length(${$reply}{"_content"});
         syswrite( FH, ${$reply}{"_content"}, $length );
         close(FH);
 
      }
   } else {
      croak("Error ${$reply}{_rc}: Failed to establish network connection");
   }
   
   return $file_name;
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
