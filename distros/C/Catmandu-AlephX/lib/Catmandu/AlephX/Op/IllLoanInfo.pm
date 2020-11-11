package Catmandu::AlephX::Op::IllLoanInfo;
use Catmandu::Sane;
use Catmandu::Util qw(:check :is);
use Moo;

our $VERSION = "1.072";

with('Catmandu::AlephX::Response');

has z36 => (
  is => 'ro',
  lazy => 1,
  isa => sub { check_hash_ref($_[0]); },
  default => sub {
    +{};
  }
);

sub op { 'ill-loan-info' }

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);
  my $op = op();

  my $z36 = {};

  my($z) = $xpath->find("/ill-LOAN-INFO/z36")->get_nodelist();

  $z36 = get_children($z) if $z;

  __PACKAGE__->new(
    session_id => $xpath->findvalue('/ill-LOAN-INFO/session-id'),
    errors => $class->parse_errors($xpath),
    z36 => $z36,
    content_ref => $str_ref
  );
}

1;
