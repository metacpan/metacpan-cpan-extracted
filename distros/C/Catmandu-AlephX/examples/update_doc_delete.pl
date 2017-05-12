#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::AlephX;
use open qw(:std :utf8);
use Data::Dumper;

sub alephx {
  state $a = Catmandu::AlephX->new(url => "http://aleph.ugent.be/X");
}

my $doc_number = shift;

my %args = (
  'library' => 'usm01',
  'doc_action' => 'DELETE',
  'doc_number' => $doc_number
);
my $u = alephx->update_doc(%args);
if($u->is_success){
  say "all ok";
}else{
  say STDERR join("\n",@{$u->errors});
}
