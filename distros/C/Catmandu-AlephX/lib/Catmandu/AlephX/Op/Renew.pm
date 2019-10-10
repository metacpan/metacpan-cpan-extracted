package Catmandu::AlephX::Op::Renew;
use Catmandu::Sane;
use Catmandu::Util qw(:check);
use Moo;

our $VERSION = "1.071";

with('Catmandu::AlephX::Response');

has reply => (
  is => 'ro'
);
has due_date => (
  is => 'ro'
);
has due_hour => (
  is => 'ro'
);

sub op { 'renew' }

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);
  my $op = op();

  __PACKAGE__->new(
    session_id => $xpath->findvalue('/'.$op.'/session-id'),
    errors => $class->parse_errors($xpath),
    reply => $xpath->findvalue('/'.$op.'/reply'),
    due_date => $xpath->findvalue('/'.$op.'/due-date'),
    due_hour => $xpath->findvalue('/'.$op.'/due-hour'),
    content_ref => $str_ref
  );
}

1;
