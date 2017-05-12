#!perl

use strict;
use warnings;

use Test::More;

done_testing;


BEGIN {
  package MyApp::Null;

  local $ENV{CPE};

  use namespace::autoclean;
  use Moose;
  use Test::More;

  use Catalyst::Runtime 5.80;
  use Catalyst qw( Environment );

  extends qw( Catalyst );

  __PACKAGE__->config( name => 'MyApp-Null' );
  __PACKAGE__->setup;

  ok( !defined $ENV{CPE}, '' );
}

BEGIN {
  package MyApp::Basic;

  local $ENV{CPE};

  use namespace::autoclean;
  use Moose;
  use Test::More;

  use Catalyst::Runtime 5.80;
  use Catalyst qw( Environment );

  extends qw( Catalyst );

  __PACKAGE__->config(
    name                  => 'MyApp-Basic',
    'Plugin::Environment' => { CPE => 'EPC' },
  );
  __PACKAGE__->setup;

  ok( $ENV{CPE} eq 'EPC' );
}
