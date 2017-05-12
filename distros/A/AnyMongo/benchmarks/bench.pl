#!/usr/bin/env perl
use strict;
use warnings;
use AnyMongo;
use MongoDB;
use DateTime;
use feature 'say';
use Benchmark qw(:all);

my $tries = 50000;

my $small_doc = {};

my $medium_doc = {
  'integer' => 5,
  'number' => 5.05,
  'boolean' => 0,
  'array' => ['test', 'benchmark']
};

my $large_doc = {
  'base_url' => 'http://www.example.com/test-me',
  'total_word_count' => 6743,
  'access_time' => DateTime->now,
  'meta_tags' => {
    'description' => 'i am a long description string',
    'author' => 'Holly Man',
    'dynamically_created_meta_tag' => 'who know\n what'
  },
  'page_structure' => {
    'counted_tags' => 3450,
    'no_of_js_attached' => 10,
    'no_of_images' => 6
  },
  'harvested_words' => ['10gen','web','open','source','application','paas',
                        'platform-as-a-service','technology','helps',
                        'developers','focus','building','mongodb','mongo'] * 20
};

my $sub_insert = sub {
    my ($col,$doc) = @_;
    $col->insert($doc);
};

my $sub_query = sub {
    my ($col) = @_;
    my $cursor = $col->find;
    do {
    } while($cursor->next);
};

my $mongo_con = MongoDB::Connection->new(host => 'mongodb://127.0.0.1');
my $any_con = AnyMongo->new_connection(host => 'mongodb://127.0.0.1');

my $mongo_col = $mongo_con->get_database('anymongo_bench')->get_collection('bench');
my $any_col = $any_con->get_database('anymongo_bench')->get_collection('bench2');

$|= 1;

say "bench insert docs ...";

cmpthese($tries,{
    'mongo-perl-driver' => sub { $sub_insert->($mongo_col,$large_doc) },
    'anymongo' => sub{ $sub_insert->($any_col,$large_doc) }
});


say "bench query/cursor ...";

cmpthese(1,{
    'mongo-perl-driver' => sub { $sub_query->($mongo_col) },
    'anymongo' => sub{ $sub_query->($any_col) }
});

$mongo_con->get_database('anymongo_bench')->drop;

