#!/usr/bin/perl -w
################################################################
# this program retrieve a memcached session by a soap call 
use Data::Dumper;
use SOAP::Lite; # +trace => 'debug';

$HOST    = "http://my_soap_server/cgi-bin/MemcachedSOAP.cgi";
$NS      = "urn:MemcachedSOAPClass";

$sess    =  shift; # read from the command line

my $soap = SOAP::Lite  ->readable(1)  ->uri($NS)  ->proxy($HOST);

my $lasess = $soap->getSession( $sess );

if( $lasess->fault ){
  printf( "\nERROR ( %s ) OCCURRED : %s \n", $lasess->faultcode, $lasess->faultstring );
} else {
  my %H  = %{$lasess->result};
  my @ks = keys( %{$lasess->result} );
  @ks = sort( @ks );

  print( "\nCLES\t VALEURS\n" ); 

  for( @ks ){ 
    print( "-------------------------------------------------------------------------------\n" );
    my $loc = Dumper( $H{ $_ } );
    print( "$_\t $loc\n" ); 
  }

}
	
print( "\n");
1;


