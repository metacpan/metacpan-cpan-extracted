#!perl

use Test::Without::Module ("Module::Runtime");
use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{CLONE_CHOOSE_PREFERRED_BACKEND} = "Clone::PP"; }
END { delete $ENV{CLONE_CHOOSE_PREFERRED_BACKEND} } # for VMS

use Test::More;

BEGIN
{
    $ENV{CLONE_CHOOSE_PREFERRED_BACKEND} and eval "use $ENV{CLONE_CHOOSE_PREFERRED_BACKEND}; 1;";
    $@ and plan skip_all => "No $ENV{CLONE_CHOOSE_PREFERRED_BACKEND} found.";
}

use Clone::Choose;

my @backends = Clone::Choose->get_backends;
my $backend  = Clone::Choose->backend;

ok($ENV{CLONE_CHOOSE_PREFERRED_BACKEND} and $backend eq $ENV{CLONE_CHOOSE_PREFERRED_BACKEND} or grep { m/^$backend$/ } @backends);

done_testing;


