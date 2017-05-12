#!/usr/bin/perl -w

use strict;

use lib qw( ./blib/lib ../blib/lib );

use Test::More tests => 554;

# Check we can load module
BEGIN { use_ok( 'Data::Pageset' ); }

#######
# new()
#######
eval {
	Data::Pageset->new();
};
like($@,qr/total_entries and entries_per_page must be supplied/,'new - Croak when no params');

eval {
	Data::Pageset->new({
		'total_entries' => 12,
	});
};
like($@,qr/total_entries and entries_per_page must be supplied/,'new - Croak when no entries_per_page');

eval {
	Data::Pageset->new({
		'entries_per_page' => 3,
	});
};
like($@,qr/total_entries and entries_per_page must be supplied/,'new - Croak when no entries_per_page');

eval {
	Data::Pageset->new({
		'total_entries' => 12,
		'entries_per_page' => -2,
	});
};
like($@,qr/Fewer than one entry per page/,'new - Croak when num entries_per_page is negative');


my $dp = Data::Pageset->new({
	'total_entries' => '23',
	'entries_per_page' => '2',
});
is($dp->current_page(),'1','new - Default current page of 1 set');

$dp = Data::Pageset->new({
	'total_entries' => '23',
	'entries_per_page' => '2',
	'current_page' => -90,
});
is($dp->current_page(),'1','new - Default current page of 1 set when current_page less than first_page');

$dp = Data::Pageset->new({
	'total_entries' => '20',
	'entries_per_page' => '10',
	'current_page' => 9,
});
is($dp->current_page(),'2','new - Default current page set to last page when current_page greater than last_page');

######
# pages_per_set
######

is($dp->pages_per_set(),10,'pages_per_set - get undef when not defined');

$dp = Data::Pageset->new({
	'total_entries' => '20',
	'entries_per_page' => '10',
	'current_page' => 4,
	'pages_per_set' => 2,
});

$dp = Data::Pageset->new({
	'total_entries' => '20',
	'entries_per_page' => '10',
	'current_page' => 4,
	'pages_per_set' => -2,
});

#####
# Current_page()
######

$dp = Data::Pageset->new({
	'total_entries' => '20',
	'entries_per_page' => '10',
});

#is($dp->current_page(),1,'Got default current page as 1, when none set');

############
# General tests
############

# Some configs for testing
my %config = (
	'total_entries'		=> 300,
	'entries_per_page'	=> 10,
	'current_page'		=> 17
);

my $page_info = Data::Pageset->new({
	'total_entries'       => $config{'total_entries'}, 
	'entries_per_page'    => $config{'entries_per_page'}, 
	'current_page'		  => $config{'current_page'},
});

isa_ok($page_info,'Data::Pageset');

$page_info->pages_per_set(2);

is($page_info->pages_per_set(),2,'pages_per_set - got 2 as exected');

is('19',$page_info->next_set(),'Know that the next set is 2');

is('15',$page_info->previous_set(),'Know that the next set is 11');

is('17 18',join(' ',@{$page_info->pages_in_set()}),'Pages returned correctly');

is($config{'current_page'},$page_info->current_page(),'Current page matches');

my $name;

my $t = 0;

