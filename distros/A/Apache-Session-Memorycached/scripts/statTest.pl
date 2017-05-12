#!/usr/bin/perl -w
###################################################
# this program tests soap service 
# soap server MUST anwers '...... MEMCACHED SOAP OK ......'; 
use Data::Dumper;
use SOAP::Lite; # +trace => 'debug';

$HOST    = "http://my_soap_server/cgi-bin/MemcachedSOAP.cgi";
$NS      = "urn:MemcachedSOAPClass";

my $soap = SOAP::Lite  ->readable(1)  ->uri($NS)  ->proxy($HOST);

my $R = $soap->status();

if( $R->fault ){
  printf( "\nERROR ( %s ) OCCURRED : %s \n", $lasess->faultcode, $lasess->faultstring );
} else {
  my $r  = $R->result;
  print( "$r\n" ); 

}

1;


