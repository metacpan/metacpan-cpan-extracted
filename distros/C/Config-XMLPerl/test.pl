#########################

###use Data::Dumper ; print Dumper(  ) ;

use Test;
BEGIN { plan tests => 11 } ;

use Config::XMLPerl qw(config_load) ;

use strict ;
use warnings qw'all' ;

#########################
{

  my $config = config_load(q`
  <config server="domain.foo" port="80">
    DB => { user => "foo" , pass => "123" , host => "db.domain.foo"}
<text>
this is 
a text
content
</text>

    <.wild crazy=123 href=http://www.com unclose>

  </config>
  `) ;
  
  ##use Data::Dumper ; print Dumper( $config->tree ) ;
  
  ok( $config->{server} , 'domain.foo' ) ;
  ok( $config->{port} , 80 ) ;

  ok( $config->{DB} ) ;
  ok( $config->{DB}{user} , "foo" ) ;
  ok( $config->{DB}{pass} , "123" ) ;
  ok( $config->{DB}{host} , "db.domain.foo" ) ;  
  
  ok( $config->{text} , q`
this is 
a text
content
`) ;
  
  ok( $config->{'.wild'} ) ;
  ok( $config->{'.wild'}{crazy} , 123 ) ;
  ok( $config->{'.wild'}{href} , 'http://www.com' ) ;
  ok( $config->{'.wild'}{unclose} ) ;
  
}
#########################

print "\nThe End! By!\n" ;

1 ;


