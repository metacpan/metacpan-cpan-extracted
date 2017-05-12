#!/usr/bin/perl -w

use strict;

use Test::More tests => 318;

##################################
## Test Configs
##################################

# Some configs for testing
my %config = (
   'totalEntries'      => 200,
   'entriesPerPage'   => 10,
);

##################################
## End test configs
##################################

# Check we can load module
BEGIN { use_ok( 'Data::SpreadPagination' ); }

my $pageInfo = Data::SpreadPagination->new({
     totalEntries      => $config{totalEntries},
     entriesPerPage    => $config{entriesPerPage},
});

isa_ok($pageInfo,'Data::SpreadPagination');
isa_ok($pageInfo,'Data::Page');

is($pageInfo->max_pages, $pageInfo->last_page - 1, 'max_pages has defaulted to number of pages minus 1');
is($pageInfo->current_page, 1, 'current_page has defaulted to 1');
is($pageInfo->first, 1, 'first entry on the current page has defaulted to 1');

eval { $pageInfo = Data::SpreadPagination->new({}) };
like($@, qr/^totalEntries and entriesPerPage must be supplied /, 'caught invalid parameter set');

eval { $pageInfo = Data::SpreadPagination->new({totalEntries => 5}) };
like($@, qr/^totalEntries and entriesPerPage must be supplied /, 'caught invalid parameter set');

eval { $pageInfo = Data::SpreadPagination->new({entriesPerPage => 5}) };
like($@, qr/^totalEntries and entriesPerPage must be supplied /, 'caught invalid parameter set');

eval { $pageInfo = Data::SpreadPagination->new({totalEntries => 5, entriesPerPage => 5, currentPage => 1, startEntry => 1}) };
like($@, qr/^currentPage and startEntry can not both be supplied /, 'caught invalid parameter set');

$pageInfo = Data::SpreadPagination->new({
  totalEntries => $config{totalEntries}, entriesPerPage => $config{entriesPerPage}, startEntry => 5
});
is($pageInfo->current_page, 1, 'entry 5 on /10 is page 1');
is($pageInfo->first, 1, '...and top of page 1 is entry 1');

$pageInfo = Data::SpreadPagination->new({
  totalEntries => $config{totalEntries}, entriesPerPage => $config{entriesPerPage}, startEntry => 10
});
is($pageInfo->current_page, 1, 'entry 10 on /10 is page 1');
is($pageInfo->first, 1, '...and top of page 1 is entry 1');

$pageInfo = Data::SpreadPagination->new({
  totalEntries => $config{totalEntries}, entriesPerPage => $config{entriesPerPage}, startEntry => 11
});
is($pageInfo->current_page, 2, 'entry 11 on /10 is page 2');
is($pageInfo->first, 11, '...and top of page 2 is entry 11');

$pageInfo = Data::SpreadPagination->new({
  totalEntries => $config{totalEntries}, entriesPerPage => $config{entriesPerPage}, startEntry => 12
});
is($pageInfo->current_page, 2, 'entry 12 on /10 is page 2');
is($pageInfo->first, 11, '...and top of page 2 is entry 11');


my $name;
while (defined (my $line = <DATA>)) {
  chomp $line;
  next unless $line;

  my ($totalEntries, $entriesPerPage, $maxPages, $currentPage);

  if ($line =~ /^# ?(.+)/) {
    $name = $1;
    my $config = <DATA>;
    ($totalEntries, $entriesPerPage, $maxPages) = $config =~ /^(\d+) +(\d+) +(\d+)/g;
  }

  for my $page (1..($totalEntries / $entriesPerPage)) {
    $pageInfo = Data::SpreadPagination->new({
      totalEntries => $totalEntries,
      entriesPerPage => $entriesPerPage,
      maxPages => $maxPages,
      currentPage => $page,
    });

    my $expected = <DATA>;
    my ($exp_page_ranges, $exp_spread) = $expected =~ /^([^\s]+) +([^\s]+)/g;
    my $exp_spread_raw = $exp_spread;
    $exp_spread_raw =~ s/undef,?//g;
    $exp_spread_raw =~ s/,?$//g;

    is(
      join(':', map { defined $_ ? join(',', @{$_}) : 'undef' } $pageInfo->page_ranges),
      $exp_page_ranges,
      "$name: page_ranges($page/L)"
    );
    is(
      join(':', map { defined $_ ? join(',', @{$_}) : 'undef' } @{scalar $pageInfo->page_ranges}),
      $exp_page_ranges,
      "$name: page_ranges($page/S)"
    );
#     print join(':', map { defined $_ ? join(',', @{$_}) : 'undef' } $pageInfo->page_ranges) . " ";

    is(join(',', $pageInfo->pages_in_spread_raw), $exp_spread_raw, "$name: pages_in_spread_raw($page/L)");
    is(join(',', @{scalar $pageInfo->pages_in_spread_raw}), $exp_spread_raw, "$name: pages_in_spread_raw($page/S)");

 #   print join(',', map { defined $_ ? $_ : 'undef' } $pageInfo->pages_in_spread) . "\n";
    is(
      join(',', map { defined $_ ? $_ : 'undef' } $pageInfo->pages_in_spread),
      $exp_spread,
      "$name: pages_in_spread($page/L)"
    );
    is(
      join(',', map { defined $_ ? $_ : 'undef' } @{scalar $pageInfo->pages_in_spread}),
      $exp_spread,
      "$name: pages_in_spread($page/S)"
    );
  }
}

