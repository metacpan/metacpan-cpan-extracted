#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Requires 'Moose';
use lib 't/lib';
use Test::Class::Refresh;
use Try::Tiny;

use Class::Refresh;

my $dir = prepare_temp_dir_for('compile-error');
push @INC, $dir->dirname;

require Foo;

is(exception { Class::Refresh->refresh }, undef, "loads successfully");

my $foo = Foo->new;
my $val;

is(exception { $val = $foo->meth }, undef, "\$foo->meth works");
is($val, 1, "got the right value");

sleep 2;
update_temp_dir_for('compile-error', $dir, 'middle');

like(
    exception { Class::Refresh->refresh },
    qr/^Global symbol "\$error" requires explicit package name/,
    "compilation error"
);

like(
    exception { $foo->meth },
    qr{^
        # 5.18+
        (?:Can't\ locate\ object\ method\ "meth"\ via\ package\ "Foo")
        |
        # 5.16 and earlier
        (?:Undefined\ subroutine\ &Foo::meth\ called)
    }x,
    "\$foo->meth doesn't work now"
);

sleep 2;
update_temp_dir_for('compile-error', $dir, 'after');

is(exception { Class::Refresh->refresh }, undef, "loads successfully");

is(exception { $val = $foo->meth }, undef, "\$foo->meth works again");
is($val, 3, "got the right value");

done_testing;
