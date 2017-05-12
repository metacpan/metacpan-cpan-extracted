#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::AlephX;
use Data::Dumper;
use open qw(:std :utf8);

my $aleph = Catmandu::AlephX->new(url => "http://aleph.ugent.be/X");

my $result = $aleph->ill_get_doc_short(doc_number => "000030527",library=>"rug01");
if($result->is_success){
  print Dumper($result->z13);
}else{
  say STDERR join('',@{$result->errors});
} 
