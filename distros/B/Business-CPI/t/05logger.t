use warnings;
use strict;
use Test::More;
use Business::CPI::Util::EmptyLogger;

ok(my $log = Business::CPI::Util::EmptyLogger->new(), 'the empty logger builds');
isa_ok($log, 'Business::CPI::Util::EmptyLogger', '$log');

map {
    is($log->$_,  undef, "$_ doesn't do anything")
} qw/debug info warn error fatal/;

map {
    ok(!$log->$_, "$_ returns false")
} qw/is_debug is_info is_warn is_error is_fatal/;

done_testing;
