package Catmandu::MediaMosa::Items::simple_list;
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
  my($class,$xpath,$is_hash)=@_;
  my @items;
  for my $i($xpath->find('/response/items/item')->get_nodelist()){
    push @items,get_children($i,$is_hash);
  }
  \@items;
}

1;
