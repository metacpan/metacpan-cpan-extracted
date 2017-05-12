#!perl -T

use strict;
use warnings;

use lib qw( t/lib t/lib/MyApp/lib );

use Test::More; 

done_testing();


BEGIN {
  package Test::C::Log;

  use namespace::autoclean;
  use Moose;
  use Test::More;

  sub warn {
    is( $_[1], 'No Log::Log4perl configuration found', 'no configuration' );
  }
}

BEGIN {
  package MyApp::Null;

  use namespace::autoclean;
  use Moose;

  use Catalyst::Runtime 5.80;
  use Catalyst qw( Log::Log4perl );

  extends qw( Catalyst );

  __PACKAGE__->config(
    name => 'MyApp',
  );

  __PACKAGE__->log( Test::C::Log->new );

  __PACKAGE__->setup();
}

BEGIN {
  package MyApp::Init;

  use namespace::autoclean;
  use Moose;

  use Catalyst::Runtime 5.80;
  use Catalyst qw( Log::Log4perl );

  extends qw( Catalyst );

  __PACKAGE__->config(
    name => 'MyApp',
    'Plugin::Log::Log4perl' => {
      conf => 'init',
    },
  );

  __PACKAGE__->setup();
}

BEGIN {
  package MyApp::InitAndWatch;

  use namespace::autoclean;
  use Moose;

  use Catalyst::Runtime 5.80;
  use Catalyst qw( Log::Log4perl );

  extends qw( Catalyst );

  __PACKAGE__->config(
    name => 'MyApp',
    'Plugin::Log::Log4perl' => {
      conf        => 'init_and_watch',
      watch_delay => 'delay',
    },
  );

  __PACKAGE__->setup();
}
