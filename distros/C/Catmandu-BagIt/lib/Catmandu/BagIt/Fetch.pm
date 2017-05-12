package Catmandu::BagIt::Fetch;
use Moo;
use IO::String;

our $VERSION = '0.12';

has 'url'      => (is => 'ro');
has 'size'     => (is => 'ro');
has 'filename' => (is => 'ro');

1;

__END__