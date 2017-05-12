#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::AlephX;
use JSON qw(to_json);
use open qw(:std :utf8);

my $aleph = Catmandu::AlephX->new(url => "http://aleph.ugent.be/X");

my $illgetdoc = $aleph->ill_get_doc(doc_number => '001317121',library=>'rug01');
if($illgetdoc->is_success){

  if($illgetdoc->record){
    say "data: ".to_json($illgetdoc->record->metadata->data,{ pretty => 1 });
  }
  else{
    say "nothing found";
  }

}else{
  say STDERR join('',@{$illgetdoc->errors});
} 
