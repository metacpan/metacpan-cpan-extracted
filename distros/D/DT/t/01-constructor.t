use Test::More tests => 8;

use strict;
use warnings 'FATAL';

use_ok 'DT';

# Should understand unix time with no import
my $time_now = time;
my $dt = eval { DT->new($time_now) };
is $@, '', "new unix time no exception";
is $dt->epoch, $time_now, "epoch() value";

my $dt_iso = eval { DT->new('2018-02-07T21:22:09Z') };
is $@, '', "new iso timestamp no exception";
is $dt_iso->epoch, 1518038529, "iso timestamp value";

eval { DT->import(':no_iso') };
is $@, '', "import :no_iso no exception";

my $xcpt_regex = qr/(?:odd|hash)/i;

$dt_iso = eval { DT->new('2018-02-07T21:22:09Z') };
like $@, $xcpt_regex, "new :no_iso exception";

# Pg is not enabled by default
my $dt_pg = eval { DT->new('2018-02-07 21:22:09.58343-08') };
like $@, $xcpt_regex, "new no :pg exception";
