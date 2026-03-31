#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(ok done_testing);

use App::prepare4release;

my $pm = <<'PM';
package X;
use v5.20;
use strict;
PM

my $got = App::prepare4release->min_perl_version_from_pm_content($pm);
ok( defined $got, 'parsed use v5.20' );

done_testing;
