use strict;
use v5.10;
use Test::More;
use App::PAIA::Tester;

new_paia_test;
paia_response 403, [ ], {
    error => 'access_denied',
    code  => 403,
    error_description => 'invalid patron or password'
};

paia qw(login -b https://example.org -u alice -p 1234 -v);

is output, "# POST https://example.org/auth/login\n";
is error, "access_denied: invalid patron or password\n";
ok exit_code;

new_paia_test;
paia_response {
    doc => [{ 
        item  => "http://example.org/abc",
        error => "item not found",
    }]
};

# use explicit token, patron, and base URL
paia qw(-b https://example.org/ -t 12345 -o alice request urn:isbn:9876);
is error, "item not found\n";
ok exit_code;

# print items
my $items = {
    doc => [{ 
        item  => "http://example.org/abc",
        status => "2",
    }]
};
paia_response $items;
paia qw(-b https://example.org/ -t 12345 -o alice items);
is_deeply stdout_json, $items, 'items'; 
ok !exit_code;

done_paia_test;
