# $Id: 01.calculations.t 2 2007-10-27 22:08:58Z kim $

use Test::More tests => 51;
use Data::Page::Balanced;

#
# Make sure default values are sane
#
my $pager = Data::Page::Balanced->new({total_entries => 25, entries_per_page => 25});

is($pager->entries_per_page(),      25,     "entries_per_page -> " .        $pager->entries_per_page);
is($pager->total_entries(),         25,     "total_entries -> " .           $pager->total_entries);
is($pager->entries_on_this_page(),  25,     "entries_on_this_page -> " .    $pager->entries_on_this_page);
is($pager->first_page(),            1,      "first_page -> " .              $pager->first_page);
is($pager->last_page(),             1,      "last_page -> " .               $pager->last_page);
is($pager->first(),                 1,      "first -> " .                   $pager->first);
is($pager->last(),                  25,     "last -> " .                    $pager->last);
is($pager->previous_page(),         undef,  "previous_page -> " .           defined $pager->previous_page ? 'defined' : 'undef');
is($pager->current_page(),          1,      "current_page -> " .            $pager->current_page);
is($pager->next_page(),             undef,  "next_page -> " .               defined $pager->next_page ? 'defined' : 'undef');
is($pager->skipped(),               0,      "skipped -> " .                 $pager->skipped);

my @ints    = (1 .. 100);
@ints       = $pager->splice(\@ints);
my $joined  = join ',', @ints;
is($joined, '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25' , "splice -> " . $joined);

#
# All arguments
#
$pager = Data::Page::Balanced->new({total_entries => 50, entries_per_page => 24, current_page=>2, flexibility=>5});
is($pager->last_page(), 2, "last_page -> " . $pager->last_page);
is($pager->entries_per_page(), 25, "entries_per_page -> " . $pager->entries_per_page);
is($pager->current_page(), 2, "current_page -> " . $pager->current_page);
is($pager->flexibility(), 5, "flexibility -> " . $pager->flexibility);

#
# Simple cases, entries per page >= total entries
#
$pager = Data::Page::Balanced->new({total_entries => 67, entries_per_page => 25});
is($pager->last_page(), 2, "last_page -> " . $pager->last_page);
is($pager->entries_per_page(), 34, "entries_per_page -> " . $pager->entries_per_page);

$pager = Data::Page::Balanced->new({total_entries => 100, entries_per_page => 20});
is($pager->last_page(), 5, "last_page -> " . $pager->last_page);
is($pager->entries_per_page(), 20, "entries_per_page -> " . $pager->entries_per_page);

$pager = Data::Page::Balanced->new({total_entries => 100, entries_per_page => 1});
is($pager->last_page(), 100, "last_page -> " . $pager->last_page);
is($pager->entries_per_page(), 1, "entries_per_page -> " . $pager->entries_per_page);

$pager = Data::Page::Balanced->new({total_entries => 26, entries_per_page => 25});
is($pager->last_page(), 1, "last_page -> " . $pager->last_page);
is($pager->entries_per_page(), 26, "entries_per_page -> " . $pager->entries_per_page);

$pager = Data::Page::Balanced->new({total_entries => 25, entries_per_page => 20});
is($pager->last_page(), 1, "last_page -> " . $pager->last_page);
is($pager->entries_per_page(), 25, "entries_per_page -> " . $pager->entries_per_page);

$pager = Data::Page::Balanced->new({total_entries => 30, entries_per_page => 20});
is($pager->last_page(), 1, "last_page -> " . $pager->last_page);
is($pager->entries_per_page(), 30, "entries_per_page -> " . $pager->entries_per_page);

$pager = Data::Page::Balanced->new({total_entries => 31, entries_per_page => 20});
is($pager->last_page(), 2, "last_page -> " . $pager->last_page);
is($pager->entries_per_page(), 20, "entries_per_page -> " . $pager->entries_per_page);

$pager = Data::Page::Balanced->new({total_entries => 20, entries_per_page => 20});
is($pager->last_page(), 1, "last_page -> " . $pager->last_page);
is($pager->entries_per_page(), 20, "entries_per_page -> " . $pager->entries_per_page);

#
# total entries < entries per page
#
$pager = Data::Page::Balanced->new({total_entries => 1, entries_per_page => 20});
is($pager->last_page(), 1, "last_page -> " . $pager->last_page);
is($pager->entries_per_page(), 20, "entries_per_page -> " . $pager->entries_per_page);

#
# Make sure the flexibility isn't overridden
#
$pager = Data::Page::Balanced->new({total_entries => 37, entries_per_page => 25});
is($pager->last_page(), 1, "last_page -> " . $pager->last_page);
is($pager->entries_per_page(), 37, "entries_per_page -> " . $pager->entries_per_page);

$pager = Data::Page::Balanced->new({total_entries => 38, entries_per_page => 25});
is($pager->last_page(), 2, "last_page -> " . $pager->last_page);
is($pager->entries_per_page(), 25, "entries_per_page -> " . $pager->entries_per_page);

#
# Non-standard flexibility
#
$pager = Data::Page::Balanced->new({total_entries => 67, entries_per_page => 25, flexibility => 1});
is($pager->last_page(), 3, "last_page -> " . $pager->last_page);
is($pager->entries_per_page(), 25, "entries_per_page -> " . $pager->entries_per_page);

$pager = Data::Page::Balanced->new({total_entries => 26, entries_per_page => 25, flexibility => 1});
is($pager->last_page(), 1, "last_page -> " . $pager->last_page);
is($pager->entries_per_page(), 26, "entries_per_page -> " . $pager->entries_per_page);

$pager = Data::Page::Balanced->new({total_entries => 26, entries_per_page => 25, flexibility => 0});
is($pager->last_page(), 2, "last_page -> " . $pager->last_page);
is($pager->entries_per_page(), 25, "entries_per_page -> " . $pager->entries_per_page);

#
# Changing total_entries, entries_per_page, flexibility and current_page after object initialization
#
$pager = Data::Page::Balanced->new({total_entries => 0, entries_per_page => 25});
is($pager->last_page(), 1, "last_page -> " . $pager->last_page);
is($pager->entries_per_page(), 25, "entries_per_page -> " . $pager->entries_per_page);

$pager->total_entries(26);
is($pager->last_page(), 1, "last_page -> " . $pager->last_page);
is($pager->entries_per_page(), 26, "entries_per_page -> " . $pager->entries_per_page);

$pager->entries_per_page(10);
is($pager->last_page(), 2, "last_page -> " . $pager->last_page);
is($pager->entries_per_page(), 13, "entries_per_page -> " . $pager->entries_per_page);

$pager->current_page(-1);
is($pager->current_page(), 1, "current_page -> " . $pager->current_page);
