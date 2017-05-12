#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::AlephX;
use Catmandu::Importer::AlephX;
use Catmandu::AlephX::Metadata::MARC::Aleph;
use Data::Dumper;
use File::Slurp;
use open qw(:std :utf8);

my $aleph = Catmandu::AlephX->new(url => "http://aleph.ugent.be/X");

my $importer = Catmandu::Importer::AlephX->new(
  url => 'http://aleph.ugent.be/X',  
  base => 'usm01' 
);

my $marc = $importer->first();

print Dumper($marc);

my %args = (
  'library' => 'usm01',
  'doc_action' => 'UPDATE',
  'doc_number' => '000000000',
  marc => $marc
);
my $info = $aleph->update_doc(%args);
say ${ $info->content_ref };
if($info->is_success){
  say "all ok";
}else{
  say "test";
  say "num errors:".scalar(@{ $info->errors() });
  say STDERR join("\n",@{$info->errors});
} 
