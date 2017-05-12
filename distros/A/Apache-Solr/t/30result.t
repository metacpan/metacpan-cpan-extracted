#!/usr/bin/perl
# Test decoding the complex results
# Try all examples from http://wiki.apache.org/solr/SearchHandler

use warnings;
use strict;

use lib 'lib';
use Apache::Solr::XML;

use Test::More tests => 5;

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

### Results

my $f1 = <<'_RESULT1';
<?xml version="1.0" encoding="UTF-8"?>
<response>
<responseHeader><status>0</status><QTime>1</QTime></responseHeader>

<result numFound="1" start="0">
 <doc>
  <arr name="cat"><str>electronics</str><str>hard drive</str></arr>
  <arr name="features"><str>7200RPM, 8MB cache, IDE Ultra ATA-133</str><str>NoiseGuard, SilentSeek technology, Fluid Dynamic Bearing (FDB) motor</str></arr>

  <str name="id">SP2514N</str>
  <bool name="inStock">true</bool>
  <str name="manu">Samsung Electronics Co. Ltd.</str>
  <str name="name">Samsung SpinPoint P120 SP2514N - hard drive - 250 GB - ATA-133</str>
  <int name="popularity">6</int>
  <float name="price">92.0</float>

  <str name="sku">SP2514N</str>
 </doc>
</result>
</response>
_RESULT1

my $d1 = {
  responseHeader => { status => '0', QTime => '1' },
  result => {
    numFound => '1',
    doc => {
      sku => 'SP2514N',
      features => [
        '7200RPM, 8MB cache, IDE Ultra ATA-133',
        'NoiseGuard, SilentSeek technology, Fluid Dynamic Bearing (FDB) motor'
      ],
      name => 'Samsung SpinPoint P120 SP2514N - hard drive - 250 GB - ATA-133',
      manu => 'Samsung Electronics Co. Ltd.',
      cat => [ 'electronics', 'hard drive' ],
      popularity => '6',
      price => '92.0',
      id => 'SP2514N',
      inStock => 1
    },
    start => '0'
  }
};

#warn "DECODED: ", Dumper decode_xml($f1);
is_deeply(decode_xml($f1), $d1, 'example 1 xml');

### A limited number of fields, plus the scores of the first 2 documents in the result set

my $f2 = <<'_RESULT2';
<?xml version="1.0" encoding="UTF-8"?>
<response>
<responseHeader><status>0</status><QTime>6</QTime></responseHeader>

<result numFound="14" start="0" maxScore="1.0851374">
 <doc>
  <float name="score">1.0851374</float>
  <str name="id">F8V7067-APL-KIT</str>
  <str name="name">Belkin Mobile Power Cord for iPod w/ Dock</str>

 </doc>
 <doc>
  <float name="score">0.68052477</float>
  <str name="id">IW-02</str>
  <str name="name">iPod &amp; iPod Mini USB 2.0 Cable</str>
 </doc>

</result>
</response>
_RESULT2

my $d2 = {
  responseHeader => { status => '0', QTime => '6' },
  result => {
    maxScore => '1.0851374',
    numFound => '14',
    doc => [
      {
        name => 'Belkin Mobile Power Cord for iPod w/ Dock',
        score => '1.0851374',
        id => 'F8V7067-APL-KIT'
      },
      {
        name => 'iPod & iPod Mini USB 2.0 Cable',
        score => '0.68052477',
        id => 'IW-02'
      }
    ],
    start => '0'
  }
};

#warn "DECODED: ", Dumper decode_xml($f2);
is_deeply(decode_xml($f2), $d2, 'example 2 xml');

### The second document in the result set with debugging info
# http://yourhost.tld:9999/solr/select?q=cat:electronics+Belkin&version=2.1&start=1&rows=1&indent=on&fl=id+name+score&debugQuery=on

my $f3 = <<'_RESULT3';
<?xml version="1.0" encoding="UTF-8"?>
<response>
<responseHeader><status>0</status><QTime>13</QTime></responseHeader>

<result numFound="14" start="1" maxScore="1.0851374">
 <doc>
  <float name="score">0.68052477</float>
  <str name="id">IW-02</str>
  <str name="name">iPod &amp; iPod Mini USB 2.0 Cable</str>

 </doc>
</result>
<lst name="debug">
 <str name="querystring">cat:electronics Belkin</str>
 <str name="parsedquery">cat:electronics text:belkin</str>
 <lst name="explain">
  <str name="id=IW-02,internal_docid=3">
