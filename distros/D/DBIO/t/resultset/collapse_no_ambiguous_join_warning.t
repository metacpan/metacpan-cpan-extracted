use warnings;
use strict;

use Test::More;
use DBIO::Test;

# karr k315, k328: the collapser's generated row fetcher is string-eval'd
# in package DBIO::ResultSet, which has a method named join(). A bare
# join() in the generated text warns "Ambiguous call resolved as
# CORE::join()". Iterating a has_many prefetch in iterator (collapse)
# mode must run that code without any warning.

my $schema = DBIO::Test->init_schema(no_deploy => 1);

$schema->storage->mock_persistent(
  qr/SELECT/i,
  [
    [ 1, 'A1', 13, undef, 1, 1, 'T1', 1999, undef, undef ],
    [ 1, 'A1', 13, undef, 2, 1, 'T2', 2000, undef, undef ],
    [ 2, 'A2', 13, undef, 3, 2, 'T3', 2001, undef, undef ],
  ],
);

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

my $rs = $schema->resultset('Artist')->search({}, {
  prefetch => 'cds',
  order_by => 'me.artistid',
});

my $first = $rs->next;
ok $first, 'first collapsed row fetched via iterator';
is scalar(@{[ $first->cds->all ]}), 2, 'has_many collapsed';
my $second = $rs->next;
ok $second, 'second collapsed row fetched';

is_deeply \@warnings, [], 'no warnings from the generated row fetcher'
  or diag explain \@warnings;

done_testing;
