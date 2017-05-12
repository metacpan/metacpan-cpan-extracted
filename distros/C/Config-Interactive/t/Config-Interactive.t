use Test::More tests => 12;
 
use_ok('Config::Interactive');
use   Config::Interactive;
 
my %CONF_VALID = (PORT => '^\d+$', DB_NAME => '^\w+$', DB_DRIVER => '^SQLite|mysql|Pg$');

my %CONF_KEYS = (PORT => ' enter any number  and press Enter ');

  
  my $cfg = "./t/data/test.conf";
  my $conf =  undef;
 # 2 
  eval {
     $conf = new Config::Interactive({  file  => $cfg }) 
  };
  ok(  !$@ && $conf , "Config::Interactive create object");
  $@ = undef;

 # 3 
 my $hashref1 =  $conf->parse; 
 ok($hashref1  , " Config::Interactive parse file  " );
   
 
   
 
#  4 
  my $hashref3 =  $conf->getNormalizedData;
  ok( $hashref3 , "Config::Interactive  getNormalizedData OK " );
 
# 5
   
  ok($hashref3->{PORT} == 8080, "  Check for key=value failed ");  
   
 # 6
   
  ok($hashref3->{METADATA_DB_FILE} eq '/home/user/somefilel', "  Check for scalar interpolation failed ");  

# 7
   
  ok($hashref3->{SQL_DB_PATH} eq '/home/user', "  Check for XML   interpolation failed " );  

# 8
   
  ok($hashref3->{SQL_production} == 1, "  Check for XML fragment attribute failed ");  

# 9
   
  ok($hashref3->{SQL_DB_DRIVER} eq 'mysql', "  Check for XML fragment  element failed ");  

# 10
  eval {  
    $conf->store("/tmp/test_$$.conf")   
  };
  ok( !$@  && -e "/tmp/test_$$.conf", "Config::Interactive store file ". $@);  
  $@ = undef;
  # 11
  eval {    
   $conf = new Config::Interactive({file => $cfg,   dialog => undef,  validkeys => \%CONF_VALID, prompts => \%CONF_KEYS}); 
   };
   ok(!$@ && $conf , "Config::Interactive create object with patterns and prompts " . $@);
   
 # 12
    
  ok( $conf->parse , "Config::Interactive parse with prompts file   " );
  

 

print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";
