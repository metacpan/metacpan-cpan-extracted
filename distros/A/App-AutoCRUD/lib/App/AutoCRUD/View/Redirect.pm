package App::AutoCRUD::View::Redirect;

use 5.010;
use strict;
use warnings;

use Moose;
extends 'App::AutoCRUD::View';
use App::AutoCRUD::View::TT; # for its utf8_url() filter

use namespace::clean -except => 'meta';


sub render {
  my ($self, $url, $context) = @_;

  # make sure the URL is url-encoded with utf8 chars
  $url = App::AutoCRUD::View::TT::utf8_url($url);

  # SEE_OTHER http code (cf http://en.wikipedia.org/wiki/303_See_Other)
  return [303, [Location => $url], []];
}

1;


__END__



