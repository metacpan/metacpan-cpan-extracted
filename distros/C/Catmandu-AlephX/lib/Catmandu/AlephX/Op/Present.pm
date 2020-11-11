package Catmandu::AlephX::Op::Present;
use Catmandu::Sane;
use Catmandu::Util qw(:is :check);
use Moo;
use Catmandu::AlephX::Metadata::MARC::Aleph;
use Catmandu::AlephX::Record::Present;

our $VERSION = "1.072";

with('Catmandu::AlephX::Response');

has records => (
  is => 'ro',
  lazy => 1,
  default => sub { [] },
  coerce => sub {
    if(is_code_ref($_[0])){
      return $_[0]->();
    }
    $_[0];
  }
);
sub op { 'present' }

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);

  my $op = op();

  __PACKAGE__->new(
    records => sub{
      my @records;
      for my $r($xpath->find("/$op/record")->get_nodelist()){

        my($l) = $r->find('./record_header')->get_nodelist();

        my $record_header = $l ? get_children($l,1) : {};

        my $metadata = Catmandu::AlephX::Metadata::MARC::Aleph->parse(
          $r->find('./metadata/oai_marc')->get_nodelist()
        );

        push @records,Catmandu::AlephX::Record::Present->new(
          metadata => $metadata,
          record_header => $record_header,
          doc_number => $r->findvalue('./doc_number')
        );

      }

      \@records
    },
    session_id => $xpath->findvalue("/$op/session-id"),
    errors => $class->parse_errors($xpath),
    content_ref => $str_ref
  );
}

1;
