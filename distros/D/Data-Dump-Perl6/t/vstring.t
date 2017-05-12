#!perl -w

BEGIN {
    if ($] < 5.010) {
    print "1..0 # Skipped: perl-5.10 required\n";
    exit;
    }
}

use strict;
use Test;
plan tests => 9;

use Data::Dump::Perl6 qw(dump_perl6);

ok(dump_perl6(v10), q{v10});
ok(dump_perl6(v5.10.1), q{v5.10.1});
ok(dump_perl6(5.10.1), q{v5.10.1});
ok(dump_perl6(500.400.300.200.100), q{v500.400.300.200.100});

ok(dump_perl6(\5.10.1), q{v5.10.1});
ok(dump_perl6(\v10), q{v10});
ok(dump_perl6(\\v10), q{v10});
ok(dump_perl6([v10, v20, v30]), q{[v10, v20, v30]});
ok(dump_perl6({ version => v6.0.0 }), q({ version => v6.0.0 }));
