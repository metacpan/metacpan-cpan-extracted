#!/usr/bin/perl -w

#
# Running the query filter in an ALVIS environment.
# Reads all parameters from alvis.cnf so just needs directory
# to target.  These are:
#     QF_PORT  YAZ_PORT  QF_TEXT
# Also tries to read resource files from
#   <ALVISdirectory>/resources
# Note this *only responds to requests locally, i.e.,
# the incoming URL must be "http://localhost....".


our $VERSION = "0.1";

use Alvis::QueryFilter;
use LWP::UserAgent;
use HTTP::Daemon;
use HTTP::Status;
use HTTP::Response;

my $options;
my $testquery;
my $verbose = 0;
if ( $ARGV[0] =~ /^--/ ) {
  $options = shift();
}

die("Usage: $0" .
    " <ALVISdirectory>") if @ARGV != 1;

my $ALVISHOME = shift @ARGV;
my $QF_PORT;
my $YAZ_PORT;
my $QF_TEXT = "text";
my $F_BN = "$ALVISHOME/resources";

&readargs();

if ( !$QF_PORT || ! $YAZ_PORT ) {
  print STDERR "Cannot locate ports in alvis.cnf\n";
  exit(1);
}

#  here are the expected resources files
#
my $lemma_dict_f="${F_BN}/lemmas";
my $term_dict_f="${F_BN}/terms";
my $NE_dict_f="${F_BN}/NEs";
my $typing_rules_f="${F_BN}/types";
my $onto_nodes_f="${F_BN}/onto_nodes";
my $onto_mapping_f="${F_BN}/onto_paths";

#  method to standardise terms and named entities
#            lower case, ignore space and '-'
sub tcanonise {
  $_ = shift();
  s/\s+//g;
  s/\-//g;
  $_ = lc($_);
  return $_;
}
sub ncanonise {
  $_ = shift();
  s/\s//g;
  if ( ! /[0-9]/ ) {
    s/[\-_]//g;
  }
  return $_;
}

sub cleanspaces() {
  $_ = shift();
  s/\s+/ /g;
  s/^ //g;
  s/ $//g;
  return $_;
}

sub checkdict() {
  my $f = shift();
  my $canonise = shift();
  my %dict = ();
  my %line = ();

  if (!defined(open(F,"<:utf8",$f)))
    {
      return undef;
    }

  while (my $l=<F>)
    {
      chomp $l;
      my ($form,$can)=split(/\t/,$l,-1);
      $form = &cleanspaces($form);
      $can = &cleanspaces($can);
      $line{$can} .= $l . "\n";
      my $cf = &$canonise($form);
      if ( defined($dict{$cf}) && $dict{$cf} ne $can ) {
	print STDERR "Item of form '$form' has canonical form '$can'\n"
	  . "   but maps to the another canonical form '$dict{$cf}'\n"
	    . "Relevent items: \n";
	print STDERR $line{$can};
	print STDERR $line{$dict{$cf}};
	print STDERR "\n";
      }
      $dict{$cf}=$can;
    }
  close(F);
}

if ( defined($options) && $options eq "--testdict" ) {
  print STDERR "======= checking $term_dict_f =======\n";
  &checkdict($term_dict_f,\&tcanonise);
  print STDERR "======= checking $NE_dict_f =======\n";
  &checkdict($NE_dict_f,\&ncanonise);
  exit(0);
}
if ( defined($options) ) {
  if ( $options eq "--verbose" ) {
     $verbose = 1;
  } elsif ( $options eq "--testquery" ) {
     $testquery = 1;
  } else {
     print STDERR "Unknown option $options\n";
     exit(1);
  }
}

$Alvis::QueryFilter::verbose = $verbose;
my $QF=Alvis::QueryFilter->new();
if (!defined($QF))
{
    die("Unable to instantiate QueryFilter.");
}

if ( 0 ) {
  #   cannot figure out how to get HTTP::Daemon
  #   to respond to remote requests, so this server *must*
  #   always be accessed locally
  open(S,"hostname --fqdn |");
  $host = <S>;
  close(S);
  if ( ! $host ) {
    die("Unable to get fully qualified domain name.");
  }
  print STDERR "Setting host to $host\n";
}

$QF->set_text_fields($QF_TEXT);
$QF->set_canon(\&tcanonise,\&ncanonise);

if (!$QF->read_dicts($lemma_dict_f,
		     $term_dict_f,
		     $NE_dict_f,
		     $typing_rules_f,
		     $onto_nodes_f,
		     $onto_mapping_f))
{
     die("Reading the dictionaries failed.");
}

my $daemon = new HTTP::Daemon
  agent => "ALVIS Zebra Filter/$VERSION",
  Proto => "tcp",
  LocalAddr => 'localhost',
  # PeerAddr => $host,
  LocalPort =>  $QF_PORT;
if ( ! $daemon ) {
  print STDERR "Starting daemon at port=$QF_PORT failed\n";
  exit(1);
}

#
#  UI ----> Zebra
#
while (my $c = $daemon->accept) {
  while (my $r = $c->get_request) {
    if ($r->method eq 'GET' ) {
      #     && $r->url =~ /\?version=1.1\&operation=searchRetrieve\&/ ) {
      # remember, this is *not* recommened practice :-)
      # print "URI: " . $r->uri . "\n";
      # print "URL: " . $r->url . "\n";
      # print "STRING: " . $r->as_string . "\n";
      # print "CONTENT: " . $r->content . "\n";
      $result = &processSRU($r->url);
      $c->send_response($result);
    } else {
      print STDERR "Bad request: " . $r->url . " \n";
      $c->send_error(RC_FORBIDDEN)
    }
  }
  $c->close;
  undef($c);
}
print STDERR "SRU query transformer shut down\n";
exit(1); 

