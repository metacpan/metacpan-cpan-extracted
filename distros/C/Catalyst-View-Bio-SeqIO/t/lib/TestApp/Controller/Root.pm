package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

use Bio::PrimarySeq;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(
    namespace => '',
);

sub test_seqio : Path Args(1) {
    my ( $self, $c, $format ) = @_;

    $c->stash(
        seqio_format  => $format,
        sequences     => [
            Bio::PrimarySeq->new( -id => 'a100', -seq => 'A'x100 ),
            Bio::PrimarySeq->new( -id => 't200', -seq => 'T'x200 ),
            Bio::PrimarySeq->new( -id => 'c24',  -seq => 'C'x24 ),
          ]);
}

sub default :Private {
    shift->test_seqio( shift );
}

sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;

1;
