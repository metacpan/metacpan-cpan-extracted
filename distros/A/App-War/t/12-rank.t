use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;

use_ok('App::War');

my @items = qw{ apricot barista cargo };

my $war = App::War->new(items => \@items)->init;
ok($war);

# mock up a 'compare' method that always chooses the first item
{
    no strict 'refs';
    no warnings 'redefine';
    *{"App::War::compare"} = sub {
        my ($self, @x) = @_;
        $self->graph->add_edge($x[0], $x[1]);
    };
}

# calculate the rankings
ok($war->rank);

