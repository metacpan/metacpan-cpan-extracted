package App::AutoCRUD::View;

use 5.010;
use strict;
use warnings;

use Moose;
use namespace::clean -except => 'meta';

sub render {
  my ($self, $data, $context) = @_;

  die "attempt to render() from abstract class View.pm";
}


sub default_dashed_args {
  my ($self, $context) = @_;
  return ();
}

1;

__END__


# parent class for views
