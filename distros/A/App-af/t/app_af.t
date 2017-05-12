use Test2::Bundle::Extended;
use App::af;

subtest 'compute_class' => sub {

  subtest 'normal' => sub {
  
    local @ARGV = qw( download --foo --bar --baz );
    
    is( App::af->compute_class, 'App::af::download' );
  
  };

  subtest 'normal' => sub {
  
    local @ARGV = qw( --version );
    
    is( App::af->compute_class, 'App::af::default' );
  
  };

  subtest 'none' => sub {
  
    local @ARGV = qw();
    
    is( App::af->compute_class, 'App::af::default' );
  
  };

};

done_testing;
