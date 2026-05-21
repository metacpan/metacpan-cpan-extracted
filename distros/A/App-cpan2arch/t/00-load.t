#!perl

use v5.42.0;

use strict;
use warnings;

use Test2::V1;

use ok 'App::cpan2arch';

foreach my $mod ( qw< App::cpan2arch > ) {
    my $mod_ver = '$' . $mod . '::VERSION';

    T2->diag(
        sprintf "Testing $mod %s, Perl %s, %s",
        $mod_ver, $], $^X,
    );
}

T2->done_testing;
