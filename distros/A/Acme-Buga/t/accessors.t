use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Acme::Buga;


subtest 'acessor exists' => sub {
    my $b = Acme::Buga->new;

    can_ok 'Acme::Buga', $_ for qw/base8 value/;
};


subtest 'using acessors' => sub {
    my $b = Acme::Buga->new;

    $b->value('Teste');

    is $b->value, 'Teste';
};

done_testing;
