package BPM::Engine::Store::ResultRole::WithGraph;
BEGIN {
    $BPM::Engine::Store::ResultRole::WithGraph::VERSION   = '0.01';
    $BPM::Engine::Store::ResultRole::WithGraph::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose::Role;

use Graph::Directed;

requires 'activities';
requires 'transitions';

sub graph {
    my $self = shift;

    my @edges = map { [
        $_->from_activity_id, $_->to_activity_id
        ] } $self->transitions->all;

    return Graph::Directed->new(edges => [ @edges ]);
    }

no Moose::Role;

1;
__END__