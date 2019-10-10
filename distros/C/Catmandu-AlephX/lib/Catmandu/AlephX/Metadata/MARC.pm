package Catmandu::AlephX::Metadata::MARC;
use Catmandu::Sane;
use Moo;
extends qw(Catmandu::AlephX::Metadata);

our $VERSION = "1.071";

#parse marcxml into Catmandu marc array

sub parse {
  my($class,$xpath)=@_;

  my @marc = ();

  my $leader = $xpath->findvalue("./*[local-name() = 'leader']");
  my $fmt = "";
  my $_id;

  for my $controlfield($xpath->find("./*[local-name() = 'controlfield']")->get_nodelist()){
    my $tag = $controlfield->findvalue('@tag');
    my $value = $controlfield->findvalue('.');
    if($tag eq "FMT"){
      $fmt = $value;
      next;
    }
    if($tag eq "001"){
      $_id = $value;
    }
    #leader can also be specified in a controlfield??
    elsif($tag eq "LDR"){
      $leader = $value;
      next;
    }
    push @marc,[$tag,'','','_',$value];
  }

  unshift @marc,['FMT','','','_',$fmt],['LDR','','','_',$leader];

  for my $datafield($xpath->find("./*[local-name() = 'datafield']")->get_nodelist()){

    my $tag = $datafield->findvalue('@tag');
    my $ind1 = $datafield->findvalue('@ind1');
    my $ind2 = $datafield->findvalue('@ind2');

    my @subf = ();

    foreach my $subfield($datafield->find("./*[local-name() = 'subfield']")->get_nodelist()) {
      my $code  = $subfield->findvalue('@code');
      my $value = $subfield->findvalue('.');
      push @subf,$code,$value;
    }

    push @marc,[$tag,$ind1,$ind2,@subf];

  }

  __PACKAGE__->new(type => 'oai_marc',data => { record => \@marc, _id => $_id });
}

1;
