package Catmandu::AlephX::Op::UpdateDoc;
use Catmandu::Sane;
use Catmandu::Util qw(:check :is);
use Moo;

our $VERSION = "1.071";

with('Catmandu::AlephX::Response');

sub op { 'update-doc' }

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);
  my $op = op();

  __PACKAGE__->new(
    session_id => $xpath->findvalue("/$op/session-id"),
    errors => $class->parse_errors($xpath),
    content_ref => $str_ref
  );
}

1;
