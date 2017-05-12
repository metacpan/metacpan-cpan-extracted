#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use lib 't/lib';
use Test::Class::Refresh;
use Try::Tiny;

use Class::Refresh;

my $dir = prepare_temp_dir_for('basic');
push @INC, $dir->dirname;

require Foo;

Class::Refresh->refresh;

can_ok('Foo', 'meth');
ok(!Foo->can('other_meth'), "!Foo->can('other_meth')");
is($Foo::FOO, 1, "package global exists");
is($Foo::BAR, 2, "other package global exists");
ok(!defined($Foo::BAZ), "third package global doesn't exist");


sleep 2;
update_temp_dir_for('basic', $dir);

Class::Refresh->refresh;

can_ok('Foo', 'other_meth');
ok(!Foo->can('meth'), "!Foo->can('meth')");
{ local $TODO = "hrm, global access like this is resolved at compile time";
is($Foo::FOO, 10, "package global exists with new value");
ok(!defined($Foo::BAR), "other package global doesn't exist");
is($Foo::BAZ, 30, "third package global exists");
}
is(eval '$Foo::FOO', 10, "package global exists with new value");
ok(!defined(eval '$Foo::BAR'), "other package global doesn't exist");
is(eval '$Foo::BAZ', 30, "third package global exists");

try { require Bar } catch { "We expect this to fail, that's alright and happens sometimes" };
Class::Refresh->refresh;
ok(exists $INC{'Bar.pm'}, "Failed package \$INC value exists");
ok(!defined $INC{'Bar.pm'}, "Failed package \$INC value is not defined after failed load");

# Now do the same thing to validate that there's no error in repopulating %CACHE
isnt(exception{ Class::Refresh->refresh }, "Second refresh is not an error");
ok(exists $INC{'Bar.pm'}, "Failed package \$INC value exists: second attempt");
ok(!defined $INC{'Bar.pm'}, "Failed package \$INC value is not defined after failed load: second attempt");

done_testing;
