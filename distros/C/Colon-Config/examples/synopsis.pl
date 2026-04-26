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

# you can also read the value from any custom field

my $data = <<EOS;
ali:x:1000:1000:Ali Ben:/home/ali:/bin/zsh
dad:y:1001:1010:Daddy:/home/dad:/bin/bash
mum:z:1002:1010:Mummy::/sbin/nologin
EOS

is $array = Colon::Config::read( $data, 1 ), [
    'ali' => 'x',
    'dad' => 'y',
    'mum' => 'z',
] or diag explain $array;

is $hash = Colon::Config::read_as_hash( $data, 1 ), {
    'ali' => 'x',
    'dad' => 'y',
    'mum' => 'z',
} or diag explain $hash;

is $hash = Colon::Config::read_as_hash( $data, 2 ), {
    'ali' => 1000,
    'dad' => 1001,
    'mum' => 1002,
} or diag explain $hash;

is $hash = Colon::Config::read_as_hash( $data, 4 ), {
    'ali' => 'Ali Ben',
    'dad' => 'Daddy',
    'mum' => 'Mummy',
} or diag explain $hash;

is $hash = Colon::Config::read_as_hash( $data, 5 ), {
    'ali' => '/home/ali',
    'dad' => '/home/dad',
    'mum' => undef,
} or diag explain $hash;

is $hash = Colon::Config::read_as_hash( $data, 99 ), {
    'ali' => undef,
    'dad' => undef,
    'mum' => undef,
} or diag explain $hash;

# custom separator support

my $csv = <<EOS;
name;age;city
alice;30;paris
bob;25;london
EOS

is Colon::Config::read($csv, 0, ";"),
    [ name => 'age;city', alice => '30;paris', bob => '25;london' ],
    "semicolon separator, field=0 (full value after first separator)"
    or diag explain Colon::Config::read($csv, 0, ";");

is Colon::Config::read_as_hash($csv, 2, ";"),
    { name => 'city', alice => 'paris', bob => 'london' },
    "semicolon separator, field=2 via read_as_hash"
    or diag explain Colon::Config::read_as_hash($csv, 2, ";");

done_testing;
