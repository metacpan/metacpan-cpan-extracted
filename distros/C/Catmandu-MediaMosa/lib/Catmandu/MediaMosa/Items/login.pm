package Catmandu::MediaMosa::Items::login;
use Catmandu::Sane;
use Catmandu::MediaMosa::XPath::Helper qw(:all);
use Moo;

with qw(Catmandu::MediaMosa::Items);

sub parse {
  my($class,$str_ref)=@_;
  __PACKAGE__->parse_xpath(xpath($str_ref));
}
sub parse_xpath {
  my($class,$xpath) = @_;
  [{
    dbus => $xpath->findvalue("/response/items/item/dbus"),
  }];
}

1;
