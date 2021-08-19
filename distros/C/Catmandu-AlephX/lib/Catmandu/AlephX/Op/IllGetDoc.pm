package Catmandu::AlephX::Op::IllGetDoc;
use Catmandu::Sane;
use Catmandu::Util qw(:check);
use Catmandu::AlephX::Metadata::MARC;
use Catmandu::AlephX::Record;
use Moo;

our $VERSION = "1.073";

with('Catmandu::AlephX::Response');

#<doc> has extra tag in marc array called 'AVA'
has record => (
  is => 'ro',
  isa => sub { check_instance($_[0],"Catmandu::AlephX::Record"); }
);
sub op { 'ill-get-doc' }

sub parse {
  my($class,$str_ref) = @_;

  my $xpath = xpath($str_ref);
  my $op = op();

  __PACKAGE__->new(
    errors => $class->parse_errors($xpath),
    session_id => $xpath->findvalue("/$op/session-id"),
    record => Catmandu::AlephX::Record->new(metadata => sub {
      $xpath->registerNs("marc","http://www.loc.gov/MARC21/slim/");
      my($marc) = $xpath->find("/$op/marc:record")->get_nodelist();
      if($marc){
        #remove controlfield with tag 'FMT' and 'LDR' because Catmandu::Importer::MARC cannot handle these
        return Catmandu::AlephX::Metadata::MARC->parse($marc);
      }
    }),
    content_ref => $str_ref
  );
}

1;
