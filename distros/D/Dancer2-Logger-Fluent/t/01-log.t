use strict;
use warnings;

use Test::More;

plan tests => 3;

use Dancer2::Logger::Fluent;

my $l = Dancer2::Logger::Fluent->new( app_name => 'test', log_level => 'core' );

ok defined($l), 'Dancer2::Logger::Fluent object';
isa_ok $l, 'Dancer2::Logger::Fluent';
can_ok $l, qw(log debug warning error);
