#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::AlephX;
use open qw(:std :utf8);
use Data::Compare;
use Test::Deep::NoTest;
use Data::Dumper;

my $doc_number = '000000444';

sub alephx {
  state $a = Catmandu::AlephX->new(url => "http://aleph.ugent.be/X");
}
sub get_doc {
  alephx()->find_doc(
    doc_num => $doc_number,
    base => "usm01"
  );
}

my $find_doc = get_doc();
my $marc = $find_doc->record->metadata->data;

#warning: this removes all CAT fields in aleph!
$marc->{record} = [grep { !( $_->[0] eq "CAT" && $_->[4] eq "WWW-X" ) } @{ $marc->{record} }];

my %args = (
  'library' => 'usm01',
  'doc_action' => 'UPDATE',
  'doc_number' => $doc_number,
  marc => $marc
);
my $u = alephx->update_doc(%args);
if($u->is_success){
  say "all ok";
}else{
  say STDERR join("\n",@{$u->errors});
}

my $new_marc = get_doc()->record->metadata->data;


#every updates creates 'CAT' fields, so first remove these, and also 005 (last modified)

$marc->{record} = [grep { $_->[0] ne "CAT" && $_->[0] ne "005" } @{ $marc->{record} }];
$new_marc->{record} = [grep { $_->[0] ne "CAT" && $_->[0] ne "005" } @{ $new_marc->{record} }];

say "old marc:";
say Dumper($marc);
say "new marc:";
say Dumper($new_marc);
my $eq = eq_deeply($marc,$new_marc);
say "equal: ".($eq ? "yes":"no");
