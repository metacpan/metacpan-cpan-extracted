use lib 'lib';
use strict;
use warnings;
use Test::More tests => 1;
use Class::Spiffy;

my $args = Class::Spiffy->parse_arguments();

ok(ref $args && ref($args) eq 'HASH');
