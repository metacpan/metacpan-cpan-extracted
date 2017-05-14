#!/usr/bin/perl

use lib '.','./blib/lib','..';
use strict;
use warnings;
use Test::More tests=>36;

BEGIN { use_ok('Bio::Das'); }
require_ok('Bio::Das');

# first test 1.5 spec
my $db = Bio::Das->new(-server=>'http://www.plantgdb.org/AtGDB/cgi-bin/das');
ok($db,'open database');
BAIL_OUT("can't perform tests because database won't open") 
    unless $db;  # can't continue

# test sources
my @sources = $db->sources;
ok(@sources > 1,'sources method');
my $d = 'AtGDB';
ok(grep(/$d/,@sources),'sources conent');
ok($sources[0]->description,'source description');
ok($sources[0]->name,'source name');

# test types()
$db->dsn($sources[0]);
my @types = $db->types;
ok(@types>1,'types fetch');

# test segment()
my $s = $db->segment(-ref=>'1',-start=>10_000,-stop=>20_000);
ok($s,'segment method returns a segment');
my @features;

SKIP: {
    skip "couldn't get segment",15 unless $s;

    my $dna = $s->dna;
    ok($dna,'dna fetch');
    is(length $dna,10001,'dna length');

    # test features
    @features = $s->features();
    ok(scalar @features,'feature fetch');

    is($features[0]->seq_id,1,'feature seq_id is same as requested');
    ok($features[0]->start<=20_000 && $features[0]->end>=10_000,
       'feature position overlaps requested range');

    my @groups = grep {$_->category eq 'group'} @features;

  SKIP2: {
      skip "no groups to test",2 unless @groups;
      is($groups[0]->category,'group',"group doesn't match");
      ok($groups[0]->get_SeqFeatures > 0,"group has subfeatures");
    };

    # see if we can't get some transcrips
    my @t = grep {  $_->method eq 'expressed_sequence_alignment'} @features;
    ok(scalar @t,'got expected types');

    # find the first one that has subfeatures
    my (@e,$t);
    for (@t) {
	$t = $_;
	@e = $_->get_SeqFeatures;
	last if @e > 1;
    }
    ok($t,'found a group with subfeatures');
    is($e[0]->source,$t[0]->source,'parent source==child source');

    @e = sort {$a->start<=>$b->start} @e;
    ok($t->category,'group');
  
    # are the start and end correct?
    is($e[0]->start,$t->start,'starts match');
    is($e[-1]->stop,$t->stop,'stops match');

    # is there a link, and are they the same?
    is($t->link,$e[0]->link,'parent and chid links match');

    # do features handle the segments call
    ok($e[0]->can('segments'),'features support segments()');
};

# test stylesheet
my $ss = $db->stylesheet;
ok($ss,'stylesheet fetch');

SKIP3: {
    skip 'no features to test',1,unless @features && $ss;
    my ($glyph,@args) = $ss->glyph($features[0]);
    is($glyph,'hat','correct glyph mapping');
};

# test parallel interface
$db = Bio::Das->new(5);
my $response = $db->features(-dsn     => 'http://www.plantgdb.org/AtGDB/cgi-bin/das/AtGDB',
			     -segment => ['1:1,10000',
					  '2:10000,20000']
    );
ok($response,'parallel fetch initializes');
ok($response->is_success,'parallel fetch successful');
my $results = $response->results;
ok($results,'parallel fetch results returned');

my @segments = keys %$results;
is(scalar @segments,2,'exactly two segments returned');
ok($segments[0] =~ /^[12]:/,'expected chromosomes returned');
my $features = $results->{$segments[0]};
ok(@$features>0,'features on fetched segments');

#### now test 1.6 ####

$db = Bio::Das->new(-server=>'http://www.modencode.org/cgi-bin/das');
$db->dsn('fly');
ok($db);
my $segment = $db->segment(-ref=>'X',-start=>7542181,-end=>7562180);
ok($segment);

SKIP: {
    if (0) {
	my @genes = $segment->features('gene:FlyBase');
	ok(@genes>0,'got genes');
	my @sub = $genes[0]->get_SeqFeatures;
	ok(@sub>1,'features have subfeatures');
    } else {
	skip("test temporarily disabled until regression db updated",2);
    }
};

__END__


