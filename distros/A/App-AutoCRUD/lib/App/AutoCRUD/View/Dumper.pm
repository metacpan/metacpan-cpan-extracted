package App::AutoCRUD::View::Dumper;

use 5.010;
use strict;
use warnings;

use Moose;
use namespace::autoclean;
use Data::Dumper;
extends 'App::AutoCRUD::View';



sub render {
  my ($self, $data, $context) = @_;

  local $Data::Dumper::Indent = 1;
  my $output = Dumper $data;
  return [200, ['Content-type' => 'text/plain'], [$output] ];
}

1;


__END__



