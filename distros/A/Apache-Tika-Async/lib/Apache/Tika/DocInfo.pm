package Apache::Tika::DocInfo;
use Moo;
our $VERSION = '0.11';

has meta => (
    is => 'ro',
);

has content => (
    is => 'ro',
);

1;