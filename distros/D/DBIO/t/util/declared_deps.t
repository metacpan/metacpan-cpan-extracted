use strict;
use warnings;
use Test::More;

use DBIO::Util ();

# DBIO::Util loads Sub::Quote at compile time (hard use), so a missing
# cpanfile entry breaks installs that resolve deps from the cpanfile alone.
open my $fh, '<', 'cpanfile'
  or plan skip_all => 'no cpanfile in cwd (installed test run)';
my $cpanfile = do { local $/; <$fh> };
close $fh;

like $cpanfile, qr/^\s*requires\s+'Sub::Quote'/m,
  'cpanfile requires Sub::Quote (hard-loaded by DBIO::Util)';

# split_name needed String::CamelCase, declared nowhere; the function was dead.
ok !DBIO::Util->can('split_name'), 'split_name is gone from DBIO::Util';
ok !(grep { $_ eq 'split_name' } @DBIO::Util::EXPORT_OK),
  'split_name is not exported any more';

done_testing;
