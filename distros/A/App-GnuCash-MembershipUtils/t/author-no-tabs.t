
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/gc-members-generate-invoices',
    'bin/gc-members-list',
    'lib/App/GnuCash/MembershipUtils.pm',
    'lib/GnuCash/Schema.pm',
    'lib/GnuCash/Schema/Result/Account.pm',
    'lib/GnuCash/Schema/Result/Billterm.pm',
    'lib/GnuCash/Schema/Result/Book.pm',
    'lib/GnuCash/Schema/Result/Budget.pm',
    'lib/GnuCash/Schema/Result/BudgetAmount.pm',
    'lib/GnuCash/Schema/Result/Commodity.pm',
    'lib/GnuCash/Schema/Result/Customer.pm',
    'lib/GnuCash/Schema/Result/Employee.pm',
    'lib/GnuCash/Schema/Result/Entry.pm',
    'lib/GnuCash/Schema/Result/Gnclock.pm',
    'lib/GnuCash/Schema/Result/Invoice.pm',
    'lib/GnuCash/Schema/Result/Job.pm',
    'lib/GnuCash/Schema/Result/Lot.pm',
    'lib/GnuCash/Schema/Result/Order.pm',
    'lib/GnuCash/Schema/Result/Price.pm',
    'lib/GnuCash/Schema/Result/Recurrence.pm',
    'lib/GnuCash/Schema/Result/Schedxaction.pm',
    'lib/GnuCash/Schema/Result/Slot.pm',
    'lib/GnuCash/Schema/Result/Split.pm',
    'lib/GnuCash/Schema/Result/Taxtable.pm',
    'lib/GnuCash/Schema/Result/TaxtableEntry.pm',
    'lib/GnuCash/Schema/Result/Transaction.pm',
    'lib/GnuCash/Schema/Result/Vendor.pm',
    'lib/GnuCash/Schema/Result/Version.pm',
    'lib/GnuCash/Schema/ResultSet/Customer.pm',
    'lib/GnuCash/Schema/ResultSet/Invoice.pm',
    't/00-compile.t',
    't/author-critic.t',
    't/author-distmeta.t',
    't/author-minimum-version.t',
    't/author-mojibake.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-linkcheck.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/author-synopsis.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t'
);

notabs_ok($_) foreach @files;
done_testing;
