package Catmandu::AlephX::Metadata::MARC::Aleph;
use Catmandu::Sane;
use Catmandu::Util qw(:array);
use Moo;

our $VERSION = "1.073";

extends qw(Catmandu::AlephX::Metadata);

#parse aleph oai marc into catmandu marc array
sub parse {
  my($class,$xpath)=@_;

  my @marc = ();
  my $_id;

  for my $fix_field($xpath->find('./fixfield')->get_nodelist()){
    my $tag = $fix_field->findvalue('@id');
    my $value = $fix_field->findvalue('.');
    push @marc,[$tag,'','','_',$value];

    if($tag eq "001"){
      $_id = $value;
    }
  }

  for my $var_field($xpath->find('./varfield')->get_nodelist()){

    my $tag = $var_field->findvalue('@id');
    my $ind1 = $var_field->findvalue('@i1');
    my $ind2 = $var_field->findvalue('@i2');

    my @subf = ();

    foreach my $sub_field($var_field->find('.//subfield')->get_nodelist()) {
      my $code  = $sub_field->findvalue('@label');
      my $value = $sub_field->findvalue('.');
      push @subf,$code,$value;
    }

    push @marc,[$tag,$ind1,$ind2,@subf];

  }

  __PACKAGE__->new(type => 'oai_marc',data => { record => \@marc, _id => $_id });
}
sub escape_value {
  my $data = $_[0];
  $data =~ s/&/&amp;/sg;
  $data =~ s/</&lt;/sg;
  $data =~ s/>/&gt;/sg;
  $data =~ s/"/&quot;/sg;
  $data;
}
sub to_xml {
  my($class,$record)=@_;

  my @xml = "<oai_marc>";

  for my $field(@{ $record->{record} }){
    my($tag,$ind1,$ind2,@subfields)= @$field;

    if(array_includes([qw(FMT LDR)],$tag) || $tag =~ /^00/o){

      push @xml,"<fixfield id=\"$tag\">";
      push @xml,escape_value($subfields[1]);
      push @xml,"</fixfield>";

    }else{

      push @xml,"<varfield id=\"$tag\" i1=\"$ind1\" i2=\"$ind2\">";
      for(my $i = 0;$i < scalar(@subfields);$i+=2){
        my $label = $subfields[$i];
        my $value = $subfields[$i+1];
        push @xml,"<subfield label=\"$label\">".escape_value($value)."</subfield>";
      }
      push @xml,"</varfield>";

    }

  }

  push @xml,"</oai_marc>";

  join('',@xml);
}

1;
