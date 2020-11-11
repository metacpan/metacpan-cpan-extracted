package Catmandu::AlephX::Op::PublishAvail;
use Catmandu::Sane;
use Catmandu::Util qw(:check);
use Catmandu::AlephX::Metadata::MARC;
use Catmandu::AlephX::Record;
use Moo;

our $VERSION = "1.072";

with('Catmandu::AlephX::Response');

#format: [ { _id => <id>, record => <doc>}, .. ]
#<doc> has extra tag in marc array called 'AVA'
has records => (
  is => 'ro',
  isa => sub { check_array_ref($_[0]); }
);
sub op { 'publish-avail' }

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);

  $xpath->registerNs(oai => "http://www.openarchives.org/OAI/2.0/");
  $xpath->registerNs(marc => "http://www.loc.gov/MARC21/slim");

  my $op = op();
  my @records;

  for my $record($xpath->find("/$op/oai:OAI-PMH/oai:ListRecords/oai:record")->get_nodelist()){

    my $identifier = $record->findvalue("./*[local-name() = 'header']/*[local-name()='identifier']");
    $identifier =~ s/aleph-publish://o;

    my($record) = $record->find("./*[local-name()='metadata']/*[local-name() = 'record']")->get_nodelist();
    if($record){
      #remove controlfield with tag 'FMT' and 'LDR' because Catmandu::Importer::MARC cannot handle these
      my $m = Catmandu::AlephX::Metadata::MARC->parse($record);
      $m->{_id} = $identifier;
      push @records,Catmandu::AlephX::Record->new(metadata => $m);
    }else{
      push @records,Catmandu::AlephX::Record->new(
        metadata => Catmandu::AlephX::Metadata::MARC->new(
          data => { _id => $identifier }, type => "oai_marc"
        )
      );
    }
  }

  __PACKAGE__->new(
    errors => $class->parse_errors($xpath),
    session_id => $xpath->findvalue("/$op/session-id"),
    records => \@records,
    content_ref => $str_ref
  );
}

1;
