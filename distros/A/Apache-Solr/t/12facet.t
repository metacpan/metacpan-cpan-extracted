#!/usr/bin/env perl
# Test decoding the complex Facet structure.
# Try all examples from http://wiki.apache.org/solr/SimpleFacetParameters

use warnings;
use strict;

use lib 'lib';
use Apache::Solr::XML;
use Log::Report  'try';

use Test::More tests => 17;

use Data::Dumper;
$Data::Dumper::Indent    = 1;
$Data::Dumper::Quotekeys = 0;

# the server will not be called in this script.
my $server = 'http://localhost:8080/solr';
my $core   = 'my-core';

my $solr = Apache::Solr::XML->new(server => $server, core => $core);
ok(defined $solr, 'instantiated client');

sub decode_xml($)
{   my $xml  = shift;
    my $tree = $solr->xmlsimple->XMLin($xml);
    Apache::Solr::XML::_cleanup_parsed($tree);
}

sub check_get($$$)
{   my ($url, $params, $test) = @_;

    # take the parameters from the url
    $url =~ s/.*\?//;
    my @url = map { split /\=/, $_, 2 } split /\&/, $url;
    s/\+/ /g,s/%([a-zA-Z0-9]{2})/chr hex $1/ge for @url;

    # the order may be important, but ignored for these tests
    my $expanded = $solr->expandSelect(%$params);
#warn Dumper \@url, $expanded;
    is_deeply({@url}, {@$expanded}, $test);
}

### Facet Fields

check_get
   "$server/select?q=ipod&rows=0&facet=true&facet.limit=-1&facet.field=cat&facet.field=inStock",
  { q => 'ipod', rows => 0
  , facet => { limit => -1, field => [ qw/cat inStock/ ] }
  }, 'example 1 get';

my $f1 = <<'_FACET_FIELDS1';
<response>
<responseHeader><status>0</status><QTime>2</QTime></responseHeader>
<result numFound="4" start="0"/>
<lst name="facet_counts">
 <lst name="facet_queries"/>
 <lst name="facet_fields">
  <lst name="cat">
        <int name="search">0</int>
        <int name="memory">0</int>
        <int name="graphics">0</int>
        <int name="card">0</int>
        <int name="music">1</int>
        <int name="software">0</int>
        <int name="electronics">3</int>
        <int name="copier">0</int>
        <int name="multifunction">0</int>
        <int name="camera">0</int>
        <int name="connector">2</int>
        <int name="hard">0</int>
        <int name="scanner">0</int>
        <int name="monitor">0</int>
        <int name="drive">0</int>
        <int name="printer">0</int>
  </lst>
  <lst name="inStock">
        <int name="false">3</int>
        <int name="true">1</int>
  </lst>
 </lst>
</lst>
</response>
_FACET_FIELDS1

my $d1 =
{
  responseHeader => { status => '0', QTime => '2' },
  facet_counts => {
    facet_fields => {
      cat => { printer => '0', search => '0', copier => '0', monitor => '0',
        drive => '0', music => '1', connector => '2', camera => '0',
        scanner => '0', software => '0', card => '0', graphics => '0',
        memory => '0', multifunction => '0', electronics => '3', hard => '0'
      },
      inStock => { false => '3', true => '1' }
    },
    facet_queries => {}
  },
  result => { numFound => '4', start => '0' }
};

is_deeply(decode_xml($f1), $d1, 'example 1 xml');

### Facet Fields with No Zeros
check_get
'http://localhost:8983/solr/select?q=ipod&rows=0&facet=true&facet.limit=-1&facet.field=cat&facet.mincount=1&facet.field=inStock',
  { q => 'ipod', rows => 0
  , facet => { limit => -1, field => [ qw/cat inStock/ ], mincount => 1 }
  }, 'example 2 get';

my $f2 = <<'_FACET_FIELDS2';
<response>
<responseHeader><status>0</status><QTime>3</QTime></responseHeader>
<result numFound="4" start="0"/>
<lst name="facet_counts">
 <lst name="facet_queries"/>
 <lst name="facet_fields">
  <lst name="cat">
        <int name="music">1</int>
        <int name="connector">2</int>
        <int name="electronics">3</int>
  </lst>
  <lst name="inStock">
        <int name="false">3</int>
        <int name="true">1</int>
  </lst>
 </lst>
</lst>
</response>
_FACET_FIELDS2

my $d2 = {
  responseHeader => { status => '0', QTime => '3' },
  facet_counts => {
    facet_fields => {
      cat => { music => '1', connector => '2', electronics => '3' },
      inStock => { false => '3', true => '1' }
    },
    facet_queries => {}
  },
  result => { numFound => '4', start => '0' }
};

is_deeply(decode_xml($f2), $d2, 'example 2 xml');

