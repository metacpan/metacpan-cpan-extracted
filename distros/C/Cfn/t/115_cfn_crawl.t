#!/usr/bin/env perl

use Test::More;
use Cfn;
use Cfn::Crawler;
use IO::Dir;
use File::Slurp;
use FindBin;

my $t_dir = "$FindBin::Bin/cfn_json/";
use IO::Dir;
my $d = IO::Dir->new($t_dir);

while (my $file = $d->read){
  next if ($file =~ m/^\./);
  next if (not $file =~ m/\.json$/);
  my $content = read_file("$t_dir/$file");
  my $cfn = Cfn->from_json($content);
  my $crawl = Cfn::Crawler->new(
    cfn => $cfn,
    criteria => sub {
      # return everything
      1;
    }
  );

  my @elements = $crawl->all;
  # each element is a Cfn::Crawler::Path
  ok((grep { not $_->isa('Cfn::Crawler::Path') } @elements) == 0, 'All results are Cfn::Crawler::Path');

  cmp_ok(scalar($crawl->mappings), '==', $cfn->MappingCount);
  cmp_ok(scalar($crawl->parameters), '==', $cfn->ParameterCount);
  cmp_ok(scalar($crawl->conditions), '==', $cfn->ConditionCount);
  cmp_ok(scalar($crawl->metadata), '==', $cfn->MetadataCount);

  # if we select all things in a stack, we can get to them via $cfn->path_to()
  foreach my $match ($crawl->all) {
    # we're doing a string comparison to see if they are the same reference
    my $path = $match->path;
    cmp_ok($cfn->path_to($path), 'eq', $match->element, "Path $path is resolved to same element");
  }
}

done_testing;
