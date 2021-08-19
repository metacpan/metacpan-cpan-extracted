package Catmandu::AlephX::Op::BorInfo;
use Catmandu::Sane;
use Catmandu::Util qw(:check :is);
use Moo;

our $VERSION = "1.073";

extends('Catmandu::AlephX::Op::BorAuth');
with('Catmandu::AlephX::Response');

has item_l => (
  is => 'ro',
  lazy => 1,
  isa => sub { check_array_ref($_[0]); },
  default => sub {
    []
  }
);
has item_h => (
  is => 'ro',
  lazy => 1,
  isa => sub { check_array_ref($_[0]); },
  default => sub {
    []
  }
);

has balance => (
  is => 'ro'
);
has sign => (
  is => 'ro'
);
has fine => (
  is => 'ro',
  lazy => 1,
  isa => sub {
    check_array_ref($_[0]);
  },
  default => sub {
    []
  }
);

sub op { 'bor-info' }

my $config = {
  fine => [qw(z31 z30 z13)],
  'item-h' => [qw(z37 z30 z13)]
};

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);

  my $op = op();

  my $args = {};

  for my $zkey(qw(z303 z304 z305)){
    my($l) = $xpath->find("/$op/$zkey")->get_nodelist();
    $args->{$zkey} = $l ? get_children($l,1) : {};
  }

  for my $child($xpath->find("/$op/item-l")->get_nodelist()){
    $args->{'item_l'} //= [];

    my $item_l = {};
    $item_l->{due_date} = $child->findvalue('./due-date');
    $item_l->{due_hour} = $child->findvalue('./due-hour');

    for my $key(qw(z36 z30 z13)){
      for my $data($child->find("./$key")->get_nodelist()){
        $item_l->{ $key } = get_children($data,1);
      }
    }

    push @{ $args->{'item_l'} },$item_l;

  }


  for my $key(keys %$config){
    for my $child($xpath->find("/$op/$key")->get_nodelist()){
      my $n = $key;
      $n =~ s/-/_/go;
      $args->{$n} //= [];

      my %result = map {
        my($l) = $child->find("./$_")->get_nodelist();
        $l ? ($_ => get_children($l,1 )) : ($_ => {});
      } @{ $config->{ $key } };

      push @{ $args->{$n} },\%result;
    }
  }

  __PACKAGE__->new(
    %$args,
    balance => $xpath->findvalue("/$op/balance"),
    sign => $xpath->findvalue("/$op/sign"),
    session_id => $xpath->findvalue("/$op/session-id"),
    errors => $class->parse_errors($xpath),
    content_ref => $str_ref
  );

}

1;
