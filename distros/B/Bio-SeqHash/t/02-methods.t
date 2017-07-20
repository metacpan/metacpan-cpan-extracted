#!/usr/bin/env perl
use Modern::Perl;
use Test::More;
use IO::All;

my $module;
BEGIN {
  $module = 'Bio::SeqHash';
  use_ok($module);
}
my @attrs = qw();
my @methods = qw(fa2hs get_id_seq get_seq get_seqs_batch);
can_ok($module, $_) for @attrs;
can_ok($module, $_) for @methods;

done_testing
