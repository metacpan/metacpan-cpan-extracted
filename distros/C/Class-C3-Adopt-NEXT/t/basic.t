use strict;
use warnings;
use Test::More tests => 12;
use Test::Exception 0.27;

use lib 't/lib';

our @warnings;

BEGIN { $SIG{__WARN__} = sub { push @warnings, @_ } }

use C3NT;

BEGIN { use_ok('Class::C3::Adopt::NEXT'); }

my $quux_obj = C3NT::Quux->new;

is(scalar @warnings, 0, 'no warnings yet');

is($quux_obj->basic, 42, 'Basic inherited method returns correct value');
like($warnings[0], qr/C3NT::Quux uses NEXT/, 'warning for the first time NEXT is used');

is($quux_obj->basic, 42, 'Basic inherited method returns correct value');
is(scalar @warnings, 3, 'warn only once per class');

{
    my $non_exist_rval;
    lives_ok(sub {
        $non_exist_rval = $quux_obj->non_exist;
    }, 'Non-existant non-ACTUAL throws no errors');
    is($non_exist_rval, undef, 'Non-existant non-ACTUAL returns undef');
}

throws_ok(sub {
    $quux_obj->non_exist_actual;
}, qr|non_exist_actual\b.*\bC3NT::Quux|, 'Non-existant ACTUAL throws correct error');

throws_ok(sub {
    $quux_obj->actual_fail_halfway;
}, qr|actual_fail_halfway\b.*\bC3NT::Quux|, 'Non-existant ACTUAL in superclass throws correct error');

is( $quux_obj->c3_then_next, 21, 'C3 then NEXT' );
is( $quux_obj->next_then_c3, 22, 'NEXT then C3' );
