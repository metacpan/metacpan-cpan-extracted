#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Catmandu::AlephX;
use open qw(:std :utf8);
use Data::Compare;
use Test::Deep::NoTest;
use Data::Dumper;
use File::Slurp;
use Catmandu::AlephX::XPath::Helper qw(:all);
use Clone qw(clone);
use XML::Simple;

sub alephx {
  state $a = Catmandu::AlephX->new(url => "http://borges1.ugent.be/X");
}

my $item_barcode = '32044044980076';

my %args = (
  'library' => 'usm50',
  'item_barcode' => $item_barcode,
);

my $z30 = alephx->read_item(%args)->z30();

$z30->{'z30-item-status'} = '01';

my $xml = XMLout($z30,,RootName=>"z30",NoAttr => 1);
$xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n".$xml;
print $xml;

$args{xml_full_req} = $xml;

my $u = alephx->update_item(%args);
if($u->is_success){
  say "all ok";
}else{
  say STDERR join("\n",@{$u->errors});

  my $old_z30 = clone($z30);
  my $new_z30 = alephx->read_item("library" => "usm50","item_barcode" => $item_barcode)->z30();

  delete $old_z30->{$_} for qw(z30-cataloger z30-update-date);
  delete $new_z30->{$_} for qw(z30-cataloger z30-update-date);

  say "old z30:";
  say Dumper($old_z30);
  say "new z30";
  say Dumper($new_z30);

  say "equal: ".(eq_deeply($old_z30,$new_z30) ? "yes":"no");
}
