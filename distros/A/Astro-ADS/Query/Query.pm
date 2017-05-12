package Astro::ADS::Query;

# ---------------------------------------------------------------------------

#+ 
#  Name:
#    Astro::ADS::Query

#  Purposes:
#    Perl wrapper for the ADS database

#  Language:
#    Perl module

#  Description:
#    This module wraps the ADS online database.

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Query.pm,v 1.24 2011/07/01 bjd Exp $

#  Copyright:
#     Copyright (C) 2001 University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

Astro::ADS::Query - Object definining an prospective ADS query.

=head1 SYNOPSIS

  $query = new Astro::ADS::Query( Authors     => \@authors,
                                  AuthorLogic => $aut_logic,
                                  Objects     => \@objects,
                                  ObjectLogic => $obj_logic, 
                                  Bibcode     => $bibcode,
                                  Proxy       => $proxy,
                                  Timeout     => $timeout,
                                  URL         => $url );

  my $results = $query->querydb();

=head1 DESCRIPTION

Stores information about an prospective ADS query and allows the query to
be made, returning an Astro::ADS::Result object. 

The object will by default pick up the proxy information from the HTTP_PROXY 
and NO_PROXY environment variables, see the LWP::UserAgent documentation for
details.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use warnings;
use vars qw/ $VERSION /;

use LWP::UserAgent;
use Astro::ADS::Result;
use Astro::ADS::Result::Paper;
use Net::Domain qw(hostname hostdomain);
use Carp;

'$Revision: 1.26 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C L A S S   A T T R I B U T E S ------------------------------------------
{
	my $_ads_mirror = 'cdsads.u-strasbg.fr';	# this is the default mirror site
	sub ads_mirror {
		my ($class, $new_mirror) = @_;
		$_ads_mirror = $new_mirror if @_ > 1;
		return $_ads_mirror;
	}
}

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Query.pm,v 1.25 2013/08/06 bjd Exp $
$Id: Query.pm,v 1.24 2009/07/01 bjd Exp $
$Id: Query.pm,v 1.22 2009/05/01 bjd Exp $
$Id: Query.pm,v 1.21 2002/09/23 21:07:49 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $query = new Astro::ADS::Query( Authors     => \@authors,
                                  AuthorLogic => $aut_logic,
                                  Objects     => \@objects,
                                  ObjectLogic => $obj_logic, 
                                  Bibcode     => $bibcode,
                                  Proxy       => $proxy,
                                  Timeout     => $timeout,
                                  URL         => $url );

returns a reference to an ADS query object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { OPTIONS   => {},
                      URL       => undef,
                      QUERY     => undef,
                      FOLLOWUP  => undef,
                      USERAGENT => undef,
                      BUFFER    => undef }, $class;

  # Configure the object
  # does nothing if no arguments supplied
  $block->configure( @_ );

  return $block;

}

# Q U E R Y  M E T H O D S ------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<querydb>

Returns an Astro::ADS::Result object for an inital ADS query

   $results = $query->querydb();

=cut

sub querydb {
  my $self = shift;

  # call the private method to make the actual ADS query
  $self->_make_query();

  # check for failed connect
  return unless defined $self->{BUFFER};

  # return an Astro::ADS::Result object
  return $self->_parse_query();

}

=item B<followup>

Returns an Astro::ADS::Result object for a followup query, e.g. CITATIONS,
normally called using accessor methods from an Astro::ADS::Paper object, but
can be called directly.

   $results = $query->followup( $bibcode, $link_type );

returns undef if no arguements passed. Possible $link_type values are AR,
CITATIONS, REFERENCES and TOC.

=cut

