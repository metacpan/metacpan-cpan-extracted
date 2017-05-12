use t::lib;
use strict;
use Config;
use Getopt::Long;
use File::Basename qw(fileparse);
use File::Spec;
use List::Util qw(min max);
use Test::More;
use autodbRunTests;

# preamble copied from autodbRunTests::runtests_main
my($details,$nested,$basenum);
GetOptions ('details=i'=>\$details,'nested=i'=>\$nested,'basenum=s'=>\$basenum);
$nested=1 if !defined $nested && defined $basenum; # basenum implies nested
$details=1 if !defined $details && $nested; # nested implies details
my($script,$testdir,$skip)=fileparse($0);

my $testdir=testdir {testcode=>1};
my @put_types=qw(put put_multi put_objects put_objects_multi);
my @get_types=qw(get find find-getnext);
my @testfiles;

########################################
# this sections deals w/ 010 basic putget tests
my $testfile=File::Spec->catfile($testdir,scriptcode.'.010.01.get.t');

# my $count_get=`perl -Mblib $testfile count`;
# code below copied from perlvar
my $secure_perl_path = $Config{perlpath};
if ($^O ne 'VMS')
  {$secure_perl_path .= $Config{_exe} unless $secure_perl_path =~ m/$Config{_exe}$/i;}
#####
# invoke perl via full (secure) path. provide defualt just in case...
my $count_get=`$secure_perl_path -Mblib $testfile count` || 17;

my @files=
  ('putget.010.00.put.t put',
   # do all 3 query types for first case
   map {"putget.010.01.get.t 0 $_"} @get_types);
#    'putget.010.01.get.t 0 get',
#    'putget.010.01.get.t 0 find',
#    'putget.010.01.get.t 0 find-getnext');
# cycle once through the put & get types
my $count=max(scalar @put_types,scalar @get_types);
my $i;
for ($i=1; $i<$count; $i++) {
  my $first_case=$i % $count_get;
  my $put_type=$put_types[$i % scalar @put_types];
  my $get_type=$get_types[$i % scalar @get_types];
  push(@files,"putget.010.00.put.t $put_type","putget.010.01.get.t $first_case $get_type");
}
# cycle through the get types for the rest
for (; $i<$count_get; $i++) {
  my $first_case=$i % $count_get;
  my $get_type=$get_types[$i % scalar @get_types];
  push(@files,"putget.010.01.get.t $first_case $get_type");
}
# 02 & 03 scripts test queries with no args and SQL args. do all get_types
push(@files,map {"putget.010.02.no_args.t $_"} @get_types);
push(@files,map {"putget.010.03.sql.t $_"} @get_types);
push(@testfiles,\@files);

########################################
# this sections deals w/ 012 mechanics tests
my @files;
for my $put_type (@put_types) {
  push(@files,"putget.012.00.mechanics.t 0 0 $put_type");
}
for my $get_type (@get_types) {
  push(@files,"putget.012.01.mechanics.t 0 0 $get_type");
}
#   for my $num_objects (1..3) {
#     for my $list_count (0..3) {
#       for my $put_type (@put_types) {
# 	push(@files,"putget.012.00.mechanics.t $num_objects $list_count $put_type");
#       }
#       for my $get_type (@get_types) {
# 	push(@files,"putget.012.01.mechanics.t $num_objects $list_count $get_type");
#       }}}
# exhaustive loop too big. just cycle through cases
my $i=0;
for my $num_objects (1..3) {
  for my $list_count (0..3) {
    my $put_type=$put_types[$i % scalar @put_types];
    my $get_type=$get_types[$i % scalar @get_types];
    push(@files,"putget.012.00.mechanics.t $num_objects $list_count $put_type");
    push(@files,"putget.012.01.mechanics.t $num_objects $list_count $get_type");
    $i++;
  }
}
push(@testfiles,\@files);

########################################
# this sections deals w/ 015 all_types tests. do the main 'get' tests with get & find
my @files=
  ('putget.015.00.all_types.t',
   'putget.015.01.all_types.t get',
   'putget.015.01.all_types.t find',
   'putget.015.10.ez_put.t',
   'putget.015.11.ez_get.t',
   'putget.015.12.ez_get1key.t get',
   'putget.015.12.ez_get1key.t find',
   'putget.015.13.ez_get2keys.t get',
   'putget.015.13.ez_get2keys.t find',
   'putget.015.14.ez_growing.t get',
   'putget.015.14.ez_growing.t find',
   'putget.015.15.ez_empty.t get',
   'putget.015.15.ez_empty.t find');
push(@testfiles,\@files);

my $ok=runtests {testcode=>1,details=>$details,nested=>$nested,basenum=>$basenum},@testfiles;
ok($ok,$script);

done_testing();
