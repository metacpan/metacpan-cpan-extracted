# $Id: 02.exceptions.t 2 2007-10-27 22:08:58Z kim $

use Test::Exception tests => 5;
use Data::Page::Balanced;

#
# Check that we croak if we aren't given the required arguments to new()
#
throws_ok { Data::Page::Balanced->new() } qr/total_entries and entries_per_page must be supplied/, 'Croaked correctly when total_entries and entries_per_page are missing.';

throws_ok { Data::Page::Balanced->new({total_entries=>20}) } qr/total_entries and entries_per_page must be supplied/, 'Croaked correctly when entries_per_page is missing.';

throws_ok { Data::Page::Balanced->new({entries_per_page=>20}) } qr/total_entries and entries_per_page must be supplied/, 'Croaked correctly when total_entries is missing.';

#
# Check that we croak if we try to set the entries per page below 1
#

throws_ok {
    my $pager = Data::Page::Balanced->new({total_entries=>20, entries_per_page=>10});
    $pager->entries_per_page(0);
} qr/There must be at least one entry per page/, 'Croaked correctly when asked to set entries_per_page below 1.';

throws_ok {
    my $pager = Data::Page::Balanced->new({total_entries=>20, entries_per_page=>0});
} qr/There must be at least one entry per page/, 'Croaked correctly when asked to set entries_per_page below 1.';
