package App::Mimosa::View::SeqIO;
use Moose;
use Bio::Chado::Schema;
use File::Spec::Functions;
use App::Mimosa::Database;
use JSON::Any;

use namespace::autoclean;

BEGIN { extends 'Catalyst::View::Bio::SeqIO' };

__PACKAGE__->config(
    default_seqio_args => {
        -width => 80,
    },
    default_format       => 'fasta',
    default_content_type => 'text/plain',
    content_type_map     => {
        fasta => 'application/x-fasta',
    },
);

1;
