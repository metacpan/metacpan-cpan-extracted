use strict;
use warnings;

use Test::More tests => 35;
use Test::Deep;
use Arepa::PackageDb;

use constant TEST_DATABASE => 't/compilation_queue_test.db';

unlink TEST_DATABASE;
my $pdb = Arepa::PackageDb->new(TEST_DATABASE);

# Create some source package to make tests with
my %attrs = (name         => 'dhelp',
             full_version => '0.6.18',
             architecture => 'any',
             distribution => 'unstable');
$pdb->insert_source_package(%attrs);
my $source_id = $pdb->get_source_package_id($attrs{name},
                                            $attrs{full_version});

my @queue_before = $pdb->get_compilation_queue;
is(scalar @queue_before, 0,
   "The compilation queue should be empty initially");
my ($comp1_arch, $comp1_dist, $comp1_tstamp) = ("i386", "lenny", "20090422");
$pdb->request_compilation($source_id,
                          $comp1_arch,
                          $comp1_dist,
                          $comp1_tstamp);

my @queue1 = $pdb->get_compilation_queue;
is(scalar @queue1, 1, "The queue should have one element");

cmp_deeply($queue1[0],
           {id                       => ignore(),
            source_package_id        => $source_id,
            architecture             => $comp1_arch,
            distribution             => $comp1_dist,
            builder                  => undef,
            status                   => 'pending',
            compilation_requested_at => $comp1_tstamp,
            compilation_started_at   => undef,
            compilation_completed_at => undef},
           "The first compilation should be correct");
cmp_deeply({ $pdb->get_compilation_request_by_id($queue1[0]->{id}) },
           {id                       => $queue1[0]->{id},
            source_package_id        => $source_id,
            architecture             => $comp1_arch,
            distribution             => $comp1_dist,
            builder                  => undef,
            status                   => 'pending',
            compilation_requested_at => $comp1_tstamp,
            compilation_started_at   => undef,
            compilation_completed_at => undef},
           "Getting the compilation request by id should succeed");

my ($comp2_arch, $comp2_dist, $comp2_tstamp) = ("amd64", "lenny", "20090423");
$pdb->request_compilation($source_id,
                          $comp2_arch,
                          $comp2_dist,
                          $comp2_tstamp);

my @queue2 = $pdb->get_compilation_queue;
is(scalar @queue2, 2, "The queue should have two elements");

cmp_deeply($queue2[1],
           {id                       => ignore(),
            source_package_id        => $source_id,
            architecture             => $comp2_arch,
            distribution             => $comp2_dist,
            builder                  => undef,
            status                   => 'pending',
            compilation_requested_at => $comp2_tstamp,
            compilation_started_at   => undef,
            compilation_completed_at => undef},
           "The first compilation should be correct");

is(scalar $pdb->get_compilation_queue(status => 'pending'),
   2,
   "The queue filtered by status 'pending' should have two elements");
is(scalar $pdb->get_compilation_queue(status => 'pending', limit => 1),
   1,
   "The limit parameter should be honoured");
is(scalar $pdb->get_compilation_queue(status => 'pending', limit => 2),
   2,
   "The limit parameter shouldn't break anything if there's only that much data");
is(scalar $pdb->get_compilation_queue(status => 'pending', limit => 3),
   2,
   "The limit parameter shouldn't produce _more_ results than otherwise");

is(scalar $pdb->get_compilation_queue(status => 'compiling'),
   0,
   "The queue filtered by status 'compiling' should be empty");
is(scalar $pdb->get_compilation_queue(status => 'compiling', limit => 1),
   0,
   "The limit parameter shouldn't produce _more_ results than otherwise");


# Now, get the id for the compilation queue elements, and mark them
my ($comp1_id, $comp2_id) = ($queue2[0]->{id}, $queue2[1]->{id});

# Mark as compiling ----------------------------------------------------------
my $builder_name = 'some_builder';
$pdb->mark_compilation_started($comp1_id, $builder_name);

my @compiling_queue1 = $pdb->get_compilation_queue(status => 'compiling');
is(scalar @compiling_queue1,
   1,
   "The element being compiled should appear");
is($compiling_queue1[0]->{id}, $comp1_id,
   "The compiled element id is correct");
is($compiling_queue1[0]->{builder}, $builder_name,
   "The builder name should be correct");
my @pending_queue1 = $pdb->get_compilation_queue(status => 'pending');
is(scalar @pending_queue1,
   1,
   "After compiling, there should be only one pending element");
is($pending_queue1[0]->{id}, $comp2_id,
   "The pending element id is correct");
is(scalar $pdb->get_compilation_queue(status => 'compiled'),
   0,
   "There shouldn't be any compiled packages yet");
is(scalar $pdb->get_compilation_queue(status => 'compilationfailed'),
   0,
   "There shouldn't be any failing-to-compile packages yet");


# Mark as compiled -----------------------------------------------------------
$pdb->mark_compilation_completed($comp1_id);

is(scalar $pdb->get_compilation_queue(status => 'compiling'),
   0,
   "There shouldn't be any compiling packages anymore");
my @compiled_queue2 = $pdb->get_compilation_queue(status => 'compiled');
is(scalar @compiled_queue2,
   1,
   "The compiled element should appear");
is($compiled_queue2[0]->{id}, $comp1_id,
   "The compiled element id is correct");
my @pending_queue2 = $pdb->get_compilation_queue(status => 'pending');
is(scalar @pending_queue2,
   1,
   "After being compiled, the pending element should stay there");
is($pending_queue2[0]->{id}, $comp2_id,
   "The pending element id is correct");


# Mark as compilationfailed --------------------------------------------------
$pdb->mark_compilation_failed($comp1_id);

is(scalar $pdb->get_compilation_queue(status => 'compiling'),
   0,
   "There shouldn't be any compiling packages anymore");
is(scalar $pdb->get_compilation_queue(status => 'compiled'),
   0,
   "There shouldn't be any compiled packages anymore");
my @failed_queue3 = $pdb->get_compilation_queue(status => 'compilationfailed');
is(scalar @failed_queue3,
   1,
   "The compilation failed element should appear");
is($failed_queue3[0]->{id}, $comp1_id,
   "The compilation failed element id is correct");
my @pending_queue3 = $pdb->get_compilation_queue(status => 'pending');
is(scalar @pending_queue3,
   1,
   "After the compilation failing, the pending element should stay there");
is($pending_queue3[0]->{id}, $comp2_id,
   "The pending element id is correct");


# Requeue (mark as pending) --------------------------------------------------
$pdb->mark_compilation_pending($comp1_id);

is(scalar $pdb->get_compilation_queue(status => 'compiling'),
   0,
   "There shouldn't be any compiling packages anymore");
is(scalar $pdb->get_compilation_queue(status => 'compiled'),
   0,
   "There shouldn't be any compiled packages anymore");
is(scalar $pdb->get_compilation_queue(status => 'compilationfailed'),
   0,
   "There shouldn't be any failed compilation packages anymore");
my @pending_queue4 = $pdb->get_compilation_queue(status => 'pending');
is(scalar @pending_queue4,
   2,
   "The new request should be correctly marked as pending");
is_deeply([ sort { $a <=> $b }
                 ($comp1_id, $comp2_id) ],
          [ sort { $a <=> $b }
                 map { $_->{id} }
                     @pending_queue4 ],
          "The pending element ids are correct");
