#!perl

use v5.40.0;

use strict;
use warnings;

use Test2::V1;

use ok 'App::pod2gfm';

foreach my $mod ( qw< App::pod2gfm > ) {
    my $mod_ver = '$' . $mod . '::VERSION';

    T2->diag(
        sprintf "Testing $mod %s, Perl %s, %s",
        $mod_ver, $], $^X,
    );
}

T2->done_testing;
