#!/usr/bin/perl -T

use lib '../lib';
use strict;
use warnings;

use Test::More tests => 12;

use Application::Pipeline;

my $app = bless {}, 'Application::Pipeline';

# check add/drop services
  ok( $app->addServices(), 'addServices should behave when passed an empty @_');

  TODO: {
    local $TODO = 'addServices needs to explicitly fail on odd length @_';

    ok( !$app->addServices( '1' ), 'addServices should complain when passed an odd length @_');
  }

  ok( $app->addServices(
        string => 'string',
        scalarref => \('string'),
        arrayref => [],
        hashref => {},
        object => bless( {}, 'Application::Pipeline'),
        coderef => sub { return 'subroutine' }
      ), 'addServices should return a true value for an even length @_');

  is( $app->string,'string' );
  isa_ok( $app->scalarref, 'SCALAR' );
  isa_ok( $app->arrayref, 'ARRAY' );
  isa_ok( $app->hashref, 'HASH' );
  isa_ok( $app->object, 'Application::Pipeline' );
  is( $app->coderef(),'subroutine' );

  can_ok( $app, 'string' );
  ok( $app->dropServices('string') );
  ok( !$app->can('string') );

