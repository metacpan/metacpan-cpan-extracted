use strict;
use warnings;
use Test::Clustericious::Config;
use Test::Clustericious::Log;
use Test::More tests => 5;

my $count = 0;

do {
  package
    Term::Prompt;
  
  use base qw( Exporter );
  
  sub prompt { ++$count; 'foo' }

  $INC{'Term/Prompt.pm'} = __FILE__;
};

create_config_ok Bar => <<EOF;
---
pw1: <%= get_password %>
pw2: <%= get_password %>
pw3: <%= get_password %>
EOF

my $config = Clustericious::Config->new('Bar');
is $config->pw1, 'foo', 'config.pw1';
is $config->pw2, 'foo', 'config.pw2';
is $config->pw3, 'foo', 'config.pw3';
is $count, 1, 'only called once';