### Facet Fields with No Zeros And Missing Count For One Field
check_get
'http://localhost:8983/solr/select?q=ipod&rows=0&facet=true&facet.limit=-1&facet.field=cat&f.cat.facet.missing=true&facet.mincount=1&facet.field=inStock',
  { q => 'ipod', rows => 0
  , facet => {limit => -1, field => [qw/cat inStock/], mincount => 1}
  , f_cat_facet => {missing => 1}
  }, 'example 3 get';

# weird field: <int>1</int>
my $f3 = <<'_FACET_FIELDS3';
<response>
<responseHeader><status>0</status><QTime>3</QTime></responseHeader>
<result numFound="4" start="0"/>
<lst name="facet_counts">
 <lst name="facet_queries"/>
 <lst name="facet_fields">
  <lst name="cat">
        <int name="music">1</int>
        <int name="connector">2</int>
        <int name="electronics">3</int>
        <int>1</int>
  </lst>
  <lst name="inStock">
        <int name="false">3</int>
        <int name="true">1</int>
  </lst>
 </lst>
</lst>
</response>
_FACET_FIELDS3

my $d3 =  {
  responseHeader => { status => '0', QTime => '3' },
  facet_counts => {
    facet_fields => {
      cat => { '' => '1', music => '1', connector => '2', electronics => '3' },
      inStock => { false => '3', true => '1' }
    },
    facet_queries => {}
  },
  result => { numFound => '4', start => '0' }
};

#warn Dumper decode_xml($f3);
is_deeply(decode_xml($f3), $d3, 'example 3 xml');

### Facet Field with Limit
check_get
  'http://localhost:8983/solr/select?rows=0&q=inStock:true&facet=true&facet.field=cat&facet.limit=5',
  { q => 'inStock:true', rows => 0
  , facet => { field => 'cat', limit => 5 }
  }, 'example 4 get';

my $f4 = <<'_FACET_FIELDS4';
<response>
<responseHeader><status>0</status><QTime>4</QTime></responseHeader>
<result numFound="12" start="0"/>
<lst name="facet_counts">
 <lst name="facet_queries"/>
 <lst name="facet_fields">
  <lst name="cat">
        <int name="electronics">10</int>
        <int name="memory">3</int>
        <int name="drive">2</int>
        <int name="hard">2</int>
        <int name="monitor">2</int>
  </lst>
 </lst>
</lst>
</response>
_FACET_FIELDS4

my $d4 = {
  responseHeader => { status => '0', QTime => '4' },
  facet_counts => {
    facet_fields => {
      cat => { memory => '3', drive => '2', monitor => '2',
        electronics => '10', hard => '2' }
    },
    facet_queries => {}
  },
  result => { numFound => '12', start => '0' }
};

#warn Dumper decode_xml($f4);
is_deeply(decode_xml($f4), $d4, 'example 4 xml');

### Facet Fields and Facet Queries
check_get
  'http://localhost:8983/solr/select?q=video&rows=0&facet=true&facet.field=inStock&facet.query=price:[*+TO+500]&facet.query=price:[500+TO+*]',
  { q => 'video', rows => 0
  , facet =>
      { field => 'inStock'
      , query => [ 'price:[* TO 500]', 'price:[500 TO *]']
      }
  }, 'example 5 get';

my $f5 = <<'_FACET_FIELDS5';
<response>
<responseHeader><status>0</status><QTime>11</QTime></responseHeader>
<result numFound="3" start="0"/>
<lst name="facet_counts">
 <lst name="facet_queries">
  <int name="price:[* TO 500]">2</int>
  <int name="price:[500 TO *]">1</int>
 </lst>
 <lst name="facet_fields">
  <lst name="inStock">
        <int name="false">2</int>
        <int name="true">1</int>
  </lst>
 </lst>
</lst>
</response>
_FACET_FIELDS5

my $d5 =  {
  responseHeader => { status => '0', QTime => '11' },
  facet_counts => {
    facet_fields => { inStock => { false => '2', true => '1' } },
    facet_queries => { 'price:[500 TO *]' => '1', 'price:[* TO 500]' => '2' }
  },
  result => { numFound => '3', start => '0' }
};

#warn Dumper decode_xml($f5);
is_deeply(decode_xml($f5), $d5, 'example 5 xml');

### Facet prefix (term suggest)
check_get     #XXX huh?  Ruby?  on -> true on index and facet
  'http://localhost:8983/solr/select?q=hatcher&wt=ruby&indent=true&facet=true&rows=0&facet.field=text&facet.prefix=xx&facet.limit=5&facet.mincount=1',
  { q => 'hatcher', wt => 'ruby', indent => 'on', rows => 0
  , facet => {field => 'text', prefix => 'xx', limit => 5, mincount => 1}
  }, 'example 6 get';


