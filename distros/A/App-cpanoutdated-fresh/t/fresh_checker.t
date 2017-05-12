
use strict;
use warnings;

use Test::More;
use Test::Differences;

# FILENAME: fresh_checker.t
# CREATED: 08/30/14 22:21:30 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test freshness checking code

use App::cpanoutdated::fresh;

my $f = App::cpanoutdated::fresh->new();

my $result = $f->_check_fresh(
  {
    release => 'Module-Metadata',
  },
  { indexed => 1, authorized => 1, version => 0, name => 'Module::Metadata' }
);

eq_or_diff( $result, undef, 'Older = undef' );

$result = $f->_check_fresh(
  {
    release => 'Module-Metadata',
  },
  { indexed => 1, authorized => 1, version => 999999, name => 'Module::Metadata' }
);

eq_or_diff( [ sort keys %$result ], [ 'cpan', 'installed', 'meta', 'name', 'release' ], 'Newer = hash' );

done_testing;

