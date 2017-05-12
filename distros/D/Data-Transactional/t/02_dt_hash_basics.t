#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 19;

use File::stat;  # an OO-ish module that has been in the core since forever

my $obj = stat('Makefile.PL');

BEGIN { use_ok('Data::Transactional') }

# NB some tests are done in parallel on tied and untied data structures
# as a sanity check
my $tied;
my $untied;

# create correct types of transactional whatsit
ok($tied = Data::Transactional->new(), "create obj with all defaults");
ok($tied->{pie} = 'meat', "... which we can use as a hash");
$tied = Data::Transactional->new();
ok(!eval { $tied->[0] = 'meat' }, "... and not as an array");
ok($tied = Data::Transactional->new(type => 'hash'), "specifically create a hash");
ok($tied->{pie} = 'meat', "... which we can use as a hash");
ok(!eval { $tied->{chips} = $obj }, "can't store objects in a hash");

# tests for a hash
$tied = Data::Transactional->new();
$untied = {};
$untied->{llama}   = $tied->{llama}   = 'Lama glama';
$untied->{alpaca}  = $tied->{alpaca}  = 'Lama pacos';
$untied->{guanaco} = $tied->{guanaco} = 'Lama guanicoe';
$untied->{vicuna}  = $tied->{vicuna}  = 'Vicugna vicugna';
ok($tied->{llama} eq 'Lama glama', "retrieve a record correctly");
ok(join('', sort keys %{$tied}) eq join('', sort keys %{$untied}), "keys works");
ok(join('', sort values %{$tied}) eq join('', sort values %{$untied}), "values works");
my($key, $value) = each(%{$tied});
ok(
    ($key eq 'llama'   && $value eq 'Lama glama') ||
    ($key eq 'alpaca'  && $value eq 'Lama pacos') ||
    ($key eq 'guanaco' && $value eq 'Lama guanicoe') ||
    ($key eq 'vicuna'  && $value eq 'Vicugna vicugna'),
    "each works");
# iterate to end
each(%{$tied});
each(%{$tied});
each(%{$tied});
each(%{$untied});each(%{$untied});each(%{$untied});each(%{$untied});
($key, $value) = each(%{$tied});
my ($key2, $value2) = each(%{$untied});
ok(!defined($key) && !defined($key2), "each fails correctly at the end");
($key, $value) = each(%{$tied});
ok(
    ($key eq 'llama'   && $value eq 'Lama glama') ||
    ($key eq 'alpaca'  && $value eq 'Lama pacos') ||
    ($key eq 'guanaco' && $value eq 'Lama guanicoe') ||
    ($key eq 'vicuna'  && $value eq 'Vicugna vicugna'),
    "each restarts correctly");
# put a hash into the hash
$tied->{'and in latin'} = { reverse %{$tied} };
ok(exists($tied->{'and in latin'}), "put a hash into the hash and it exists");
ok(join('', sort keys %{$tied->{'and in latin'}}) eq 'Lama glamaLama guanicoeLama pacosVicugna vicugna', "subhash has correct keys");
ok(join('', sort values %{$tied->{'and in latin'}}) eq 'alpacaguanacollamavicuna', "subhash has correct values");

ok(delete $tied->{llama} eq 'Lama glama' && delete $untied->{llama} eq 'Lama glama', "delete seems to work");
ok(!exists($tied->{llama}) && !exists($untied->{llama}), "... and the deleted value no longer exists (according to exists()!)");
ok(join('', sort keys %{$tied}) eq 'alpacaand in latinguanacovicuna', "... and according to keys");
