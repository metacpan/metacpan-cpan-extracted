# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-Range-Compare-Stream.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 13;

BEGIN { use_ok('Data::Range::Compare::Stream::Iterator::Consolidate::FileAsc') };

#########################

# most tests require this file to exist!
my $exists;
my $filename;

# guess file locations
foreach my $location (qw(file_test.src t/file_test.src)) {
  $exists=-r $location;
  $filename=$location;
  last if $exists;
}


# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#
# Basic Constructor tests

{
  my $bad_args=Data::Range::Compare::Stream::Iterator::Consolidate::FileAsc->new;
  ok($bad_args->in_error,'no file should show an error state') or diag(Dumper($bad_args));
}

SKIP: {
  skip 'Cannot read from file_test.src',12 unless $exists;
  
  my $s=new Data::Range::Compare::Stream::Iterator::Consolidate::FileAsc(filename=>$filename);
  ok($s,'instance should exist!');
  ok(!$s->in_error,'Instance should not be in error!');
  
  ok($s->has_next,'instance should have next');

  cmp_ok($s->get_next,'eq','Commoon Range: [1 - 2] Starting range: [1 - 2] Ending Range: [1 - 2]','first row should be: 1 - 2');
  ok($s->has_next,'instance should have row 2');
  cmp_ok($s->get_next,'eq','Commoon Range: [3 - 4] Starting range: [3 - 4] Ending Range: [3 - 4]','first row should be: 3 - 4');

  ok($s->has_next,'instance should have row 3');
  cmp_ok($s->get_next,'eq','Commoon Range: [5 - 6] Starting range: [5 - 6] Ending Range: [5 - 6]','first row should be: 7 - 8');

  ok($s->has_next,'instance should have row 3');
  cmp_ok($s->get_next,'eq','Commoon Range: [7 - 8] Starting range: [7 - 8] Ending Range: [7 - 8]','first row should be: 1 - 2');

  ok(!$s->has_next,'instance should have no more rows!');
}

