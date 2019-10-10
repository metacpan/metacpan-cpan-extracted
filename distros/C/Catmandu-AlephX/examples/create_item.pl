#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Catmandu::AlephX;
use open qw(:std :utf8);
use Data::Compare;
use Test::Deep::NoTest;
use Data::Dumper;
use File::Slurp;
use Catmandu::AlephX::XPath::Helper qw(:all);
use Clone qw(clone);

sub alephx {
  state $a = Catmandu::AlephX->new(url => "http://borges1.ugent.be/X");
}

my $file = shift;
is_string($file) or die("usage: $0 <file>\n");

my $xml = read_file($file);

my %args = (
  'adm_library'    => 'rug50',
  'bib_library'    => 'rug01',
  'bib_doc_number' => '000000444',
  'xml_full_req'   => $xml
);

my $u = alephx->create_item(%args);

if($u->is_success){
  say "all ok";
}
else{
  say STDERR join("\n",@{$u->errors});
}
