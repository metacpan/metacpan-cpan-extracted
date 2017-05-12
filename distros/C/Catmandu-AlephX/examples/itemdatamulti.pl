#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::AlephX;
use Data::Dumper;
use open qw(:std :utf8);

my $aleph = Catmandu::AlephX->new(url => "http://aleph.ugent.be/X");

my($base,$doc_number)=("rug01","001484477");
my $item_data = $aleph->item_data_multi(base => $base,doc_number => $doc_number);
if($item_data->is_success){
  for my $item(@{ $item_data->items() }){
    print Dumper($item);
  };
}else{
  say STDERR join('',@{$item_data->errors});
}
