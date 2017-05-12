#!perl
use strict;
use warnings;
use Test::More;
use Test::NoWarnings;

use Data::Reach qw/reach/;

plan tests => 3;

# test data
my $data = {
  foo => [ undef,
           'abc',
           {bar => {buz => 987}},
           1234,
          ],
  qux => 'qux',
};


is reach($data, qw/qux/),       'qux',         '1 step scalar';
is reach($data, qw/foo 3/),     1234,          'multistep short';

