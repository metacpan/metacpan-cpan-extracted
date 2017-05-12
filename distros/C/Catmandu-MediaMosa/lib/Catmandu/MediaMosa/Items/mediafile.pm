package Catmandu::MediaMosa::Items::mediafile;
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

      if($name eq "metadata"){

        $item->{$name} = get_children($child,1);

      }elsif($name eq "still"){        
        $item->{stills} //= [];
        push @{$item->{stills}},get_children($child,1);
      }else{
        $item->{$name} = $value;
      }
    }
    push @items,$item;
  }

  \@items;
}

1;
