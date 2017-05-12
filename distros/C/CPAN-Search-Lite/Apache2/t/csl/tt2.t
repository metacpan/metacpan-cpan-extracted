#!/usr/bin/perl
use strict;
use warnings;
use Apache::Test;
use Apache::TestUtil qw(t_cmp t_write_perl_script);
use Apache::TestRequest qw(GET_OK HEAD_OK);
use CPAN::Search::Lite::Util qw(%chaps);
use FindBin;
use lib "$FindBin::Bin/../lib";
use TestCSL qw($expected);
use CPAN::Search::Lite::Lang qw(%langs);

my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || '';
my @langs = keys %langs;

plan tests => 38 + 7 * scalar @langs;

my $result;

for my $id (keys %$expected) {
  my $result = GET_OK "/author/$id";
  ok t_cmp($result, 1, "fetching /author/$id");
  $result = GET_OK "/search?mode=author&query=$id";
  ok t_cmp($result, 1, "fetching /search?mode=author&query=$id");

  my $dist = $expected->{$id}->{dist};
  $result = GET_OK "/dist/$dist";
  ok t_cmp($result, 1, "fetching /dist/$dist");
  $result = GET_OK "/~$id";
  ok t_cmp($result, 1, "fetching /~$id");
  $result = GET_OK "/~$id/$dist";
  ok t_cmp($result, 1, "fetching /~$id/$dist");
  $result = GET_OK "/search?mode=dist&query=$dist";
  ok t_cmp($result, 1, "fetching /search?mode=dist&query=$dist");

  my $module = $expected->{$id}->{mod};
  $result = GET_OK "/module/$module";
  ok t_cmp($result, 1, "fetching /module/$module");
  $result = GET_OK "/search?mode=module&query=$module";
  ok t_cmp($result, 1, "fetching /search?mode=module&query=$module");

  my $chapter = $chaps{$expected->{$id}->{chapter}};
  $result = GET_OK "/chapter/$chapter";
  ok t_cmp($result, 1, "fetching /chapter/$chapter");
  my $subchapter = $expected->{$id}->{subchapter};
  $result = GET_OK "/chapter/$chapter/$subchapter";
  ok t_cmp($result, 1, "fetching /chapter/$chapter/$subchapter");
}

for my $lang (@langs) {
    for (qw(dist module author recent mirror chapter search)) {
        $result = HEAD_OK "/$_", 'Accept-Language' => $lang;
        ok t_cmp($result, 1, 
                 "fetching /$_ in language $lang");
    }
}

my $no_such = 'XXX';
for (qw(dist module author chapter)) {
  $result = GET_OK "/$_/$no_such";
  ok t_cmp($result, 1, "fetching /$_/$no_such");
  $result = GET_OK "/search?mode=$_&query=$no_such";
  ok t_cmp($result, 1, "fetching /search?mode=$_&query=$no_such");
}
