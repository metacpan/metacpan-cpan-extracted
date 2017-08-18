use Test2::V0 -no_srand => 1;
use App::af;
use lib 't/lib';
use lib 'corpus/lib';
use MyTest;
use File::Temp qw( tempdir );
use File::chdir;
do './bin/af';

subtest 'basic' => sub {

  local $CWD = tempdir( CLEANUP => 1 );

  alienfile q{
    use alienfile;
    #configure { requires 'Bogus1::Bogus1' };
    requires 'Bogus2::Bogus2';
    share { requires 'Bogus3::Bogus3' };
    sys { requires 'Bogus4::Bogus4' };
  };

  run 'missing';
  is last_exit, 0;
  
  foreach my $phase (qw( configure any share system ))
  {
    run 'missing', -p => $phase;
    is last_exit, 0;
  }

};

done_testing;
