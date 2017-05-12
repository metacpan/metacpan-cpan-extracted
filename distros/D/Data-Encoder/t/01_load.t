use strict;
use warnings;
use Test::Requires 'JSON';
use Data::Encoder;
use Test::More;

my $encoder = Data::Encoder->load('JSON');
is $encoder->encode(['foo']), '["foo"]';

done_testing;
