#!/perl -I..

use strict;
use lib 't';
use Test::More tests => 1;

my @warnings;
BEGIN {$SIG{__WARN__} = sub {push @warnings,  join '', @_} }

use cvNowarn;
SKIP: {
    skip 'Readonly installed', 1  if $Config::Vars::RO_ok;

    is scalar @warnings, 0     => 'Correct number of warnings';
}
