package Catmandu::AlephX::Record;
use Catmandu::Sane;
use Catmandu::Util qw(:is :check);
use Moo;
use Catmandu::AlephX::Metadata;

has metadata => (
  is => 'ro',
  lazy => 1,
  isa => sub {
    defined($_[0]) && check_instance($_[0],"Catmandu::AlephX::Metadata");
  },
  coerce => sub {
    if(is_code_ref($_[0])){
      return $_[0]->();
    }
    $_[0];
  }
);

1;
