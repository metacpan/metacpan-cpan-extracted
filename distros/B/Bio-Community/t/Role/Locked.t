use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    t::Role::TestLocked
);


my $obj;


# Basic object

ok $obj = t::Role::TestLocked->new(), 'Basic object';
isa_ok $obj, 't::Role::TestLocked';
ok $obj->foo('bar');
is $obj->foo, 'bar';


# Lock object

ok $obj->lock, 'Lock';
eval { $obj->foo(5) };
ok $@, 'Forbidden modification';
is $obj->foo, 'bar';


# Unlock object

ok $obj->unlock, 'Unlock';
ok $obj->foo('zzz');
is $obj->foo, 'zzz';


done_testing();

