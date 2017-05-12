#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::AlephX;
use Data::Dumper;
use open qw(:std :utf8);

my $aleph = Catmandu::AlephX->new(url => "http://aleph.ugent.be/X");

my $find = $aleph->find(request => 'wrd=(art)',base=>'rug01');
if($find->is_success){
  say "set_number: ".$find->set_number;
  say "no_records: ".$find->no_records;
  say "no_entries: ".$find->no_entries;
  say "session_id: ".$find->session_id;
}else{
  say STDERR join('',@{$find->errors});
} 
