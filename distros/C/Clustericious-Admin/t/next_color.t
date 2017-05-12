use strict;
use warnings;
use Test::Clustericious::Config;
use Test::More tests => 2;
use App::clad;

subtest default => sub {
  plan tests => 5;

  create_config_ok 'Clad', {
    env => {},
    cluster => {
      cluster1 => [ qw( host1 host2 host3 ) ],
      cluster2 => [ qw( host4 host5 host6 ) ],
    },
  };
  
  my $clad = App::clad->new('cluster1' => 'uptime');
  
  is $clad->next_color, 'green', 'clad.next_color = green';
  is $clad->next_color, 'cyan',  'clad.next_color = cyan';
  is $clad->next_color, 'green', 'clad.next_color = green';
  is $clad->next_color, 'cyan',  'clad.next_color = cyan';

};

subtest default => sub {
  plan tests => 5;

  create_config_ok 'Clad', {
    env => {},
    cluster => {
      cluster1 => [ qw( host1 host2 host3 ) ],
      cluster2 => [ qw( host4 host5 host6 ) ],
    },
    
    colors => [ qw( red white blue ) ],
  };
  
  my $clad = App::clad->new('cluster1' => 'uptime');
  
  is $clad->next_color, 'red', 'clad.next_color = red';
  is $clad->next_color, 'white',  'clad.next_color = white';
  is $clad->next_color, 'blue', 'clad.next_color = blue';
  is $clad->next_color, 'red',  'clad.next_color = red';

};
