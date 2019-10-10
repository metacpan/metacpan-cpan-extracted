#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Catmandu::Store::AlephX;
use Catmandu::Importer::MARC;
use Data::Dumper;
use open qw(:std :utf8);

my $file = shift;
if(is_string($file) && -f $file){
  open STDIN,"<",$file or die($!);
}
my $importer = Catmandu::Importer::MARC->new(type => "ALEPHSEQ");
my $bag = Catmandu::Store::AlephX->new(url => "http://borges1.ugent.be/X",username => "t",password => "t")->bag();

$importer->each(sub{
  my $r = shift;
  delete $r->{_id};
  $r = $bag->add($r);
  say "added ".$r->{_id};
});