foreach my $line (<DATA>) {
  chomp $line;
  next unless $line;

  if ($line =~ /^# ?(.+)/) {
    $name = $1;
    next;
  }
  my @vals = map { $_ = undef if $_ eq 'undef'; $_ } split /\s+/, $line;

  my $page = Data::Pageset->new({
  	'total_entries'		=> $vals[0],
	'entries_per_page'	=> $vals[1],
	'current_page'		=> $vals[2],
	'pages_per_set'		=> $vals[3],
	'mode'			=> $vals[15],
  });

  my @integers = (0..$vals[0]);
  @integers = $page->splice(\@integers);
  my $integers = join ',', @integers;
  my $page_nums = join ',', @{$page->pages_in_set()};
  
  is($page->first_page, $vals[4], "$name: first page");
  is($page->last_page, $vals[5], "$name: last page");
  is($page->first, $vals[6], "$name: first");
  is($page->last, $vals[7], "$name: last");
  is($page->previous_page, $vals[8], "$name: previous_page");
  is($page->current_page, $vals[9], "$name: current_page");
  is($page->next_page, $vals[10], "$name: next_page");
  is($integers, $vals[11], "$name: splice");
  is($page->next_set(), $vals[12], "$name: next_set");
  is($page->previous_set(), $vals[13], "$name: previous_set");
  is($page_nums, $vals[14], "$name: pages_in_set");

#  my $ps = Data::Pageset->new({
#  	'total_entries'		=> $vals[0],
#	'entries_per_page'	=> $vals[1],
#	'current_page'		=> $page->previous_set,
#	'pages_per_set'		=> $vals[3],
#	'mode'			=> $vals[15],
#  });
#  my $ns = Data::Pageset->new({
#  	'total_entries'		=> $vals[0],
#	'entries_per_page'	=> $vals[1],
#	'current_page'		=> $page->next_set,
#	'pages_per_set'		=> $vals[3],
#	'mode'			=> $vals[15],
#  });
#
#  diag("totent($vals[0]) epp($vals[1]) cp($vals[9]) pps($vals[3])\n");
#  diag("previous set pis: ", join(",",@{$ps->pages_in_set()}), "\n") if($page->previous_set);
#  diag("    this set pis: ", join(",",@{$page->pages_in_set()}), "\n");
#  diag("    next set pis: ", join(",",@{$ns->pages_in_set()}), "\n") if($page->next_set);

}

# 0: total_entries
# 1: entries_per_page
# 2: current_page
# 3: pages_per_set
# 4: first_page number
# 5: last_page number
# 6: first entry on page
# 7: last last entry on page
# 8: previous_page
# 9: current_page
# 10: next_page
# 11: results on current page
# 12: next_set
# 13: previous_set
# 14: page numbers for set
# 15: mode
 
__DATA__
# Initial test
50 10 1 1   1 5 1 10 undef 1 2 0,1,2,3,4,5,6,7,8,9 2 undef 1
50 10 2 4   1 5 11 20 1 2 3 10,11,12,13,14,15,16,17,18,19 5 undef 1,2,3,4
50 10 3 undef   1 5 21 30 2 3 4 20,21,22,23,24,25,26,27,28,29 undef undef 1,2,3,4,5
50 10 4 2   1 5 31 40 3 4 5 30,31,32,33,34,35,36,37,38,39 5 1 3,4
50 10 5 1   1 5 41 50 4 5 undef 40,41,42,43,44,45,46,47,48,49 undef 4 1

# Under 10
1 10 1 4   1 1 1 1 undef 1 undef 0 undef undef 1
2 10 1 5   1 1 1 2 undef 1 undef 0,1  undef undef 1
3 10 1 6   1 1 1 3 undef 1 undef 0,1,2 undef undef 1
4 10 1 7   1 1 1 4 undef 1 undef 0,1,2,3 undef undef 1
5 10 1 undef   1 1 1 5 undef 1 undef 0,1,2,3,4 undef undef 1
6 10 1 9   1 1 1 6 undef 1 undef 0,1,2,3,4,5 undef undef 1
7 10 1 10   1 1 1 7 undef 1 undef 0,1,2,3,4,5,6 undef undef 1
8 10 1 undef   1 1 1 8 undef 1 undef 0,1,2,3,4,5,6,7 undef undef 1
9 10 1 12   1 1 1 9 undef 1 undef 0,1,2,3,4,5,6,7,8 undef undef 1
10 10 1 13   1 1 1 10 undef 1 undef 0,1,2,3,4,5,6,7,8,9 undef undef 1

# Over 10
11 10 1 2   1 2 1 10 undef 1 2 0,1,2,3,4,5,6,7,8,9 undef undef 1,2
11 10 2 3   1 2 11 11 1 2 undef 10 undef undef 1,2
12 10 1 undef   1 2 1 10 undef 1 2 0,1,2,3,4,5,6,7,8,9 undef undef 1,2
12 10 2 5   1 2 11 12 1 2 undef 10,11  undef undef 1,2
13 10 1 6   1 2 1 10 undef 1 2 0,1,2,3,4,5,6,7,8,9  undef undef 1,2
13 10 2 7   1 2 11 13 1 2 undef 10,11,12 undef undef 1,2

