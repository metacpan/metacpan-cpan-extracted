use Test::More;
use strict;

if(!$ENV{'TEST_ASSEMBLA_PASS'}) {
    plan skip_all => 'This test is useless unless you are the author';
}

use API::Assembla;

my $api = API::Assembla->new(
    username => 'iirobot',
    password => $ENV{'TEST_ASSEMBLA_PASS'}
);

my $tickets = $api->get_tickets('dhHT8ENtKr4k_1eJe4gwI3');
cmp_ok(scalar(keys($tickets)), '==', 3, '3 tickets');

{
    my $ticket = $tickets->{4317338};

    ok($ticket->description =~ /make it/, 'description');
    cmp_ok($ticket->number, '==', 3, 'number');
    cmp_ok($ticket->priority, '==', 3, 'priority');
    cmp_ok($ticket->status_name, 'eq', 'New', 'status_name');
    cmp_ok($ticket->summary, 'eq', 'test ticketing', 'summary');
}

{
    my $ticket = $api->get_ticket('dhHT8ENtKr4k_1eJe4gwI3', 3);

    ok($ticket->description =~ /make it/, 'description');
    cmp_ok($ticket->number, '==', 3, 'number');
    cmp_ok($ticket->priority, '==', 3, 'priority');
    cmp_ok($ticket->status_name, 'eq', 'New', 'status_name');
    cmp_ok($ticket->summary, 'eq', 'test ticketing', 'summary');
}

done_testing;