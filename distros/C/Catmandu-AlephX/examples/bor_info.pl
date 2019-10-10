#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::AlephX;
use Data::Dumper;
use open qw(:std :utf8);

my $aleph = Catmandu::AlephX->new(url => "http://borges1.ugent.be/X");

my %args = (
  library => "rug50",
  bor_id => "demo",
  verification => "demo",
  user_name => "t",
  user_password => "t"
);
my $info = $aleph->bor_info(%args);
if($info->is_success){
  print Dumper($info->item_l);
  print Dumper($info->item_h);
}else{
  say STDERR join('',@{$info->errors});
}
