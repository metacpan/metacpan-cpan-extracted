#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{CLONE_CHOOSE_PREFERRED_BACKEND} = "Storable"; }
END { delete $ENV{CLONE_CHOOSE_PREFERRED_BACKEND} } # for VMS

use Test::More;

BEGIN
{
    $ENV{CLONE_CHOOSE_PREFERRED_BACKEND} and eval "use $ENV{CLONE_CHOOSE_PREFERRED_BACKEND}; 1;";
    $@ and plan skip_all => "No $ENV{CLONE_CHOOSE_PREFERRED_BACKEND} found.";

    use_ok('Clone::Choose') || BAIL_OUT "Couldn't load Clone::Choose";
}

diag("Testing Clone::Choose $Clone::Choose::VERSION, Perl $], $^X");

my $backend = Clone::Choose->backend;

diag("Using backend $backend version " . $backend->VERSION);

done_testing;


