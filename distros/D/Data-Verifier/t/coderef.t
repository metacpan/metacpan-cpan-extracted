use strict;
use Test::Exception;
use Test::More;

use Data::Verifier;

{
    my $verifier = Data::Verifier->new(
        profile => {
            name => {
                filters => sub { my $val = shift; return lc($val); }
            },
            address1 => {
                filters => [
                    sub { my $val = shift; $val =~ s/A/Z/g; return $val; },
                    sub { my $val = shift; $val =~ s/B/Y/g; return $val; }
                ]
            },
        }
    );

    my $results = $verifier->verify({
        name        => "FoObAr",
        address1    => 'ABCD'
    });

    ok($results->success, 'success');
    cmp_ok($results->get_value('name'), 'eq', 'foobar', 'scalar as coderef');
    cmp_ok($results->get_value('address1'), 'eq', 'ZYCD', 'array of coderefs');
}

done_testing;