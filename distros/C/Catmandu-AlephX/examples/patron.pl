#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::AlephX;
use Data::Dumper;
use open qw(:std :utf8);

my $aleph = Catmandu::AlephX->new(url => "http://borges1.ugent.be/X");

my %args = (
  library => 'rug50',
  bor_id => 'demo',
  verification => 'demo'
);
my $info = $aleph->bor_info(%args);
if($info->is_success){

  my $z304 = $info->z304();
  my @keys = qw(z304-address-0 z304-address-1 z304-address-2 z304-address-3 z304-address-4 z304-email-address z304-date-from z304-date-to z304-zip z304-telephone z304-telephone-1 z304-telephone-2 z304-telephone-3 z304-telephone-4);

  for my $key(@keys){
    my $val = $z304->{$key} // "<not defined>";
    say sprintf("\t%20s : %s",$key,$val);
  }

  my $z305 = $info->z305();
  @keys = qw(z305-no-cash z305-no-hold z305-no-loan z305-no-photo);
  for my $key(@keys){
    my $val = $z305->{$key} // "<not defined>";
    say sprintf("\t%20s : %s",$key,$val);
  }


}else{
  say STDERR "error: ".join('',@{$info->errors});
  exit 1;
}
