package Catmandu::Importer::Activiti::HistoricProcessInstance;
use Catmandu::Sane;
use Catmandu::Util qw(:is :check :array);
use Activiti::Rest::Client;
use Moo;

our $VERSION = "0.11";

with 'Catmandu::Importer';

has url => (
  is => 'ro',
  isa => sub { check_string($_[0]); },
  required => 1
);
has params => (
  is => 'ro',
  isa => sub { check_hash_ref($_[0]); },
  lazy => 1,
  default => sub { +{}; }
);
has _activiti => (
  is => 'ro',
  lazy => 1,
  builder => '_build_activiti'
);
sub _build_activiti {
  my $self = $_[0];
  Activiti::Rest::Client->new(url => $self->url);
}

sub generator {
  my $self = $_[0];
  sub {

    state $start = 0;
    state $size = 100;
    state $total;
    state $results = [];
    state $activiti = $self->_activiti();
    state $params = $self->params();

    unless(@$results){

      if(defined $total){
        return if $start >= $total;
      }

      my $res = $activiti->query_historic_process_instances(
        content => {
          %$params,
          start => $start,
          size => $size
        }
      )->parsed_content;

      $total = $res->{total};
      return unless @{ $res->{data} };

      $results = $res->{data};
      
      $start += $size;
    }

    shift @$results;
  };
}

=head1 NAME

Catmandu::Importer::Activiti::HistoricProcessInstance - Package that imports historic process instances from Activiti

=head1 SYNOPSIS

    use Catmandu::Importer::Activiti::HistoricProcessInstance;

    my $importer = Catmandu::Importer::Activiti::HistoricProcessInstance->new(
      url => 'http://user:password@localhost:8080/activiti-rest/service',
      params => {
        includeProcessVariables => "true"
      }
    );

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 METHODS

=head2 new()

Create a new importer

Arguments:

  url       base url for the activiti rest api
  params    additional filters (see: http://www.activiti.org/userguide/#restHistoricProcessInstancesGet)

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. The
Catmandu::Importer::Activiti::HistoricProcessInstance methods are not idempotent: Activiti feeds can only be read once.

=head1 SEE ALSO

L<Catmandu::Iterable>

=head1 AUTHOR

Nicolas Franck C<< Nicolas Franck at UGent be >>

=cut

1;
