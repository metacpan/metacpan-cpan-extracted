use strict;
use warnings;
use Test::More 0.88;

use B::Hooks::EndOfScope;

plan skip_all => 'Skipping PP fallback test in XS mode'
  unless $INC{'B/Hooks/EndOfScope/PP.pm'};

my $w;
local $SIG{__WARN__} = sub {
  $w = $_[0] if $_[0] =~ qr/\QException "bar"/
};

eval q[
    sub foo {
        BEGIN {
            on_scope_end { die 'Exception "bar"' };
        }
    }
];

like (
  $w,
  qr/scope-end callback raised an exception, which can not be propagated when .+? operates in pure-perl mode/,
  'Warning on lost callback exception correctly emited'
);

done_testing;