#my $expected_page_ranges = [undef, undef, undef, [2, 20]];
#my $page_ranges = $pageInfo->page_ranges;
#is_deeply($expected_page_ranges, $page_ranges, 'page ranges are as expected in scalar context');
#my @page_ranges = $pageInfo->page_ranges;
#is_deeply($expected_page_ranges, \@page_ranges, '...and also in list context');


__DATA__
# All visible
100 10 9
undef:undef:undef:2,10  1,2,3,4,5,6,7,8,9,10
1,1:undef:undef:3,10    1,2,3,4,5,6,7,8,9,10
1,2:undef:undef:4,10    1,2,3,4,5,6,7,8,9,10
1,3:undef:undef:5,10    1,2,3,4,5,6,7,8,9,10
1,4:undef:undef:6,10    1,2,3,4,5,6,7,8,9,10
1,5:undef:undef:7,10    1,2,3,4,5,6,7,8,9,10
1,6:undef:undef:8,10    1,2,3,4,5,6,7,8,9,10
1,7:undef:undef:9,10    1,2,3,4,5,6,7,8,9,10
1,8:undef:undef:10,10   1,2,3,4,5,6,7,8,9,10
1,9:undef:undef:undef   1,2,3,4,5,6,7,8,9,10


# 20 pages 10+1 visible
200 10 10
undef:undef:2,7:17,20   1,2,3,4,5,6,7,undef,17,18,19,20
1,1:undef:3,7:17,20     1,2,3,4,5,6,7,undef,17,18,19,20
1,2:undef:4,8:18,20     1,2,3,4,5,6,7,8,undef,18,19,20
1,2:3,3:5,8:18,20       1,2,3,4,5,6,7,8,undef,18,19,20
1,2:3,4:6,9:19,20       1,2,3,4,5,6,7,8,9,undef,19,20
1,2:3,5:7,9:19,20       1,2,3,4,5,6,7,8,9,undef,19,20
1,2:4,6:8,10:19,20      1,2,undef,4,5,6,7,8,9,10,undef,19,20
1,2:5,7:9,11:19,20      1,2,undef,5,6,7,8,9,10,11,undef,19,20
1,2:6,8:10,12:19,20     1,2,undef,6,7,8,9,10,11,12,undef,19,20
1,2:7,9:11,13:19,20     1,2,undef,7,8,9,10,11,12,13,undef,19,20
1,2:8,10:12,14:19,20    1,2,undef,8,9,10,11,12,13,14,undef,19,20
1,2:9,11:13,15:19,20    1,2,undef,9,10,11,12,13,14,15,undef,19,20
1,2:10,12:14,16:19,20   1,2,undef,10,11,12,13,14,15,16,undef,19,20
1,2:11,13:15,17:19,20   1,2,undef,11,12,13,14,15,16,17,undef,19,20
1,2:12,14:16,18:19,20   1,2,undef,12,13,14,15,16,17,18,19,20
1,2:12,15:17,18:19,20   1,2,undef,12,13,14,15,16,17,18,19,20
1,3:13,16:18,18:19,20   1,2,3,undef,13,14,15,16,17,18,19,20
1,3:13,17:undef:19,20   1,2,3,undef,13,14,15,16,17,18,19,20
1,4:14,18:undef:20,20   1,2,3,4,undef,14,15,16,17,18,19,20
1,4:14,19:undef:undef   1,2,3,4,undef,14,15,16,17,18,19,20


# ridiculously small maximum
100 10 2
undef:undef:2,3:undef   1,2,3,undef
undef:1,1:3,3:undef     undef,1,2,3,undef
undef:2,2:4,4:undef     undef,2,3,4,undef
undef:3,3:5,5:undef     undef,3,4,5,undef
undef:4,4:6,6:undef     undef,4,5,6,undef
undef:5,5:7,7:undef     undef,5,6,7,undef
undef:6,6:8,8:undef     undef,6,7,8,undef
undef:7,7:9,9:undef     undef,7,8,9,undef
undef:8,8:10,10:undef   undef,8,9,10,undef
undef:8,9:undef:undef   undef,8,9,10

# even more silly maximum
100 10 0
undef:undef:undef:undef 1,undef
undef:undef:undef:undef undef,2,undef
undef:undef:undef:undef undef,3,undef
undef:undef:undef:undef undef,4,undef
undef:undef:undef:undef undef,5,undef
undef:undef:undef:undef undef,6,undef
undef:undef:undef:undef undef,7,undef
undef:undef:undef:undef undef,8,undef
undef:undef:undef:undef undef,9,undef
undef:undef:undef:undef undef,10

