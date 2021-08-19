package Catmandu::AlephX::Record::Present;
use Catmandu::Sane;
use Moo;

our $VERSION = "1.073";

extends 'Catmandu::AlephX::Record';

has record_header => (is => 'ro',required => 1);
has doc_number => (is => 'ro',required => 1);

1;
