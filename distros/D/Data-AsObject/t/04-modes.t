#!perl -T

use strict;
use warnings;

use lib q(lib);

use Test::More tests => 6;
use Test::Exception;
use Test::Warn;

use Data::AsObject
    dao => { mode => 'strict', -as => 'dao_strict' },
    dao => { mode => 'loose',  -as => 'dao_loose'  },
    dao => { mode => 'silent', -as => 'dao_silent' };

my %data = (foo => [1,2,3]);

my $data_strict = dao_strict {%data};
my $data_loose  = dao_loose  {%data};
my $data_silent = dao_silent {%data};

# strict
is($data_strict->foo(0), 1, "strict mode with existing element");
throws_ok( sub {$data_strict->bar}, qr(Attempting to access non-existing hash key), "strict mode with non-existing element" );

# loose
is($data_loose->foo(0), 1, "loose mode with existing element");
warning_like( sub  {$data_loose->bar}, qr(Attempting to access non-existing hash key), "loose mode with non-existing element" );

# silent
is($data_silent->foo(0), 1, "silent mode with existing element");
is($data_silent->bar, undef, "silent mode with non-existing element");

