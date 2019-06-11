package Apache::Tika::DocInfo;
use Moo;
our $VERSION = '0.08';

has meta => (
    is => 'ro',
);

has content => (
    is => 'ro',
);

1;