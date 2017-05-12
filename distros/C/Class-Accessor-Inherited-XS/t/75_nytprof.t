use strict;
BEGIN { $ENV{NYTPROF} = 'start=no' }
use constant HAS_NYTPROF => eval{ require Devel::NYTProf };
use Test::More HAS_NYTPROF ? ('no_plan') : (skip_all => 'requires Devel::NYTProf');

use Class::Accessor::Inherited::XS inherited => [qw/foo/];

sub bar { goto __PACKAGE__->can('foo') }
is(bar(__PACKAGE__), undef) for (1..2);
