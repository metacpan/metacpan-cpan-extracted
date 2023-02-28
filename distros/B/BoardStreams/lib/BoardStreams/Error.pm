package BoardStreams::Error;

use Moo;
with 'Throwable';

use BoardStreams::Util 'make_one_line';

use Data::Dump 'dump';

use experimental 'signatures';

use overload '""' => sub {
    my $text = ref($_[0]) . '=' . dump({
        code => $_[0]->code,
        $_[0]->has_data ? (data => $_[0]->data) : (),
    });
    return make_one_line $text;
};

our $VERSION = "v0.0.36";

has code => (
    is       => 'ro',
    required => 1,
);

has data => (
    is        => 'ro',
    predicate => 1,
);

1;
