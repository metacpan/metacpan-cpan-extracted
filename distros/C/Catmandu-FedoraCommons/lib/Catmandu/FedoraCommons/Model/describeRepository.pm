=head1 NAME

Catmandu::FedoraCommons::Model::describeRepository - Perl model for the Fedora 'describe' method call

=head1 SYNOPSIS

  use Catmandu::FedoraCommons;

  my $fedora = Catmandu::FedoraCommons->new('http://localhost:8080/fedora','fedoraAdmin','fedoraAdmin');

  my $obj = $fedora->describeRepository()->parse_content;

  {
    "sampleOAI-URL" : "http://localhost:8080/fedora/oai?verb=Identify",
    "repositoryName" : "Fedora Repository",
    "repositoryOAI-identifier" : {
      "OAI-delimiter" : ":",
      "OAI-namespaceIdentifier" : "localhost",
      "OAI-sample" : "oai:localhost:islandora:100"
    },
    "repositoryBaseURL" : "http://localhost:8080/fedora",
    "sampleAccess-URL" : "http://localhost:8080/fedora/objects/demo:5",
    "adminEmail" : "libservice@ugent.be",
    "repositoryVersion" : "3.7.1",
    "repositoryPID" : {
      "PID-sample" : "islandora:100",
      "PID-delimiter" : ":",
      "PID-namespaceIdentifier" : "islandora",
      "retainPID" : "*"
    },
    "sampleSearch-URL" : "http://localhost:8080/fedora/objects"
  }

=head1 SEE ALSO

L<Catmandu::FedoraCommons>

=cut
package Catmandu::FedoraCommons::Model::describeRepository;

use XML::LibXML;

sub parse {
    my ($class,$xml) = @_;
    my $dom  = XML::LibXML->load_xml(string => $xml);
    $dom->getDocumentElement()->setNamespace('http://www.fedora.info/definitions/1/0/access/','a');

    my @nodes = $dom->findnodes("/a:fedoraRepository/*");

    my $result = {};

    for my $node (@nodes) {
        my $name  = $node->nodeName;
        my $value = $node->textContent;

        if ($name eq 'repositoryPID' || $name eq 'repositoryOAI-identifier') {
            $result->{$name} ||= {};
            for my $model ($node->findnodes("./*")) {
                my $n  = $model->nodeName;
                my $v = $model->textContent;

                $result->{$name}->{$n} = $v;
            }
        }
        else {
            $result->{$name} = $value;
        }
    }

    return $result;
}

1;
