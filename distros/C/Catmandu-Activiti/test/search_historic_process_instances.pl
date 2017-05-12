#!/usr/bin/env perl
use Catmandu::Sane;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "/home/njfranck/git/Activiti-Rest/lib";
use Catmandu::Store::Activiti::HistoricProcessInstance;
use Data::Dumper;

print Dumper(\@INC);

my $store = Catmandu::Store::Activiti::HistoricProcessInstance->new(
  url => 'http://kermit:kermit@localhost:8080/activiti-rest/service'
);

my $hits = $store->bag()->search(sort => 'endTime desc',query => { excludeSubprocesses => "true" });
print Dumper($hits);
