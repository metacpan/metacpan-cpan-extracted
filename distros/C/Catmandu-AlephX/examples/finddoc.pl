#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::AlephX;
use Data::Dumper;
use open qw(:std :utf8);

my $aleph = Catmandu::AlephX->new(url => "http://borges1.ugent.be/X",default_args => {
  user_name => "test",user_password => "test"
});

my $find = $aleph->find_doc(base=>'rug01',doc_num=>'000000444',user_name => "");

if($find->is_success){
  say Dumper($find->record->metadata->data);
}else{
  say STDERR join('',@{$find->errors});
}
