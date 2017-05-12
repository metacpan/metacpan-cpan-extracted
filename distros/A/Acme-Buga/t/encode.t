use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Acme::Buga 'buga';

# result
my $res   = 'buGa BUGA Buga BUga buGa BUGA BUga BugA BugA BUGA Buga BUga buGa buga';
my $coded = 'Teste';


subtest 'encode test constructor param' => sub {
    my $b = Acme::Buga->new( value => $coded );

    my $en = $b->encode;

    is $en, $res;
};


subtest 'encode test method param' => sub {
    my $b = Acme::Buga->new;

    my $en = $b->encode($coded);

    is $en, $res;
};

subtest 'alternative constructor encode' => sub {
    my $en = buga($coded)->encode;

    is $en, $res;
};

done_testing;
