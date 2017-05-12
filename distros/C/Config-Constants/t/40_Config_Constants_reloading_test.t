#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use File::Spec;

use Config::Constants perl => File::Spec->catdir('t', 'confs', 'conf.pl');

BEGIN {
    use_ok('t::lib::Foo::Bar');
    use_ok('t::lib::Bar::Baz');
}

is(Foo::Bar::test_BAZ(), 'Foo::Bar -> BAZ is (the coolest module ever)', '... got the right config');

is(Bar::Baz::test_FOO(), 'Bar::Baz -> FOO is (42)', '... got the right config variable');
is(Bar::Baz::test_BAR(), 'Bar::Baz -> BAR is (Foo and Baz)', '... got the right config variable');

delete $INC{'t/lib/Foo/Bar.pm'};
delete $INC{'t/lib/Bar/Baz.pm'};

{
    local $SIG{'__WARN__'} = sub {};
    use_ok('t::lib::Foo::Bar');
    use_ok('t::lib::Bar::Baz');    
}

is(Foo::Bar::test_BAZ(), 'Foo::Bar -> BAZ is (the coolest module ever)', '... got the right config');

is(Bar::Baz::test_FOO(), 'Bar::Baz -> FOO is (42)', '... got the right config variable');
is(Bar::Baz::test_BAR(), 'Bar::Baz -> BAR is (Foo and Baz)', '... got the right config variable');