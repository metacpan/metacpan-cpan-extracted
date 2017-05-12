package App::AutoCRUD::View::Plain;

use 5.010;
use strict;
use warnings;

use Moose;
use namespace::autoclean;
use Data::Dumper;
extends 'App::AutoCRUD::View';


sub render {
  my ($self, $output, $context) = @_;

  return [200, ['Content-type' => 'text/plain'], [$output] ];
}

1;


__END__