sub followup {
  my $self = shift;

  # return unless we have arguments
  return unless @_;

  my $bibcode = shift;
  my $link_type = shift;

  # call the private method to make the actual ADS query
  $self->_make_followup( $bibcode, $link_type );

  # check for failed connect
  return unless defined $self->{BUFFER};

  # return an Astro::ADS::Result object
  return $self->_parse_query();

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

Return (or set) the current timeout in seconds for the ADS request.

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
   $query->url( "adsabs.harvard.edu" );

if not defined the default URL is cdsads.u-strasbg.fr

As of v1.24, this method sets a class attribute to keep it
consistant across all objects.  Not terribly thread safe, but
at least you know where your query is going.

=cut

sub url {
  my $self = shift;
  my $class = ref($self);	# now re-implemented as a class attribute

  # SETTING URL
  if (@_) { 

    # set the url option 
    my $base_url = shift; 
    $class->ads_mirror( $base_url );
    if( defined $base_url ) {
       $self->{QUERY} = "http://$base_url/cgi-bin/nph-abs_connect?";
       $self->{FOLLOWUP} = "http://$base_url/cgi-bin/nph-ref_query?";
    }
  }

  # RETURNING URL
  return $class->ads_mirror();
}

=item B<agent>

Returns the user agent tag sent by the module to the ADS server.

   $agent_tag = $query->agent();

=cut

sub agent {
  my $self = shift;
  my $string = shift;
  if (defined $string) {
	my $agent = $self->{USERAGENT}->agent();
	$agent =~ s/(\d+)\s(\[.*\]\s*)?\(/$1 [$string] (/;
	return $self->{USERAGENT}->agent($agent);
  }
  else {
    return $self->{USERAGENT}->agent();
  }
}

# O T H E R   M E T H O D S ------------------------------------------------

=item B<Authors>

Return (or set) the current authors defined for the ADS query.

   @authors = $query->authors();
   $first_author = $query->authors();
   $query->authors( \@authors );

if called in a scalar context it will return the first author.

=cut

sub authors {
  my $self = shift;

  # SETTING AUTHORS
  if (@_) { 

    # clear the current author list   
    ${$self->{OPTIONS}}{"author"} = "";

    # grab the new list from the arguements
    my $author_ref = shift;

    # make a local copy to use for regular expressions
    my @author_list = @$author_ref;

    # mutilate it and stuff it into the author list OPTION
    for my $i ( 0 ... $#author_list ) {
       $author_list[$i] =~ s/\s/\+/g;

       if ( $i eq 0 ) {
          ${$self->{OPTIONS}}{"author"} = $author_list[$i];
       } else {
          ${$self->{OPTIONS}}{"author"} = 
               ${$self->{OPTIONS}}{"author"} . ";" . $author_list[$i]; 
       }
    }
  }

  # RETURNING AUTHORS 
  my $author_line =  ${$self->{OPTIONS}}{"author"};
  $author_line =~ s/\+/ /g;
  my @authors = split(/;/, $author_line);

  return wantarray ? @authors : $authors[0];
}

=item B<AuthorLogic>

Return (or set) the logic when dealing with multiple authors for a search,
possible values for this parameter are OR, AND, SIMPLE, BOOL and FULLMATCH.

   $author_logic = $query->authorlogic();
   $query->authorlogic( "AND" );

if called with no arguements, or invalid arguements, then the method will
return the current logic.

=cut

sub authorlogic {
  my $self = shift;

  if (@_) {

     my $logic = shift; 
     if ( $logic eq "OR"   || $logic eq "AND" || $logic eq "SIMPLE" ||
          $logic eq "BOOL" || $logic eq "FULLMATCH" ) {

        # set the new logic
        ${$self->{OPTIONS}}{"aut_logic"} = $logic;
     }
  }

  return ${$self->{OPTIONS}}{"aut_logic"};
}

=item B<Objects>

Return (or set) the current objects defined for the ADS query.

   @objects = $query->objects();
   $query->objects( \@objects );

=cut

sub objects {
  my $self = shift;

  # SETTING AUTHORS
  if (@_) {

    # clear the current object list
    ${$self->{OPTIONS}}{"object"} = "";

    # grab the new list from the arguements
    my $object_ref = shift;

    # make a local copy to use for regular expressions
    my @object_list = @$object_ref;

    # mutilate it and stuff it into the object list OPTION
    for my $i ( 0 ... $#object_list ) {
       $object_list[$i] =~ s/\s/\+/g;

       if ( $i eq 0 ) {
          ${$self->{OPTIONS}}{"object"} = $object_list[$i];
       } else {
          ${$self->{OPTIONS}}{"object"} = 
               ${$self->{OPTIONS}}{"object"} . ";" . $object_list[$i];
       }
    }
  }

  # RETURNING OBJECTS 
  my $object_line =  ${$self->{OPTIONS}}{"object"};
  $object_line =~ s/\+/ /g;
  my @objects = split(/;/, $object_line);

  return @objects;

}

=item B<ObjectLogic>

Return (or set) the logic when dealing with multiple objects in a search,
possible values for this parameter are OR, AND, SIMPLE, BOOL and FULLMATCH.

   $obj_logic = $query->objectlogic();
   $query->objectlogic( "AND" );

if called with no arguements, or invalid arguements, then the method will
return the current logic.

=cut

sub objectlogic {
  my $self = shift;

  if (@_) {

     my $logic = shift; 
     if ( $logic eq "OR"   || $logic eq "AND" || $logic eq "SIMPLE" ||
          $logic eq "BOOL" || $logic eq "FULLMATCH" ) {

        # set the new logic
        ${$self->{OPTIONS}}{"obj_logic"} = $logic;
     }
  }

  return ${$self->{OPTIONS}}{"obj_logic"};
}

=item B<Bibcode>

Return (or set) the current bibcode used for the ADS query.

   $bibcode = $query->bibcode();
   $query->bibcode( "1996PhDT........42J" );

=cut

sub bibcode {
  my $self = shift;

  # SETTING BIBCODE
  if (@_) { 

    # set the bibcode option  
    ${$self->{OPTIONS}}{"bibcode"} = shift;
  }

  # RETURNING BIBCODE
  return ${$self->{OPTIONS}}{"bibcode"};
}


=item B<startmonth>

Return (or set) the current starting month of the ADS query.

   $start_month = $query->startmonth();
   $query->startmonth( "01" );

=cut

sub startmonth {
  my $self = shift;

  # SETTING STARTING MONTH
  if (@_) { 

    # set the starting month option  
    ${$self->{OPTIONS}}{"start_mon"} = shift;
  }

  # RETURNING STARTING MONTH
  return ${$self->{OPTIONS}}{"start_mon"};

}

=item B<endmonth>

Return (or set) the current end month of the ADS query.

   $end_month = $query->endmonth();
   $query->endmonth( "12" );

=cut

sub endmonth {
  my $self = shift;

  # SETTING END MONTH
  if (@_) { 

    # set the end month option  
    ${$self->{OPTIONS}}{"end_mon"} = shift;
  }

  # RETURNING END MONTH
  return ${$self->{OPTIONS}}{"end_mon"};

}

=item B<startyear>

Return (or set) the current starting year of the ADS query.

   $start_year = $query->startyear();
   $query->start_year( "2001" );

=cut

sub startyear {
  my $self = shift;

  # SETTING START YEAR
  if (@_) { 

    # set the starting year option  
    ${$self->{OPTIONS}}{"start_year"} = shift;
  }

  # RETURNING START YEAR
  return ${$self->{OPTIONS}}{"start_year"};

}

=item B<endyear>

Return (or set) the current end year of the ADS query.

   $end_year = $query->endyear();
   $query->end_year( "2002" );

=cut

sub endyear {
  my $self = shift;

  # SETTING END YEAR
  if (@_) { 

    # set the end year option  
    ${$self->{OPTIONS}}{"end_year"} = shift;
  }

  # RETURNING END YEAR
  return ${$self->{OPTIONS}}{"end_year"};

}

=item B<journal>

Return (or set) whether refereed, non-refereed (OTHER) or all bibilographic sources (ALL) are returned.

   $query->journal( "REFEREED" );
   $query->journal( "OTHER" );
   $query->journal( "ALL" );
   
   $journals = $query->journal();

the default is ALL bibilographic sources

=cut

sub journal {
  my $self = shift;

  # SETTING END YEAR
  if (@_) { 

    my $source = shift;
    
    if ( $source eq "REFEREED" ) {
       ${$self->{OPTIONS}}{"jou_pick"} = "NO";
    } elsif ( $source eq "OTHER" ) {
       ${$self->{OPTIONS}}{"jou_pick"} = "EXCL";
    } else {
       ${$self->{OPTIONS}}{"jou_pick"} = "ALL";
    }  

  }

  # RETURNING END YEAR
  return ${$self->{OPTIONS}}{"jou_pick"};

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
  my $class = ref($self);

  # CONFIGURE DEFAULTS
  # ------------------

  # define the default base URL
  my $default_url = $class->ads_mirror();
  
  # define the query URLs
  $self->{QUERY} = "http://$default_url/cgi-bin/nph-abs_connect?";
  $self->{FOLLOWUP} = "http://$default_url/cgi-bin/nph-ref_query?";

   
  # Setup the LWP::UserAgent
  my $HOST = hostname();
  my $DOMAIN = hostdomain();
  $self->{USERAGENT} = new LWP::UserAgent( timeout => 30 ); 
  $self->{USERAGENT}->agent("Astro::ADS/$VERSION ($HOST.$DOMAIN)");

  # Grab Proxy details from local environment
  $self->{USERAGENT}->env_proxy();

  # configure the default options
  ${$self->{OPTIONS}}{"db_key"}           = "AST";
  ${$self->{OPTIONS}}{"sim_query"}        = "YES";
  ${$self->{OPTIONS}}{"aut_xct"}          = "NO";
  ${$self->{OPTIONS}}{"aut_logic"}        = "OR";
  ${$self->{OPTIONS}}{"obj_logic"}        = "OR";
  ${$self->{OPTIONS}}{"author"}           = "";
  ${$self->{OPTIONS}}{"object"}           = "";
  ${$self->{OPTIONS}}{"keyword"}          = "";
  ${$self->{OPTIONS}}{"start_mon"}        = "";
  ${$self->{OPTIONS}}{"start_year"}       = "";
  ${$self->{OPTIONS}}{"end_mon"}          = "";
  ${$self->{OPTIONS}}{"end_year"}         = "";
  ${$self->{OPTIONS}}{"ttl_logic"}        = "OR";
  ${$self->{OPTIONS}}{"title"}            = "";
  ${$self->{OPTIONS}}{"txt_logic"}        = "OR";
  ${$self->{OPTIONS}}{"text"}             = "";
  ${$self->{OPTIONS}}{"nr_to_return"}     = "100";
  ${$self->{OPTIONS}}{"start_nr"}         = "1";
  ${$self->{OPTIONS}}{"start_entry_day"}  = "";
  ${$self->{OPTIONS}}{"start_entry_mon"}  = "";
  ${$self->{OPTIONS}}{"start_entry_year"} = "";
  ${$self->{OPTIONS}}{"min_score"}        = "";
  ${$self->{OPTIONS}}{"jou_pick"}         = "ALL";
  ${$self->{OPTIONS}}{"ref_stems"}        = "";
  ${$self->{OPTIONS}}{"data_and"}         = "ALL";
  ${$self->{OPTIONS}}{"group_and"}        = "ALL";
  ${$self->{OPTIONS}}{"sort"}             = "SCORE";
  ${$self->{OPTIONS}}{"aut_syn"}          = "YES";
  ${$self->{OPTIONS}}{"ttl_syn"}          = "YES";
  ${$self->{OPTIONS}}{"txt_syn"}          = "YES";
  ${$self->{OPTIONS}}{"aut_wt"}           = "1.0";
  ${$self->{OPTIONS}}{"obj_wt"}           = "1.0";
  ${$self->{OPTIONS}}{"ttl_wt"}           = "0.3";
  ${$self->{OPTIONS}}{"txt_wt"}           = "3.0";
  ${$self->{OPTIONS}}{"aut_wgt"}          = "YES";
  ${$self->{OPTIONS}}{"obj_wgt"}          = "YES";
  ${$self->{OPTIONS}}{"ttl_wgt"}          = "YES";
  ${$self->{OPTIONS}}{"txt_wgt"}          = "YES";
  ${$self->{OPTIONS}}{"ttl_sco"}          = "YES";
  ${$self->{OPTIONS}}{"txt_sco"}          = "YES";
  ${$self->{OPTIONS}}{"version"}          = "1";
  ${$self->{OPTIONS}}{"bibcode"}          = "";

  # Set the data_type option to PORTABLE so our regular expressions work!
  # Set the return format to LONG so we get full abstracts!
  ${$self->{OPTIONS}}{"data_type"}        = "PORTABLE";
  ${$self->{OPTIONS}}{"return_fmt"}       = "LONG";

  # CONFIGURE FROM ARGUEMENTS
  # -------------------------

  # return unless we have arguments
  return unless @_;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / Authors AuthorLogic Objects ObjectLogic Bibcode 
                    StartMonth EndMonth StartYear EndYear Journal
                    Proxy Timeout URL/ ) {
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

Private function used to make an ADS query. Should not be called directly,
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
      # some bibcodes have & and needs to be made "web safe"
      my $websafe_option = ${$self->{OPTIONS}}{$key};
      $websafe_option =~ s/&/%26/g;
      $options = $options . "&$key=$websafe_option";

   }

   # build final query URL
   $URL = $URL . $options;
   
   # build request
   my $request = new HTTP::Request('GET', $URL);

   # grab page from web
   my $reply = $ua->request($request);

   if ( ${$reply}{"_rc"} eq 200 ) {
   
      # stuff the page contents into the buffer
      $self->{BUFFER} = ${$reply}{"_content"};
      
   } elsif ( ${$reply}{"_rc"} eq 500 ) {
   
      # we may have a network unreachable, or we may have a no reference
      # selected error returned by ADS (go figure)

      $self->{BUFFER} = ${$reply}{"_content"};
      my @buffer = split( /\n/,$self->{BUFFER});
      chomp @buffer;
            
      # assume we have an error unless we can prove otherwise
      my $error_flag = 1;
      
      foreach my $line ( 0 ... $#buffer ) {
          if( $buffer[$line] =~ "No reference selected" ) {
       
             # increment the counter and drop out of the loop
             $line = $#buffer;
             $error_flag = 0;
          }      
      }
      
      # we definately have an error
      if( $error_flag ) { 
         $self->{BUFFER} = undef;
		 my $proxy_string = undef;
		 if ($proxy_string = $ua->proxy('http')) { substr($proxy_string, 0, 0) = ' using proxy '; }
		 else { $proxy_string = ' (no proxy)'; }
         croak("Error ${$reply}{_rc}: Failed to establish network connection to $URL",
				$proxy_string, "\n");
      }
      
   } else {
      $self->{BUFFER} = undef;
	  my $proxy_string = undef;
	  if ($proxy_string = $ua->proxy('http')) { substr($proxy_string, 0, 0) = ' using proxy '; }
	  else { $proxy_string = ' (no proxy)'; }
      croak("Error ${$reply}{_rc}: Failed to establish network connection to $URL",
				$proxy_string, "\n");
   }
   
   
}

=item B<_make_followup>

Private function used to make a followup ADS query, e.g. REFERNCES, called
from the followup() assessor method. Should not be called directly.

=cut

sub _make_followup {
   my $self = shift;

   # grab the user agent
   my $ua = $self->{USERAGENT};

   # clean out the buffer
   $self->{BUFFER} = "";

   # grab the base URL
   my $URL = $self->{FOLLOWUP};

   # which paper?
   my $bibcode = shift;
   $bibcode =~ s/&/%26/g;	# make ampersands websafe

   # which followup?
   my $refs = shift;

   # which database?
   my $db_key = ${$self->{OPTIONS}}{"db_key"};
   my $data_type = ${$self->{OPTIONS}}{"data_type"};
   my $fmt = ${$self->{OPTIONS}}{"return_fmt"};

   # build the final query URL
   $URL = $URL . "bibcode=$bibcode&refs=$refs&db_key=$db_key&data_type=$data_type&return_fmt=$fmt"; 

   # build request
   my $request = new HTTP::Request('GET', $URL);

   # grab page from web
   my $reply = $ua->request($request);

   if ( ${$reply}{"_rc"} eq 200 ) {
      # stuff the page contents into the buffer
      $self->{BUFFER} = ${$reply}{"_content"};
   } else {
      $self->{BUFFER} = undef;
	  my $proxy_string = undef;
	  if ($proxy_string = $ua->proxy('http')) { substr($proxy_string, 0, 0) = ' using proxy '; }
	  else { $proxy_string = ' (no proxy) '; }
      croak("Error ${$reply}{_rc}: Failed to establish network connection to $URL" .
			$proxy_string . $self->{BUFFER} ."\n");
   }
}

=item B<_parse_query>

Private function used to parse the results returned in an ADS query. Should 
not be called directly. Instead use the querydb() assessor method to make and
parse the results.

=cut

sub _parse_query {
  my $self = shift;

  # get a local copy of the current BUFFER
  my @buffer = split( /\n/,$self->{BUFFER});
  chomp @buffer;

  # create an Astro::ADS::Result object to hold the search results
  my $result = new Astro::ADS::Result();

  # create a temporary object to hold papers
  my $paper;

  # loop round the returned buffer and stuff the contents into Paper objects
  my ( $next, $counter );
  $next = $counter = 0;
  foreach my $line ( 0 ... $#buffer ) {

     #     R     Bibcode
     #     T     Title
     #     A     Author List
     #     F     Affiliations
     #     J     Journal Reference
     #     D     Publication Date
     #     K     Keywords
     #     G     Origin
     #     I     Outbound Links
     #     U     Document URL
     #     O     Object name
     #     B     Abstract
     #     S     Score

     # NO ABSTRACTS
     if( $buffer[$line] =~ "Retrieved 0 abstracts" ) {

        # increment the counter and drop out of the loop
        $line = $#buffer;
        
     }
     
     # NO ABSTRACT (HTML version)
     if( $buffer[$line] =~ "No reference selected" ) {
       
       # increment the counter and drop out of the loop
        $line = $#buffer;
     }
     
     # NEW PAPER
     if( substr( $buffer[$line], 0, 2 ) eq "%R" ) {

        $counter = $line;
        my $tag = substr( $buffer[$counter], 1, 1 );

        # grab the bibcode
        my $bibcode = substr( $buffer[$counter], 2 );
        $bibcode =~ s/\s+//g;

        # New Astro::ADS::Result::Paper object
        $paper = new Astro::ADS::Result::Paper( Bibcode => $bibcode );

        $counter++;

        # LOOP THROUGH PAPER
        my ( @title, @authors, @affil, @journal, @pubdate, @keywords, 
             @origin, @links, @url, @object, @abstract, @score );
        while ( $counter <= $#buffer &&
                substr( $buffer[$counter], 0, 2 ) ne "%R" ) {


           # grab the tags
           if( substr( $buffer[$counter], 0, 1 ) eq "%" ) {
              $tag = substr( $buffer[$counter], 1, 1 );
           }

           # ckeck for each tag and stuff the contents into the paper object

           # TITLE
           # -----
           if( $tag eq "T" ) {

              #do we have the start of an title block?
              if ( substr( $buffer[$counter], 0, 1 ) eq "%") {

                 # push the end of line substring onto array
                 push ( @title, substr( $buffer[$counter], 3 ) );

              } else {

                 # push the entire line onto the array
                 push (@title, $buffer[$counter] );

              }
           }

           # AUTHORS
           # -------
           if( $tag eq "A" ) {

              #do we have the start of an author block?
              if ( substr( $buffer[$counter], 0, 1 ) eq "%") {

                 # push the end of line substring onto array
                 push ( @authors, substr( $buffer[$counter], 3 ) );

              } else {

                 # push the entire line onto the array
                 push (@authors, $buffer[$counter] );

              }
           }

           # AFFILIATION
           # -----------
           if( $tag eq "F" ) {

              #do we have the start of an affil block?
              if ( substr( $buffer[$counter], 0, 1 ) eq "%") {

                 # push the end of line substring onto array
                 push ( @affil, substr( $buffer[$counter], 3 ) );

              } else {

                 # push the entire line onto the array
                 push (@affil, $buffer[$counter] );

              }
           }

           # JOURNAL REF
           # -----------
           if( $tag eq "J" ) {

              #do we have the start of an journal block?
              if ( substr( $buffer[$counter], 0, 1 ) eq "%") {

                 # push the end of line substring onto array
                 push ( @journal, substr( $buffer[$counter], 3 ) );

              } else {

                 # push the entire line onto the array
                 push (@journal, $buffer[$counter] );

              }
           }

           # PUBLICATION DATE
           # ----------------
           if( $tag eq "D" ) {

              #do we have the start of an publication date block?
              if ( substr( $buffer[$counter], 0, 1 ) eq "%") {

                 # push the end of line substring onto array
                 push ( @pubdate, substr( $buffer[$counter], 3 ) );

              } else {

                 # push the entire line onto the array
                 push (@pubdate, $buffer[$counter] );

              }
           }

           # KEYWORDS
           # --------
           if( $tag eq "K" ) {

              #do we have the start of an keyword block?
              if ( substr( $buffer[$counter], 0, 1 ) eq "%") {

                 # push the end of line substring onto array
                 push ( @keywords, substr( $buffer[$counter], 3 ) );

              } else {

                 # push the entire line onto the array
                 push (@keywords, $buffer[$counter] );

              }
           }

           # ORIGIN
           # ------
           if( $tag eq "G" ) {

              #do we have the start of an origin block?
              if ( substr( $buffer[$counter], 0, 1 ) eq "%") {

                 # push the end of line substring onto array
                 push ( @origin, substr( $buffer[$counter], 3 ) );

              } else {

                 # push the entire line onto the array
                 push (@origin, $buffer[$counter] );

              }
           }

           # LINKS
           # -----
           if( $tag eq "I" ) {

              #do we have the start of an author block?
              if ( substr( $buffer[$counter], 0, 1 ) eq "%") {

                 # push the end of line substring onto array
                 push ( @links, substr( $buffer[$counter], 3 ) );

              } else {

                 # push the entire line onto the array
                 push (@links, $buffer[$counter] );

              }
           }

           # URL
           # ---
           if( $tag eq "U" ) {

              #do we have the start of an URL block?
              if ( substr( $buffer[$counter], 0, 1 ) eq "%") {

                 # push the end of line substring onto array
                 push ( @url, substr( $buffer[$counter], 3 ) );

              } else {

                 # push the entire line onto the array
                 push (@url, $buffer[$counter] );

              }
           }

           # OBJECT
           # ------
           if( $tag eq "O" ) {

              #do we have the start of an title block?
              if ( substr( $buffer[$counter], 0, 1 ) eq "%") {

                 # push the end of line substring onto array
                 push ( @object, substr( $buffer[$counter], 3 ) );

              } else {

                 # push the entire line onto the array
                 push (@object, $buffer[$counter] );

              }
           }

           # ABSTRACT
           # --------
           if( $tag eq "B" ) {

              #do we have the start of an title block?
              if ( substr( $buffer[$counter], 0, 1 ) eq "%") {

                 # push the end of line substring onto array
                 push ( @abstract, substr( $buffer[$counter], 3 ) );

              } else {

                 # push the entire line onto the array
                 push (@abstract, $buffer[$counter] );

              }
           }

           # SCORE
           # -----
           if( $tag eq "S" ) {

              #do we have the start of an title block?
              if ( substr( $buffer[$counter], 0, 1 ) eq "%") {

                 # push the end of line substring onto array
                 push ( @score, substr( $buffer[$counter], 3 ) );

              } else {

                 # push the entire line onto the array
                 push (@score, $buffer[$counter] );

              }
           }


           # set the next paper increment
           $next = $counter;
           # increment the line counter
           $counter++;

        }

        # PUSH TITLE INTO PAPER OBJECT
        # ----------------------------
        chomp @title;
        my $title_line = "";
        for my $i ( 0 ... $#title ) {
           # drop it onto one line
           $title_line = $title_line . $title[$i];
        }
        $paper->title( $title_line ) if defined $title[0];

        # PUSH AUTHORS INTO PAPER OBJECT
        # ------------------------------
        chomp @authors;
        my $author_line = "";
        for my $i ( 0 ... $#authors ) {
           # drop it onto one line
           $author_line = $author_line . $authors[$i];
        }
        # get rid of leading spaces before author names
        $author_line =~ s/;\s+/;/g;

        my @paper_authors = split( /;/, $author_line );
        $paper->authors( \@paper_authors ) if defined $authors[0];

        # PUSH AFFILIATION INTO PAPER OBJECT
        # ----------------------------------
        chomp @affil;
        my $affil_line = "";
        for my $i ( 0 ... $#affil ) {
           # drop it onto one line
           $affil_line = $affil_line . $affil[$i];
        }
        # grab each affiliation from its brackets
        $affil_line =~ s/\w\w\(//g;

        my @paper_affil = split( /\), /, $affil_line );
        $paper->affil( \@paper_affil ) if defined $affil[0];

        # PUSH JOURNAL INTO PAPER OBJECT
        # ------------------------------
        chomp @journal;
        my $journal_ref = "";
        for my $i ( 0 ... $#journal ) {
           # drop it onto one line
           $journal_ref = $journal_ref . $journal[$i];
        }
        $paper->journal( $journal_ref ) if defined $journal[0];

        # PUSH PUB DATE INTO PAPER OBJECT
        # -------------------------------
        chomp @pubdate;
        my $pub_date = "";
        for my $i ( 0 ... $#pubdate ) {
           # drop it onto one line
           $pub_date = $pub_date . $pubdate[$i];
        }
        $paper->published( $pub_date ) if defined $pubdate[0];

        # PUSH KEYWORDS INTO PAPER OBJECT
        # -------------------------------
        chomp @keywords;
        my $key_line = "";
        for my $i ( 0 ... $#keywords ) {
           # drop it onto one line
           $key_line = $key_line . $keywords[$i];
        }
        # get rid of excess spaces
        $key_line =~ s/, /,/g;

        my @paper_keys = split( /,/, $key_line );
        $paper->keywords( \@paper_keys ) if defined $keywords[0];

        # PUSH ORIGIN INTO PAPER OBJECT
        # -----------------------------
        chomp @origin;
        my $origin_line = "";
        for my $i ( 0 ... $#origin) {
           # drop it onto one line
           $origin_line = $origin_line . $origin[$i];
        }
        $paper->origin( $origin_line ) if defined $origin[0];

        # PUSH LINKS INTO PAPER OBJECT
        # ----------------------------
        chomp @links;
        my $links_line = "";
        for my $i ( 0 ... $#links ) {
           # drop it onto one line
           $links_line = $links_line . $links[$i];
        }
        # annoying complex reg exp to get rid of formatting
        $links_line =~ s/:.*?;\s*/;/g;

        my @paper_links = split( /;/, $links_line );
        $paper->links( \@paper_links ) if defined $links[0];

        # PUSH URL INTO PAPER OBJECT
        # --------------------------
        chomp @url;
        my $url_line = "";
        for my $i ( 0 ... $#url ) {
           # drop it onto one line
           $url_line = $url_line . $url[$i];
        }
        # get rid of trailing spaces
        $url_line =~ s/\s+$//;
        $paper->url( $url_line ) if defined $url[0];

        # PUSH OBJECT INTO PAPER OBJECT
        # -----------------------------
        chomp @object;
        my $object_line = "";
        for my $i ( 0 ... $#object ) {
           # drop it onto one line
           $object_line = $object_line . $object[$i];
        }
        $paper->object( $object_line ) if defined $object[0];

        # PUSH ABSTRACT INTO PAPER OBJECT
        # -------------------------------
        chomp @abstract;
        for my $i ( 0 ... $#abstract ) {
           # get rid of trailing spaces
           $abstract[$i] =~ s/\s+$//;
        }
        $paper->abstract( \@abstract ) if defined $abstract[0];

        # PUSH SCORE INTO PAPER OBJECT
        # ----------------------------
        chomp @score;
        my $score_line = "";
        for my $i ( 0 ... $#score ) {
           # drop it onto one line
           $score_line = $score_line . $score[$i];
        }
        $paper->score( $score_line ) if defined $score[0];


     }

     # Increment the line counter to the correct index for the next paper
     $line += $next;

     # Push the new paper onto the Astro::ADS::Result object
     # -----------------------------------------------------
     $result->pushpaper($paper) if defined $paper;
     $paper = undef;

   }

   # return an Astro::ADS::Result object, or undef if no abstracts returned
   return $result;

}

=item B<_dump_raw>

Private function for debugging and other testing purposes. It will return
the raw output of the last ADS query made using querydb().

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

=head1 BUGS

=over

=item #35645 filed at rt.cpan.org (Ampersands)

Older versions can't handle ampersands in the bibcode, such as A&A for Astronomy & Astrophysics.
Fixed for queries in 1.22 - 5/2009.
Fixed for references in 1.23 - Boyd Duffee E<lt>b dot duffee at isc dot keele dot ac dot ukE<gt>, 7/2011.

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
