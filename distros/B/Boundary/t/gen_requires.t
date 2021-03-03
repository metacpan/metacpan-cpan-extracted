use strict;
use warnings;
use Test::More;

use Boundary ();

my $code = Boundary->gen_requires('Some');
is ref $code, 'CODE';

is_deeply \%Boundary::INFO, {};

$code->('hello');

is_deeply $Boundary::INFO{Some}{requires}, ['hello'];

$code->('world');

is_deeply $Boundary::INFO{Some}{requires}, ['hello', 'world'];

done_testing;
