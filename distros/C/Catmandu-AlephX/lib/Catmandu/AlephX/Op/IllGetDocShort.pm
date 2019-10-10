package Catmandu::AlephX::Op::IllGetDocShort;
use Catmandu::Sane;
use Catmandu::Util qw(:check :is);
use Moo;

our $VERSION = "1.071";

with('Catmandu::AlephX::Response');

has z13 => (
  is => 'ro',
  lazy => 1,
  isa => sub{
    check_hash_ref($_[0]);
  },
  default => sub { {}; }
);
sub op { 'ill-get-doc-short' }

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);

  my $op = op();

  my $z13 = {};

  my($z) = $xpath->find("/$op/z13")->get_nodelist();

  $z13 = get_children($z) if $z;

  __PACKAGE__->new(
    session_id => $xpath->findvalue("/$op/session-id"),
    errors => $class->parse_errors($xpath),
    z13 => $z13,
    content_ref => $str_ref
  );
}

1;
