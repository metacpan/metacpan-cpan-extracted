use strict;
use warnings;
use Test::More;
use FindBin;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
eval { require Test::Kwalitee; Test::Kwalitee->import('kwalitee_ok'); 1 }
    or plan skip_all => 'Test::Kwalitee required';

# Only `make distdir` writes META.*, so from a checkout the metadata indicators pass vacuously.
chdir "$FindBin::Bin/.." or die $!;
plan skip_all => 'not a release directory: run this inside the make distdir output'
    if -d '.git';
ok -f $_, "$_ ships" for qw(META.yml META.json);

# Test::Kwalitee skips CPANTS' separate-license indicator as experimental.
ok -f 'LICENSE', 'separate LICENSE file is shipped';
kwalitee_ok();
done_testing;
