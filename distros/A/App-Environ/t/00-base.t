use 5.008000;
use strict;
use warnings;

use Test::More tests => 6;

my $APPENV_CLASS;
my $APPCONF_CLASS;

BEGIN {
  $APPENV_CLASS = 'App::Environ';
  use_ok( $APPENV_CLASS );

  $APPCONF_CLASS = 'App::Environ::Config';
  use_ok( $APPCONF_CLASS );
};

can_ok( $APPENV_CLASS, 'register' );
can_ok( $APPENV_CLASS, 'send_event' );

can_ok( $APPCONF_CLASS, 'register' );
can_ok( $APPCONF_CLASS, 'instance' );
