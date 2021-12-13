#!/usr/bin/perl

use strict;
use warnings;
use Avatica::Client;
use Data::Dumper;

my $connection_id = int(rand(111)) . $$;

print $connection_id, $/;

my $client = Avatica::Client->new(url => 'http://hpqs:8765');
my ($res, $connection) = $client->open_connection($connection_id);

($res, my $prepare) = $client->prepare($connection_id, 'select * from test where id > ?');

my $statement = $prepare->get_statement;
my $statement_id = $statement->get_id;
my $signature = $statement->get_signature;

print "prepare statement id: $statement_id", $/;

sub avatica_exec {
    my $tv = shift;

    ($res, my $execute) = $client->execute($connection_id, $statement_id, $signature, [$tv], 2);
    my $result = $execute->get_results(0);

    print "execute statement id: ", $result->get_statement_id , $/;

    print
        join (
            ', ',
            map { ($_->get_value(0)->get_scalar_value->get_number_value, $_->get_value(1)->get_scalar_value->get_string_value) }
            @{$result->get_first_frame->get_rows_list}
        ), $/;

    ($res, my $fetch) = $client->fetch($connection_id, $prepare->get_statement->get_id, undef, 3);

    print
        join (
            ', ',
            map { ($_->get_value(0)->get_scalar_value->get_number_value, $_->get_value(1)->get_scalar_value->get_string_value) }
            @{$fetch->get_frame->get_rows_list}
        ), $/;
}

my $tv1 = Avatica::Client::Protocol::TypedValue->new;
$tv1->set_number_value(5);
$tv1->set_type(Avatica::Client::Protocol::Rep::INTEGER());

avatica_exec($tv1);
<>;

my $tv2 = Avatica::Client::Protocol::TypedValue->new;
$tv2->set_number_value(0);
$tv2->set_type(Avatica::Client::Protocol::Rep::INTEGER());

avatica_exec($tv2);
<>;

my $tv3 = Avatica::Client::Protocol::TypedValue->new;
$tv3->set_number_value(8);
$tv3->set_type(Avatica::Client::Protocol::Rep::INTEGER());

avatica_exec($tv3);
<>;
