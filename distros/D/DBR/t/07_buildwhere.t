#!/usr/bin/perl

use strict;
use warnings;
no warnings 'uninitialized';
use Time::HiRes;
use DBR::Util::Operator;
use Carp;

$| = 1;

use lib './lib';
use t::lib::Test;
use Test::More;


use Data::Dumper;
use Getopt::Std;
my %opts;
getopts('dbqvl:',\%opts);
$opts{d} = 1;

sub okq {
      my ($test,$msg) = @_;
      if ($test){
	    pass($msg) if !$opts{q};
      }else{
	    fail($msg);
      }
      return $test;
}
my $testct = 0;
my $loops = $opts{l} || 10000;

# As always, it's important that the sample database is not tampered with, otherwise our tests will fail
my $dbr = setup_schema_ok('music');

my $session = $dbr->session;

my $instance = $dbr->get_instance('music') or die "Failed to retrieve DB instance";
ok($instance, 'dbr instance');

my $schema = $instance->schema or die "Failed to retrieve schema";
ok($schema, 'dbr schema');

test(
     [ album_id => 2 ],
     'album_id = 2'
    );
test(
     [ album_id => 1, rating   => 'earbleed' ],
     'album_id = 1 AND rating = 900'
    );
test(
     [ album_id => 1, AND rating   => 'earbleed' ],
     'album_id = 1 AND rating = 900'
    );

test(
     [
      album_id => 2,
      name     => 'Track BA2',
      rating   => 'earbleed',
      date_released => GT 'November 26th 2005 PST'
     ],
     "album_id = 2 AND date_released > 1132992000 AND name = 'Track BA2' AND rating = 900"
    );

test([
      album_id => 2,
      OR name     => 'Track BA2',
      OR rating   => 'earbleed',
      OR date_released => GT 'November 26th 2005 PST'
     ],
     "album_id = 2 OR (name = 'Track BA2' OR (rating = 900 OR date_released > 1132992000))"
    );

test([
      album_id => 2,
      AND name => 'Track BA2',
      AND rating => 'earbleed',
      AND date_released => GT 'November 26th 2005 PST'
     ],
     "album_id = 2 AND date_released > 1132992000 AND name = 'Track BA2' AND rating = 900"
    );

test([
      (
       ( album_id => 1, AND rating => 'earbleed' ),
       OR album_id => 789 
      ),   # closing peren ends the list of args to OR
      date_released => GT 'November 26th 2005 PST',
     ],
     "((album_id = 1 AND rating = 900) OR album_id = 789) AND date_released > 1132992000"
    );

test([
      album_id => 1,
      AND (rating   => 'earbleed', OR album_id => 789 ),
      AND date_released => GT 'November 26th 2005 PST'
     ],
     "(rating = 900 OR album_id = 789) AND album_id = 1 AND date_released > 1132992000"
     );
test([
      date_released => GT 'November 26th 2005 PST',
      album_id => 1,
      OR (album_id => 2, rating => 'earbleed'),
      OR (album_id => 3)
     ],
     "((album_id = 1 AND date_released > 1132992000) OR (album_id = 2 AND rating = 900)) OR album_id = 3"
    );

test([
      date_released => GT 'November 26th 2005 PST',
      AND (
	   album_id => 1,
	   OR (album_id => 2, rating => 'earbleed'),
	   OR (album_id => 3)
	  )
     ],
     "((album_id = 1 OR (album_id = 2 AND rating = 900)) OR album_id = 3) AND date_released > 1132992000"
    );

test([
      'artist.name'      => 'Artist A',
      'artist.artist_id' => 1
     ],
     "(b.artist_id = 1 AND b.name = 'Artist A') AND a.artist_id = b.artist_id"
    );

test([
      'artist.name' => 'Artist A',
      AND
      'artist.artist_id' => 1
     ],
     "(b.artist_id = 1 AND b.name = 'Artist A') AND a.artist_id = b.artist_id"
    );

test([
      (
       'artist.name' => 'Artist A',
       AND
       'artist.artist_id' => 1
      ),
      OR
      'artist.name' => 'Artist B',
     ],
     "((b.artist_id = 1 AND b.name = 'Artist A') AND a.artist_id = b.artist_id) OR (c.name = 'Artist B' AND a.artist_id = c.artist_id)"
    );

test([
      'artist.name' => 'Artist A',
      AND (
	   'artist.artist_id' => 1,
	   OR
	   'artist.name' => 'Artist B'
	  )
     ], # A little less than efficient SQL-wise... but technically correct
     "((c.artist_id = 1 AND a.artist_id = c.artist_id) OR (d.name = 'Artist B' AND a.artist_id = d.artist_id)) AND b.name = 'Artist A' AND a.artist_id = b.artist_id"
    );
test(
     [ album_id => [1,2], rating   => 'earbleed' ],
     'album_id IN (1,2) AND rating = 900'
    );

done_testing();
exit;


sub test{
      my $where = shift;
      my $reference_sql   = shift;

      $testct++;
      my $conn = $instance->connect('conn');
      okq($conn,'Connect');

      my $table = $schema->get_table( 'album' ) or die("failed to look up table");

      my $builder = DBR::Interface::Where->new(
					       session       => $session,
					       instance      => $instance,
					       primary_table => $table,
					      ) or die("Failed to create wherebuilder");

      my $output = $builder->build( $where );
      okq($output,"Test build $testct");

      my $sql = $output->sql($conn);
      okq($sql,"Produce sql");

      diag ("SQL:  $sql");
      diag ("WANT: $reference_sql") if ! $opts{'q'};
      okq( $sql eq $reference_sql,"SQL correctness check");

      my ($start,$end,$seconds);
      my $before = Dumper($where);
      if ($opts{d}) {
	    $start = Time::HiRes::time();
	    my $rv;
	    for (1..$loops) {
		  $rv = $builder->digest( $where ) || confess 'Failed to build where';
	    }
	    diag "DIGEST: $rv" if $opts{v}; 
	    diag "DIGEST CLEAR: " . $builder->digest_clear( $where ) if $opts{v};

	    $end = Time::HiRes::time();

	    $seconds = $end - $start;

	    diag("Digest benchmark $testct took $seconds seconds. (" . sprintf("%0.4d",$loops / $seconds). " digests per second)");
      }

      my $after = Dumper($where);
      okq( $before eq $after, "Before/after reference check");
      # HERE HERE HERE - FIX THIS: Benchmarking currently doesn't work with joins cus of an inability to reset aliases

      if( $opts{b} ){

	    $start = Time::HiRes::time();
	    for (1..$loops){
		  my $rv  = $builder->build( $where ) || confess 'Failed to build where';
		  my $sql = $rv->sql( $conn )     || confess 'Failed to generate SQL';
	    }
	    $end = Time::HiRes::time();
	    $seconds = $end - $start;
	    diag("Build/SQL Benchmark $testct took $seconds seconds. (" . sprintf("%0.4d",$loops / $seconds). " query builds per second)");
      }
}