0.6805248 = sum of:
  0.22365452 = weight(cat:electronics in 3), product of:
    0.35784724 = queryWeight(cat:electronics), product of:
      1.0 = idf(docFreq=14)
      0.35784724 = queryNorm
      ...
</str>
 </lst>

</lst>
</response>
_RESULT3

my $d3 = {
  responseHeader => { status => '0', QTime => '13' },
  debug => {
    parsedquery => 'cat:electronics text:belkin',
    querystring => 'cat:electronics Belkin',
    explain => {
      'id=IW-02,internal_docid=3' => '
0.6805248 = sum of:
  0.22365452 = weight(cat:electronics in 3), product of:
    0.35784724 = queryWeight(cat:electronics), product of:
      1.0 = idf(docFreq=14)
      0.35784724 = queryNorm
      ...
'
    }
  },
  result => {
    maxScore => '1.0851374',
    numFound => '14',
    doc => {
      name => 'iPod & iPod Mini USB 2.0 Cable',
      score => '0.68052477',
      id => 'IW-02'
    },
    start => '1'
  }
};

#warn "DECODED: ", Dumper decode_xml($f3);
is_deeply(decode_xml($f3), $d3, 'example 3 xml');

### One document with highlighting
# http://localhost:8983/solr/select/?stylesheet=&q=solr+xml&version=2.1&start=0&rows=10&indent=on&hl=true&hl.fl=features,sku&hl.snippets=3

my $f4 = <<'_RESULT4';
<?xml version="1.0" encoding="UTF-8"?>
<response>
<responseHeader><status>0</status><QTime>3</QTime></responseHeader>

<result numFound="1" start="0">
 <doc>
  <arr name="cat"><str>software</str><str>search</str></arr>
  <arr name="features"><str>Advanced Full-Text Search Capabilities using Lucene</str><str>Optimizied for High Volume Web Traffic</str><str>Standards Based Open Interfaces - XML and HTTP</str>

        <str>Comprehensive HTML Administration Interfaces</str><str>Scalability - Efficient Replication to other Solr Search Servers</str><str>Flexible and Adaptable with XML configuration and Schema</str><str>Good unicode support: héllo (hello with an accent over the e)</str></arr>
  <str name="id">SOLR1000</str>
  <bool name="inStock">true</bool>
  <str name="manu">Apache Software Foundation</str>
  <str name="name">Solr, the Enterprise Search Server</str>

  <int name="popularity">10</int>
  <float name="price">0.0</float>
  <str name="sku">SOLR1000</str>
 </doc>
</result>
<lst name="highlighting">
 <lst name="SOLR1000">
  <arr name="features">

        <str>Standards Based Open Interfaces - &lt;em>XML&lt;/em> and HTTP</str>
        <str>Scalability - Efficient Replication to other &lt;em>Solr&lt;/em> Search Servers</str>
        <str>Flexible and Adaptable with &lt;em>XML&lt;/em> configuration and Schema</str>
  </arr>

  <arr name="sku">
        <str>&lt;em>SOLR&lt;/em>1000</str>
  </arr>
 </lst>
</lst>
</response>
_RESULT4

my $d4 = {
  responseHeader => { status => '0', QTime => '3' },
  result => {
    numFound => '1',
    doc => {
      sku => 'SOLR1000',
      features => [
        'Advanced Full-Text Search Capabilities using Lucene',
        'Optimizied for High Volume Web Traffic',
        'Standards Based Open Interfaces - XML and HTTP',
        'Comprehensive HTML Administration Interfaces',
        'Scalability - Efficient Replication to other Solr Search Servers',
        'Flexible and Adaptable with XML configuration and Schema',
        "Good unicode support: h\x{e9}llo (hello with an accent over the e)"
      ],
      name => 'Solr, the Enterprise Search Server',
      manu => 'Apache Software Foundation',
      cat => [ 'software', 'search' ],
      popularity => '10',
      price => '0.0',
      id => 'SOLR1000',
      inStock => 1
    },
    start => '0'
  },
  highlighting => {
    SOLR1000 => {
      sku => [ '<em>SOLR</em>1000' ],
      features => [
        'Standards Based Open Interfaces - <em>XML</em> and HTTP',
        'Scalability - Efficient Replication to other <em>Solr</em> Search Servers',
        'Flexible and Adaptable with <em>XML</em> configuration and Schema'
      ]
    }
  },
};

#warn "DECODED: ", Dumper decode_xml($f4);
is_deeply(decode_xml($f4), $d4, 'example 4 xml');
