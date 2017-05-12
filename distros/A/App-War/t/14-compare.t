use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

use_ok('App::War');

my @items = qw{ Austin Buffalo Chicago Detroit };

my $war = App::War->new(items => \@items)->init;

# mock up the user response to prefer items in alphabetical order
{
    no strict 'refs';
    no warnings 'redefine';
    my $x = 0;
    *{"App::War::_get_response"} = sub {
        my ($self,$x,$y) = @_;
        return ($x lt $y) ? 1 : 2;
    };
}

# rank the items
$war->rank;

# resolve the graph
like($war->report,qr/Austin Buffalo Chicago Detroit/);