my $f6 = <<'_FACET_FIELDS6';
{
'responseHeader'=>{
  'status'=>0,
  'QTime'=>88,
  'params'=>{
        'facet.limit'=>'5',
        'wt'=>'ruby',
        'rows'=>'0',
        'facet'=>'true',
        'facet.mincount'=>'1',
        'facet.field'=>'text',
        'indent'=>'on',
        'facet.prefix'=>'xx',
        'q'=>'hatcher'}},
'response'=>{'numFound'=>90,'start'=>0,'docs'=>[]
},
'facet_counts'=>{
  'facet_queries'=>{},
  'facet_fields'=>{
        'text'=>[
         'xx',7,
         'xxxviii',2,
         'xx909337',1,
         'xxvi',1] } } 
_FACET_FIELDS6

### Date Faceting: per day for the past 5 days
try {  # catch 'deprecated warning'
check_get
  'http://localhost:8983/solr/select/?q=*:*&rows=0&facet=true&facet.date=timestamp&facet.date.start=NOW/DAY-5DAYS&facet.date.end=NOW/DAY%2B1DAY&facet.date.gap=%2B1DAY',
  { q => '*:*', rows => 0
  , facet => { date => 'timestamp', date_gap => '+1DAY'
             , date_start => 'NOW/DAY-5DAYS', date_end => 'NOW/DAY+1DAY'}
  }, 'example 7 get';
};

my @ex = $@->exceptions;
cmp_ok(scalar @ex, '==', 1, 'exceptions');
is("$ex[0]","warning: deprecated solr main::check_get(facet.date) since 3.1\n");


my $f7 = <<'_FACET_FIELDS7';
<response>
<lst name="responseHeader">
 <int name="status">0</int>
 <int name="QTime">5</int>
 <lst name="params">
  <str name="facet.date">timestamp</str>
  <str name="facet.date.end">NOW/DAY+1DAY</str>
  <str name="facet.date.gap">+1DAY</str>
  <str name="rows">0</str>
  <str name="facet">true</str>
  <str name="facet.date.start">NOW/DAY-5DAYS</str>
  <str name="indent">true</str>
  <str name="q">*:*</str>
 </lst>
</lst>
<result name="response" numFound="42" start="0"/>
<lst name="facet_counts">
 <lst name="facet_queries"/>
 <lst name="facet_fields"/>
 <lst name="facet_dates">
  <lst name="timestamp">
        <int name="2007-08-11T00:00:00.000Z">1</int>
        <int name="2007-08-12T00:00:00.000Z">5</int>
        <int name="2007-08-13T00:00:00.000Z">3</int>
        <int name="2007-08-14T00:00:00.000Z">7</int>
        <int name="2007-08-15T00:00:00.000Z">2</int>
        <int name="2007-08-16T00:00:00.000Z">16</int>
        <str name="gap">+1DAY</str>
        <date name="end">2007-08-17T00:00:00Z</date>
  </lst>
 </lst>
</lst>
</response>
_FACET_FIELDS7

my $d7 =  {
  responseHeader => {
    params => {
      facet => 'true', indent => 'true', q => '*:*', rows => '0',
      'facet.date.end' => 'NOW/DAY+1DAY', 'facet.date.gap' => '+1DAY',
      'facet.date.start' => 'NOW/DAY-5DAYS', 'facet.date' => 'timestamp'
    },
    status => '0', QTime => '5'
  },
  facet_counts => {
    facet_fields => {},
    facet_dates => {
      timestamp => {
        '2007-08-11T00:00:00.000Z' => '1',
        '2007-08-15T00:00:00.000Z' => '2',
        '2007-08-13T00:00:00.000Z' => '3',
        '2007-08-12T00:00:00.000Z' => '5',
        '2007-08-14T00:00:00.000Z' => '7',
        '2007-08-16T00:00:00.000Z' => '16',
        end => '2007-08-17T00:00:00Z',
        gap => '+1DAY'
      }
    },
    facet_queries => {}
  },
  result => { name => 'response', numFound => '42', start => '0' }
};

#warn Dumper decode_xml($f7);
is_deeply(decode_xml($f7), $d7, 'example 7 xml');

### Pivot (ie Decision Tree) Faceting
check_get
  'http://localhost:8983/solr/select?q=*:*&facet.pivot=cat,popularity,inStock&facet.pivot=popularity,cat&facet=true&facet.field=cat&facet.limit=5&rows=0&wt=json&indent=true&facet.pivot.mincount=0',
  { q => '*:*', rows => 0, wt => 'json', indent => 1
  , facet => { pivot => [ 'cat,popularity,inStock', 'popularity,cat' ]
             , pivot_mincount => 0, field => 'cat', limit => 5 }
  }, 'example 8 get';

my $f8 = <<'_FACET_FIELDS8';
"facet_pivot":{
      "cat,popularity,inStock":[{
          "field":"cat",
          "value":"electronics",
          "count":14,
          "pivot":[{
              "field":"popularity",
              "value":"6",
              "count":5,
              "pivot":[{
                  "field":"inStock",
                  "value":"true",
                  "count":5}]},
            {
              "field":"popularity",
              "value":"7",
              "count":4,
              "pivot":[{
                  "field":"inStock",
                  "value":"false",
                  "count":2},
                {
                  "field":"inStock",
                  "value":"true",
                  "count":2}]},
            {
...
_FACET_FIELDS8
