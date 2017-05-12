use strict;
use warnings;
use Test::More;

use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use Badge::Depot::Plugin::Coverage;

my $badge = Badge::Depot::Plugin::Coverage->new(coverage => 87.1);
is $badge->image_url, 'https://img.shields.io/badge/coverage-87.1%-orange.svg', 'Correct image';

$badge = Badge::Depot::Plugin::Coverage->new(coverage => -1);
is $badge->to_html, '', 'Correct empty badge';
done_testing;