sub processSRU() {
  my $SRU = shift();

  if ( $verbose ) {
    print STDERR "SRU: $SRU\n\n";
  }
  
  my $ToZebra=$QF->UI2Zebra($SRU);
  if (!defined($ToZebra)) {
    # print STDERR "Expansion failed: ".$QF->errmsg();
    $ToZebra = "";
  }

  # $ToZebra=~s/%([a-f0-9][a-f0-9])/pack("C", hex($1))/eig;
  # print STDERR " ----> Zebra: \n\n$actual\n\n$ToZebra\n\n";
  
  print STDERR "QueryFilter [" . localtime()
    . "] URL: http://localhost:$YAZ_PORT$ToZebra\n";

  my $response;
  if ( $testquery) {
    my $content = "<zs:searchRetrieveResponse>\n<zs:version>1.1</zs:version>\n"
      . " <zs:numberOfRecords/><zs:records><zs:record>\n"
      . "  <zs:recordSchema>D9.1</zs:recordSchema>\n"
      . "  <zs:recordPacking>xml</zs:recordPacking>\n"
      . "   <zs:recordData><document/></zs:recordData>\n"
      . "   <zs:recordPosition>1</zs:recordPosition>\n"
      . "  </zs:record></zs:records>\n"
	. "</zs:searchRetrieveResponse>\n";
    $response = HTTP::Response->new(200, "", undef, $content );
  } else {
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;
    $response = $ua->get("http://localhost:$YAZ_PORT$ToZebra");
  }
  
  # print STDERR "MSG:  " . $response->message ."\n";

  if ( ! $response->is_success ) {
    #   pass on error return from Zebra
    return $response;
  }
  
  #
  # Zebra ----> UI
  #
  
  if ( ! $QF->Zebra2UI( $response->content_ref ) ) {
    print STDERR "Unable to insert query for $SRU\n";
  }

  if ( $verbose && ${$response->content_ref} =~
       /(<zs:extraResponseData>.*?<\/zs:extraResponseData>)/ms) {
    print STDERR "UI XML:\n$1\n"; 
  } 
  
  return $response;
}

sub readargs() {
  if ( ! open(A,"<$ALVISHOME/alvis.cnf") ) {
    print STDERR "No alvis.cnf: $!\n";
    exit(1);
  }
  while ( ($_=<A>) ) {
    chomp();
    s/#.*//;
    s/^\s+//;
    if ( /^QF_TEXT=\s*(\S.*)/ ) {
      print STDERR "Setting text fields to $1\n";
      $QF_TEXT = $1;   
    }
    if ( /^QF_PORT=\s*([0-9]+)/ ) {
      $QF_PORT = int($1);   
      print STDERR "Setting filter QF_PORT to $QF_PORT\n";
    }
    if ( /^YAZ_PORT=\s*([0-9]+)/ ) {
      $YAZ_PORT = int($1);   
      print STDERR "Setting YAZ PORT to $YAZ_PORT\n";
    }
  }
  close(A);
}

=pod

=head1 NAME
    
  run_QF.pl -- simple HTTP server for query filtering of SRU

=head1 SYNOPSIS
    
  run_QF.pl [--testdict] [--testquery] [--verbose] <AlvisDir>

=head1 DESCRIPTION

B<--testdict>   Load up dictionaries, do simple checking, then quit.

B<--testquery>   Transform queries and return response without forwarding query to a real SRU server.

B<--verbose>   Some additional trace data provided.

This is a simple SRU query filter built using HTTP::Daemon.  All configuration data is read from the ALVIS configuration file at <AlvisDir>/alvis.cnf.  Error messages and a simple URL trail go to stderr.  The linguistic resources used by
Alvis::Query filter are located in <AlvisDir>/resources.

It is intended to be copied and modified for any application.

=head1 CONFIGURATION

B<QF_PORT>    Port number for this server.

B<QF_TEXT>    Space delimited list of fields that text matches go to.

B<YAZ_PORT>    Port number to forward transformed SRU queries to.

=head1 DATA

All resources have one entry per line, and each entry has fields that are tab delimited.  Spacing within a field should be standardised to single spaces.  The "types" file should be non-existant if named entities are also listed as having ontology nodes.

<AlvisDir>/resources/lemmas :   Lists (text-occurrence,lemma-form) for lemmatising words.

<AlvisDir>/resources/NEs :   Lists (text-occurrence,canonical-form) for matching named entities.

<AlvisDir>/resources/onto_nodes :    Lists (canonical-form,ontology-node) for matching lemmas, terms and named entities that are located in the ontology.

<AlvisDir>/resources/onto_paths :  Lists (ontology-node,ontology-path) giving fully expanded path for each node.

<AlvisDir>/resources/terms :   Lists (text-occurence,canonical-form) for matching terms.

<AlvisDir>/resources/types :   Lists (canonical-form,type) for named entities.  Types are short text items (e.g., 'species', 'company', 'person') used to categorise named entities when no ontology is in use.

Entries in "NEs" and "terms" are applied as rules to query words, with longest match applying first.  Once all these are done, the typing or ontology forms are applied.

Resources are best manipulated and iported/exported as a
single XML file using the routines of
B<zebractl>(1).

=head1 SEE ALSO

B<Alvis::QueryFilter>(3), 
B<zebractl>(1), 
B<zebrad>(1), 
B<HTTP::Daemon>(3).

See http://www.alvis.info/alvis/Architecture_2fFormats#queryfilter 
for sample use, the XML formats and the schema.
See http://www.alvis.info/alvis/Architecture_2fFormats#filterresources
for description of the linguistic resources and an XML Schema.

=head1 AUTHOR

Kimmo Valtonen, Wray Buntine

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Kimmo Valtonen, Wray Buntine

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut
