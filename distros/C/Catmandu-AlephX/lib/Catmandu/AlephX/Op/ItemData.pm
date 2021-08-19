package Catmandu::AlephX::Op::ItemData;
use Catmandu::Sane;
use Catmandu::Util qw(:check :is);
use Moo;

our $VERSION = "1.073";

with('Catmandu::AlephX::Response');

has items => (
  is => 'ro',
  lazy => 1,
  isa => sub{
    check_array_ref($_[0]);
    for(@{ $_[0] }){
      check_hash_ref($_);
    }
  },
  default => sub {
    [];
  }
);
sub op { 'item-data' }

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);
  my $op = op();

  my @items;

  for my $item($xpath->find("/$op/item")->get_nodelist()){
    push @items,get_children($item,1);
  }

  __PACKAGE__->new(
    session_id => $xpath->findvalue("/$op/session-id"),
    errors => $class->parse_errors($xpath),
    items => \@items,
    content_ref => $str_ref
  );
}

1;
