package Catmandu::AlephX::Op::Find;
use Catmandu::Sane;
use Moo;

our $VERSION = "1.072";

with('Catmandu::AlephX::Response');

#'set_number' == id waaronder zoekactie wordt opgeslagen door Aleph (kan je later hergebruiken)
has set_number => (
  is => 'ro'
);
has no_records => (
  is => 'ro'
);
has no_entries => (
  is => 'ro',
);
sub op { 'find' }

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);
  my $op = op();

  __PACKAGE__->new(
    errors => $class->parse_errors($xpath),
    session_id => $xpath->findvalue("/$op/session-id"),
    set_number => $xpath->findvalue("/$op/set_number"),
    no_records => $xpath->findvalue("/$op/no_records"),
    no_entries => $xpath->findvalue("/$op/no_entries"),
    content_ref => $str_ref
  );
}

1;
