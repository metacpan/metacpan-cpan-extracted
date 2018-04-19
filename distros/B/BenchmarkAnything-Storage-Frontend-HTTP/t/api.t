use Mojo::Base -strict;

use Test::Deep 'cmp_bag', 'cmp_deeply', 'superhashof';
use Test::More;
use Test::Mojo;
use JSON;
use File::Slurper;
require BenchmarkAnything::Storage::Frontend::Lib;

my $t;
my $json;
my $data;
my $query;
my $balib;
my $expected;
my $got;

my $cfgfile   = "t/benchmarkanything.cfg";
my $dsn       = 'dbi:SQLite:t/benchmarkanything.sqlite';

$ENV{BENCHMARKANYTHING_CONFIGFILE} = $cfgfile;

sub verify {
        my ($input, $output, $fields) = @_;

        for (my $i=0; $i < @$input; $i++) {
                my $got      = $output->[$i];
                my $expected = $input->[$i];
                foreach my $field (@$fields) {
                        is($got->{$field},  $expected->{$field},  "re-found [$i].$field = $expected->{$field}");
                }
        }
}

# --------------------------------------------------------------------
# Careful here!
#
# We use BA::S::F.:Lib as direcly connecting Perl lib, i.e.,
# configured with 'frontend:lib' mode, in it's role to prepare the
# database for the tests before the server starts.
#
# This config is also ok for the BA::S::F::HTTP because it should
# directly access the DB (via BenchmarkAnything::Storage::Backend::SQL), i.e., in
# 'frontend:lib' mode.
#
# We can *NOT* configure it as frontend:http because that would
# contact the HTTP server which uses the same config and would by
# itself try forward the requests to HTTP - a short circuit.
#
# Should you ever want this, create 2 separate configfiles, and
# provide them explicitely, separated by the purpose: in $balib here
# the normal lib, and vie $ENV{BENCHMARKANYTHING_CONFIGFILE} to the
# HTTP server.
# --------------------------------------------------------------------

diag "\nUsing DSN: '$dsn'";

$balib = BenchmarkAnything::Storage::Frontend::Lib
 ->new(really  => $dsn,
       verbose => 0,
       debug   => 0,
      )
 ->connect;
is ($balib->{config}{benchmarkanything}{storage}{backend}{sql}{dsn}, $dsn, "config - dsn");

diag "\n========== submit data ==========";

# Create and fill test DB
$balib->createdb;

# test instance
$t = Test::Mojo->new('BenchmarkAnything::Storage::Frontend::HTTP');

# listnames on empty DB
$t->get_ok('/api/v1/listnames')
 ->status_is(200)
 ->json_is([]);

# listkeys on empty DB
$t->get_ok('/api/v1/listkeys')
 ->status_is(200)
 ->json_is([]);

# search
$t->get_ok('/api/v1/search')->status_is(200);

# submit data
$json = File::Slurper::read_text('t/valid-benchmark-anything-data-01.json');
$data = JSON::decode_json($json);
$t->post_ok('/api/v1/add' => {Accept => '*/*'} => json => $data);

# listnames after add
$t->get_ok('/api/v1/listnames')
 ->status_is(200)
 ->json_is([qw( benchmarkanything.test.metric )]);

# submit more data
$json = File::Slurper::read_text('t/valid-benchmark-anything-data-02.json');
$data = JSON::decode_json($json);
$t->post_ok('/api/v1/add' => {Accept => '*/*'} => json => $data);

# listnames after add
$t->get_ok('/api/v1/listnames')->status_is(200);
$got = $t->tx->res->json;
$expected = [qw( benchmarkanything.test.metric
                 benchmarkanything.test.metric.3
                 benchmarkanything.test.metric.2
                 benchmarkanything.test.metric.1
                 another.benchmarkanything.test.metric.1
                 another.benchmarkanything.test.metric.2
              )];
cmp_bag($got, $expected, "listnames");

# listkeys after add
$t->get_ok('/api/v1/listkeys')->status_is(200);
$got = $t->tx->res->json;
$expected = [qw( comment compiler keyword )];
cmp_bag($got, $expected, "listkeys");

diag "\n========== Search ==========";

# Create and fill test DB
$balib->createdb;

# fill data
$json = File::Slurper::read_text('t/valid-benchmark-anything-data-02.json');
$data = JSON::decode_json($json);
$t->post_ok('/api/v1/add' => {Accept => '*/*'} => json => $data);

# get data point
$t->get_ok('/api/v1/search/2');
$got      = $t->tx->res->json;
$expected = {
             "NAME"     => "benchmarkanything.test.metric.2",
             "VALUE"    => 34.56789,
             "comment"  => "another float value",
             "compiler" => "icc",
             "keyword"  => "zomtec",
            };
cmp_deeply($got, superhashof($expected), "search/:id to get single point");

# Create and fill test DB
$balib->createdb;

# fill data
$json = File::Slurper::read_text('t/valid-benchmark-anything-data-01.json');
$data = JSON::decode_json($json);
$t->post_ok('/api/v1/add' => {Accept => '*/*'} => json => $data);

# search data
$json = File::Slurper::read_text('t/query-benchmark-anything-03.json');
$query = JSON::decode_json($json);
$t->post_ok('/api/v1/search' => {Accept => '*/*'} => json => $query);
$got      = $t->tx->res->json;
$expected = JSON::decode_json(File::Slurper::read_text('t/query-benchmark-anything-03-expectedresult.json'));
verify($got, $expected, [qw(NAME VALUE comment compiler keyword)]);


diag "\n========== Stats ==========";

# Create and fill test DB
$balib->createdb;

# fill data
$json = File::Slurper::read_text('t/valid-benchmark-anything-data-02.json');
$data = JSON::decode_json($json);
$t->post_ok('/api/v1/add' => {Accept => '*/*'} => json => $data);

# simple counts
$t->get_ok('/api/v1/stats')->status_is(200);
$got = $t->tx->res->json;
is($got->{count_datapoints}, 8, "stats - count data points");
#is($got->{count_metrics},    5, "stats - count metrics");
#is($got->{count_keys},       3, "stats - count keys");

done_testing();
