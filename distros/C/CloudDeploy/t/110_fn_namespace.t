#!/usr/bin/env perl

use Test::More;
use CCfnX::Shortcuts;

is_deeply(
  Fn::Join('-', 'Value1', 'Value2'),
  { 'Fn::Join' => [ '-', [ 'Value1', 'Value2' ] ] },
  'Join used as function'
);
is_deeply(
  Fn::Base64('This is a base64 string'),
  { 'Fn::Base64' => 'This is a base64 string' },
  'Base64 used as Function'
);

done_testing;