# Under 20
19 10 1 2   1 2 1 10 undef 1 2 0,1,2,3,4,5,6,7,8,9 undef undef 1,2
19 10 2 3   1 2 11 19 1 2 undef 10,11,12,13,14,15,16,17,18 undef undef 1,2
20 10 1 undef   1 2 1 10 undef 1 2 0,1,2,3,4,5,6,7,8,9 undef undef 1,2
20 10 2 5   1 2 11 20 1 2 undef 10,11,12,13,14,15,16,17,18,19 undef undef 1,2

# Over 20
21 10 1 5   1 3 1 10 undef 1 2 0,1,2,3,4,5,6,7,8,9 undef undef 1,2,3
21 10 2 5   1 3 11 20 1 2 3 10,11,12,13,14,15,16,17,18,19 undef undef 1,2,3
21 10 3 5   1 3 21 21 2 3 undef 20 undef undef 1,2,3
22 10 1 5   1 3 1 10 undef 1 2 0,1,2,3,4,5,6,7,8,9 undef undef 1,2,3
22 10 2 10   1 3 11 20 1 2 3 10,11,12,13,14,15,16,17,18,19 undef undef 1,2,3
22 10 3 10   1 3 21 22 2 3 undef 20,21 undef undef 1,2,3
23 10 1 10   1 3 1 10 undef 1 2 0,1,2,3,4,5,6,7,8,9 undef undef 1,2,3
23 10 2 undef   1 3 11 20 1 2 3 10,11,12,13,14,15,16,17,18,19 undef undef 1,2,3
23 10 3 10   1 3 21 23 2 3 undef 20,21,22 undef undef 1,2,3

# Slide - no sliding (to low pages)
1 10 1 4   1 1 1 1 undef 1 undef 0 undef undef 1 slide
89 10 1 10 1 9 1 10 undef 1 2 0,1,2,3,4,5,6,7,8,9 undef undef 1,2,3,4,5,6,7,8,9 slide

# Slide - no sliding (current page to low)
89 10 1 10 1 9 1 10 undef 1 2 0,1,2,3,4,5,6,7,8,9 undef undef 1,2,3,4,5,6,7,8,9 slide
89 10 4 10 1 9 31 40 3 4 5 30,31,32,33,34,35,36,37,38,39 undef undef 1,2,3,4,5,6,7,8,9 slide

# Slide - sliding
89 10 4 10 1 9 31 40 3 4 5 30,31,32,33,34,35,36,37,38,39 undef undef 1,2,3,4,5,6,7,8,9 slide
999 10 20 9 1 100 191 200 19 20 21 190,191,192,193,194,195,196,197,198,199 29 11 16,17,18,19,20,21,22,23,24 slide
999 10 11 9 1 100 101 110 10 11 12 100,101,102,103,104,105,106,107,108,109 20 2 7,8,9,10,11,12,13,14,15 slide
999 10 20 10 1 100 191 200 19 20 21 190,191,192,193,194,195,196,197,198,199 30 10 16,17,18,19,20,21,22,23,24,25 slide
1070 20 54 15 1 54 1061 1070 53 54 undef 1060,1061,1062,1063,1064,1065,1066,1067,1068,1069 undef 32 40,41,42,43,44,45,46,47,48,49,50,51,52,53,54 slide 
209 10 5 5 1 21 41 50 4 5 6 40,41,42,43,44,45,46,47,48,49 10 1 3,4,5,6,7 slide

# High pages - shift left two
500 20 21 5 1 25 401 420 20 21 22    400,401,402,403,404,405,406,407,408,409,410,411,412,413,414,415,416,417,418,419 26    16 19,20,21,22,23 slide
# High pages - shift left one    
500 20 22 5 1 25 421 440 21 22 23    420,421,422,423,424,425,426,427,428,429,430,431,432,433,434,435,436,437,438,439 27    17 20,21,22,23,24 slide
# High pages - first fixed    
500 20 23 5 1 25 441 460 22 23 24    440,441,442,443,444,445,446,447,448,449,450,451,452,453,454,455,456,457,458,459 undef 18 21,22,23,24,25 slide
# High pages - penultimate fixed    
500 20 24 5 1 25 461 480 23 24 25    460,461,462,463,464,465,466,467,468,469,470,471,472,473,474,475,476,477,478,479 undef 18 21,22,23,24,25 slide
# High pages - final page    
500 20 25 5 1 25 481 500 24 25 undef 480,481,482,483,484,485,486,487,488,489,490,491,492,493,494,495,496,497,498,499 undef 18 21,22,23,24,25 slide        
