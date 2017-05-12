#!/usr/bin/env perl
use Catmandu::Sane;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "/home/njfranck/git/Activiti-Rest/lib";
use Catmandu::Importer::Activiti::RuntimeProcessInstance;
use Data::Dumper;

print Dumper(\@INC);

my $importer = Catmandu::Importer::Activiti::RuntimeProcessInstance->new(
  url => 'http://kermit:kermit@localhost:8080/activiti-rest/service',
  include_process_variables => "true"
);

$importer->each(sub{
  print Dumper(shift);
});
