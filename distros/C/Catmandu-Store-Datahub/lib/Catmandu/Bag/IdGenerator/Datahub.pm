package Catmandu::Bag::IdGenerator::Datahub;

our $VERSION = '0.01';

use Catmandu::Sane;
use URL::Encode qw(url_encode_utf8 url_decode_utf8);
use Moo;

with 'Catmandu::IdGenerator';

has data_pid => (is => 'ro');

sub generate {
    my ($self) = @_;
    my $data_pid = url_encode_utf8($self->data_pid);
    return $data_pid;
}

1;
