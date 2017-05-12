package AppReg; 
use PNDI; 

BEGIN { 
  my %DbConfig = (
  'Database.Default.TYPE'   => 'mysql',
  'Database.Default.NAME'   => 'MyTestDB',
  'Database.Default.HOST'   => 'localhost',
  'Database.Default.PORT'   => '3306',
  'Database.Default.USER'   => 'root',
  'Database.Default.PASS'   => ''
  );

  foreach my $key (keys %DbConfig) {
    PNDI->register(name=>$key,value=>$DbConfig{$key},scope=>$PNDI::SERVICE);
  }
};

1;
