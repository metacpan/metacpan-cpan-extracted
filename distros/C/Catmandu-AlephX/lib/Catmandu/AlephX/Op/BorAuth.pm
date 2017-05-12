package Catmandu::AlephX::Op::BorAuth;
use Catmandu::Sane;
use Catmandu::Util qw(:check :is);
use Moo;

with('Catmandu::AlephX::Response');

has z303 => (
  is => 'ro',
  lazy => 1,
  isa => sub{
    check_hash_ref($_[0]);
  },
  default => sub {
    {};
  }
);
has z304 => (
  is => 'ro',
  lazy => 1,
  isa => sub{
    check_hash_ref($_[0]);
  },
  default => sub {
    {};
  }
);
has z305 => (
  is => 'ro',
  lazy => 1,
  isa => sub{
    check_hash_ref($_[0]);
  },
  default => sub {
    {};
  }
);

sub op { 'bor-auth' } 

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);
  my $op = op();

  my @keys = qw(z303 z304 z305);
  my %args = ();

  for my $key(@keys){
    my($l) = $xpath->find("/$op/$key")->get_nodelist();
    my $data = $l ? get_children($l,1) : {};
    $args{$key} = $data;    
  }  

  __PACKAGE__->new(
    %args,
    session_id => $xpath->findvalue("/$op/session-id"),
    errors => $class->parse_errors($xpath),
    content_ref => $str_ref
  ); 

}

1;
