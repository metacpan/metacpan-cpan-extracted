#!/usr/bin/env perl
use Test::More;
use strict;
use warnings;
no strict 'refs';
use Mojo::JSON qw/decode_json/;

use lib '../lib';

BEGIN {
  use_ok('Crypt::MagicSignatures::Envelope');
  use_ok('Crypt::MagicSignatures::Key');
};

ok(my $me = Crypt::MagicSignatures::Envelope->new(
  data => ''
), 'Constructor (Attributes)');

ok(!$me->data(''), 'Define null data');

ok(!$me->data, 'No data');

ok(my $mkey = Crypt::MagicSignatures::Key->generate(size => 1024), 'Generate');

ok(!$me->sign($mkey), 'Do not sign no data');

is($me->data_type, 'text/plain', 'Data type default');
ok($me->data_type('application/atom+xml'), 'Set data type');
ok(!$me->dom, 'Get demo from no dom');

ok($me->to_xml, 'XML without data');
ok(!$me->to_compact, 'Compact without data');
is($me->to_json, '{}', 'JSON without data');

done_testing;
__END__
