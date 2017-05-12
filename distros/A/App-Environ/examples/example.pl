#!/usr/bin/env perl

use 5.008000;
use strict;
use warnings;

use lib './examples/lib';

use FindBin;
use App::Environ;
use Data::Dumper;

BEGIN {
  $ENV{APPCONF_DIRS} = "$FindBin::Bin/etc";
}

use Cat;
use Dog;
use Cow;

App::Environ->send_event( 'initialize', qw( foo bar ) );

my $cat_inst = Cat->instance;
my $dog_inst = Dog->instance;
my $cow_inst = Cow->instance;

print Dumper($cat_inst);
print Dumper($dog_inst);
print Dumper($cow_inst);

App::Environ->send_event('reload');
App::Environ->send_event('finalize:r');
