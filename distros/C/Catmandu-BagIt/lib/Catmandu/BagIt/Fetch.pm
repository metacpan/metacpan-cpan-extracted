package Catmandu::BagIt::Fetch;

our $VERSION = '0.233';

use Moo;
use IO::String;

has 'url'      => (is => 'ro');
has 'size'     => (is => 'ro');
has 'filename' => (is => 'ro');

1;

__END__
