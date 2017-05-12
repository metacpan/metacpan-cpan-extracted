use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Acme::Buga 'buga';

# result
my $coded = 'buGa BUGA Buga BUga buGa BUGA BUga BugA BugA BUGA Buga BUga buGa buga';
my $res   = 'Teste';


subtest 'decode test constructor param' => sub {
    my $b = Acme::Buga->new( value => $coded );

    my $de = $b->decode;

    is $de, $res;
};


subtest 'decode test method param' => sub {
    my $b = Acme::Buga->new;

    my $de = $b->decode($coded);

    is $de, $res;
};


subtest 'alternative constructor decode' => sub {
    my $de = buga($coded)->decode;

    is $de, $res;
};

done_testing;
