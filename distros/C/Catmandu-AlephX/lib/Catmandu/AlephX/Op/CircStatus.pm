package Catmandu::AlephX::Op::CircStatus;
use Catmandu::Sane;
use Catmandu::Util qw(:check);
use Moo;

our $VERSION = "1.072";

with('Catmandu::AlephX::Response');

has item_data => (
  is => 'ro',
  isa => sub { check_array_ref($_[0]); }
);

sub op { 'circ-status' }

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);

  my $op = op();

  my @item_data;

  for my $i($xpath->find("/$op/item-data")->get_nodelist()){
    push @item_data,get_children($i,1);
  }

  __PACKAGE__->new(
    item_data => \@item_data,
    session_id => $xpath->findvalue("/$op/session-id"),
    errors => $class->parse_errors($xpath),
    content_ref => $str_ref
  );

}

1;
