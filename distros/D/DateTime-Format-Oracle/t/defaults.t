use strict;
use Test::More tests => 1;

use DateTime::Format::Oracle;

my %tests = (
    nls_date_format => 'YYYY-MM-DD HH24:MI:SS',
);

foreach my $method (keys %tests) {
    local $ENV{uc($method)} = '';
    is(DateTime::Format::Oracle->$method(), $tests{$method}, "default value for $method");
}

