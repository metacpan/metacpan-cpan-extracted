#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use File::Temp ();

use_ok('Data::FDSet');

my $set = Data::FDSet->new();
is_deeply( $set->get_fds(), [], 'get_fds() when empty' );

my @temps = map { scalar File::Temp::tempfile() } ( 1 .. 8 );

my $xtra_temp = File::Temp::tempfile();

$set->add( $xtra_temp, fileno( $temps[0] ), fileno( $temps[1] ) );

is_deeply(
    $set->get_fds(),
    [ fileno($temps[0]), fileno($temps[1]), fileno($xtra_temp) ],
    'add() then get_fds()',
);

$set->remove( fileno($temps[1]), fileno($xtra_temp) );

is_deeply(
    $set->get_fds(),
    [  fileno($temps[0]) ],
    'remove() then get_fds()',
);

my $rout = Data::FDSet->new();

select( $$rout = $$set, undef, undef, 1 );

is_deeply(
    $rout->get_fds(),
    [  fileno($temps[0]) ],
    'select() works with the dereferenced scalar',
);

#----------------------------------------------------------------------

vec( my $mask = q<>, 5, 1 ) = 1;
ok(
    Data::FDSet->new($mask)->has(5),
    'instantiate from preexisting mask; has()',
);

#----------------------------------------------------------------------

vec( my $mask2 = q<>, 2, 1 ) = 1;
vec( $mask2, 7, 1 ) = 1;

my $replace_set = Data::FDSet->new();
$$replace_set = $mask2;

is_deeply(
    $replace_set->get_fds(),
    [ 2, 7 ],
    'replace by writing internal scalar',
);

done_testing();
