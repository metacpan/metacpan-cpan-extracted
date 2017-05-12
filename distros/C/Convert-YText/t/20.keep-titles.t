BEGIN {
   binmode STDOUT, ':utf8';
   binmode STDERR, ':utf8';
}

use Test::More;
use strict;
use warnings;

require 't/titles.pl';

plan tests => 1+2*(scalar (keys %titles::hash));

use_ok 'Convert::YText', qw(encode_ytext validate_ytext);
foreach my $key (keys %titles::hash){
  ok(validate_ytext($titles::hash{$key}));
  is(encode_ytext($key), $titles::hash{$key}, "conserve: ".$key);
}
