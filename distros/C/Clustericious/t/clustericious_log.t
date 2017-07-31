use strict;
use warnings;
use Test::Clustericious::Log import => ':all', diag => 'NONE', note => 'ALL';
use Clustericious::Log -init_logging => "Froodle";
use Test::More tests => 5;
use YAML::XS ();

TRACE "trace";
DEBUG "debug";
INFO  "info";
WARN  "warn";
ERROR "error";
FATAL "fatal";

cmp_ok log_events, '>', 0, 'log_events';

subtest log_context => sub {
  plan tests => 6;

  my $count = scalar log_events;
  ok $count, "number of events = $count";

  log_context {
  
    is scalar log_events, 0, 'no events in context';
    
    INFO "some info";
    
    is scalar log_events, 1, 'exactly one event in context';
  
    like [log_events]->[0]->{message}, qr{some info}, 'contains message';
  };
  
  is scalar log_events, $count+1, "exactly @{[ $count+1 ]} events back out of context";
  like [log_events]->[-1]->{message}, qr{some info}, 'does not contain message';

};

subtest log_like => sub {

  log_context {
  
    INFO "Unicron! Why did you torture me?";
    INFO "Grimlock here";
    INFO "and slag";
    
    note YAML::XS::Dump(log_events);
    
    log_like 'Grimlock here', 'simple string';
    log_like qr{rimlock},     'regex';

    log_like {
      message => 'Grimlock here', 
      log4p_level => 'INFO',
    }, 'hash ref';

    log_like {
      message => qr{rimlock},
      log4p_level => 'INFO',
    }, 'hash ref with regex';
  
  };
};

subtest log_unlike => sub {

  log_context {
  
    INFO "Unicron! Why did you torture me?";
    INFO "Grimlock here";
    INFO "and slag";
    ERROR "Megatron";
    
    log_unlike 'A commedy Tonight!', 'string';
    log_unlike qr{some pattern that does not match}, 'regex';

    log_unlike {
      message     => 'Megatron',
      log4p_level => 'INFO',
    }, 'hashref';

    log_unlike {
      message     => qr{egatron},
      log4p_level => 'INFO',
    }, 'hashref with regex';
  
  };

};


subtest 'correct package' => sub {

  log_context {
    do {
      package
        Foo::Bar::Baz;
      use Clustericious::Log;
      INFO "Message From Foo";
    };
    
    do {
      package
        Barf::Baz::Foo;
      use Clustericious::Log;
      INFO "Message From Barf";
    };
    
    log_like {
      message        => 'Message From Foo',
      log4p_category => 'Foo.Bar.Baz',
    }, 'correct class';
    
    log_like {
      message        => 'Message From Barf',
      log4p_category => 'Barf.Baz.Foo',
    };

    note YAML::XS::Dump(log_events);
    
  };

};
