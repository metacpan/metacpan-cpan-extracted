package Catmandu::MediaMosa::Items::asset;
use Catmandu::Sane;
use Catmandu::Util qw(:array);
use Catmandu::MediaMosa::XPath::Helper qw(:all);
use Moo;

with qw(Catmandu::MediaMosa::Items);

sub parse {
  my($class,$str_ref)=@_;
  __PACKAGE__->parse_xpath(xpath($str_ref));
}
sub parse_xpath {
  my($class,$xpath)=@_;
  my @items;
  for my $i($xpath->find('/response/items/item')->get_nodelist()){
    my $item = {};
    for my $child($i->find('child::*')->get_nodelist()){
      my $name = $child->nodeName();
      my $value = $child->textContent();

      if(array_includes([qw(dublin_core qualified_dublin_core czp)],$name)){

        $item->{$name} = get_children($child);

      }elsif($name eq "mediafiles"){
        my @mediafiles;
        for my $mf($child->find("mediafile")->get_nodelist()){
          my $mediafile = {};

          for my $mfchild($mf->find("child::*")->get_nodelist()){
            if($mfchild->nodeName() eq "metadata"){
              $mediafile->{"metadata"} = get_children($mfchild,1);
            }else{
              $mediafile->{ $mfchild->nodeName() } = $mfchild->textContent();
            }
          }

          push @mediafiles,$mediafile;
        }
        $item->{$name} = \@mediafiles;
      }else{
        $item->{$name} = $value;
      }
    }
    push @items,$item;
  }

  \@items;
}

1;
