#!perl

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;

use Colon::Config;

my $config_sample = <<'EOS';
# this is a comment
fruit:banana
world: space
empty:

# ^^ empty line above is ignored
not a column (ignored)
sample:value:with:column
last:value
EOS

my $array;
is $array = Colon::Config::read($config_sample), [

    # note this is an Array Ref by default
    'fruit'  => 'banana',
    'world'  => 'space',
    'empty'  => undef,
    'sample' => 'value:with:column',
    'last'   => 'value'
  ]
  or diag explain $array;

my $hash;
is $hash = Colon::Config::read_as_hash($config_sample), {
    'fruit'  => 'banana',
    'world'  => 'space',
    'empty'  => undef,
    'sample' => 'value:with:column',
    'last'   => 'value'
  }
  or diag explain $hash;

done_testing;
