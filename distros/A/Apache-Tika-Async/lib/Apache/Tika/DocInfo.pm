package Apache::Tika::DocInfo;
use Moo;
use vars qw($VERSION);
$VERSION = '0.06';

has meta => (
    is => 'ro',
    #isa => 'Hash',
);

has content => (
    is => 'ro',
    #isa => 'Int',
);

1;