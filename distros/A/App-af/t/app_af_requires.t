use Test2::Bundle::Extended;
use App::af;
use lib 't/lib';
use lib 'corpus/lib';
use MyTest;
use File::Temp qw( tempdir );
use File::chdir;
use YAML qw( Load );
do './bin/af';

subtest 'basic' => sub {

  local $CWD = tempdir( CLEANUP => 1 );

  alienfile q{
    use alienfile;
    
    probe sub { 'system' };
    
    requires 'Foo::Any' => '1.00';
    
    configure {
      requires 'Foo::Config' => '2.00';
    };
    
    share {
      requires 'Foo::Share' => '3.00';
    };
    
    sys {
      requires 'Foo::System' => '4.00';
    };
  };
  
  subtest 'all' => sub {
  
    run 'requires';
    
    is last_exit, 0;
    
    is(
      Load(last_stdout),
      {
        any       => { 'Foo::Any' => '1.00' },
        configure => { 'Foo::Config' => '2.00' },
        share     => { 'Foo::Any' => '1.00', 'Foo::Share' => '3.00' },
        system    => { 'Foo::Any' => '1.00', 'Foo::System' => '4.00' },
      },
    );
  
  };
  
  subtest 'configure' => sub {
  
    run 'requires', -p => 'configure';
    
    is last_exit, 0;
    
    is(
      Load(last_stdout),
      { 'Foo::Config' => '2.00' },
    );
  
  };
  
  subtest 'any' => sub {
  
    run 'requires', -p => 'any';
    
    is last_exit, 0;
    
    is(
      Load(last_stdout),
      { 'Foo::Any' => '1.00' },
    );
  
  };
  
  subtest 'share' => sub {
  
    run 'requires', -p => 'share';
    
    is last_exit, 0;
    
    is(
      Load(last_stdout),
      { 'Foo::Any' => '1.00', 'Foo::Share' => '3.00' },
    );
  
  };
  
  subtest 'system' => sub {
  
    run 'requires', -p => 'system';
    
    is last_exit, 0;
    
    is(
      Load(last_stdout),
      { 'Foo::Any' => '1.00', 'Foo::System' => '4.00' },
    );
  
  };

};

done_testing;
