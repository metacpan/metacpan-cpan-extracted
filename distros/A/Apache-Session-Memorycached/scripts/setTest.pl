#!/usr/bin/perl -w
####################################################################
# this program set a session by a request on soap memcached service
####################################################################
#
use Data::Dumper;
use SOAP::Lite; # +trace => 'debug';

$HOST    = "http://my_soap_server/cgi-bin/MemcachedSOAP.cgi";

$NS      = "urn:MemcachedSOAPClass";

my $soap = SOAP::Lite  ->readable(1)  ->uri($NS)  ->proxy($HOST);

my %SS = (      'APT_APT' => '00000',
	        'APT_GPE' => '11111',
		'APT_IL2' => '22222',
		'APT_RCE' => '33333',
		'APT_ZRB' => '44444',
		'affectation' => '66666',
		'boitier' => '77777',
		'cn' => '88888',
		'codique' => '99999',
		'departement' => 'aaaaa',
		'dgi' => 'bbbbb',
		'dn' => 'ccccc',
		'fonction' => 'ddddd',
		'liste_applications' => 'eeeee',
		'mail' => 'fffff',
		'personaltitle' => 'ggggg',
		'profil_aptera' => 'hhhhh',
		'profil_gap' => 'iiiiii',
		'profil_gdp' => 'jjjjj',
		'profil_geide' => 'kkkkk',
		'profil_ghe' => 'lllllll',
		'profil_rce' => 'mmmm',
		'profil_seq' => 'nnnn',
		'uid' => 'Le Vengeur Masqué' );


my $numses = $soap->setSession( %SS  );

if( $numses->fault ){
    printf( "\nERROR ( %s ) OCCURRED : %s \n", $numses->faultcode, $numses->faultstring );
}

my $NSS = $numses->result; 

my $NSE = $soap->getSession( $NSS );

if( $NSE->fault ){
  printf( "\nERROR ( %s ) OCCURRED : %s \n", $NSE->faultcode, $NSE->faultstring );
} else {
  my %H  = %{$NSE->result};
  my @ks = keys( %{$NSE->result} );
  @ks = sort( @ks );

  print( "\nCLES\t VALEURS\n" ); 

  for( @ks ){ 
    print( "-------------------------------------------------------------------------------\n" );
    my $loc = Dumper( $H{ $_ } );
    print( "$_\t $loc\n" ); 
  }
}

print( "\n");



