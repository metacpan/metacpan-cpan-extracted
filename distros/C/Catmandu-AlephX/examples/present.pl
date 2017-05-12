#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::AlephX;
use Data::Dumper;
use open qw(:std :utf8);

my $aleph = Catmandu::AlephX->new(url => "http://aleph.ugent.be/X");

my $set_number = $aleph->find(request => "wrd=(BIB.AFF)",base => "rug01")->set_number;
my $present = $aleph->present(
  set_number => $set_number,
  set_entry => "000000001"
);
if($present->is_success){
  for my $record(@{ $present->records }){
    say "record_header: ".Dumper($record->{record_header});    
    say "\ttype: ".$record->metadata->type;
    say "\tdata: ".Dumper($record->metadata->data());     
  }
}else{
  say STDERR join('',@{$present->errors});
} 
