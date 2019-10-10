#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::AlephX;
use JSON qw(to_json);
use open qw(:std :utf8);

my $aleph = Catmandu::AlephX->new(url => "http://borges1.ugent.be/X");

my($base,$doc_number)=("rug01","000000444");
my $item_data = $aleph->item_data(base => $base,doc_number => $doc_number);
if($item_data->is_success){
  print to_json($item_data->items(),{pretty => 1});
}else{
  say STDERR join('',@{$item_data->errors});
}
