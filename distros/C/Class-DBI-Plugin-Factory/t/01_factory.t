use strict;
use Test::More;
use lib 't/lib';

BEGIN {
	eval "require Class::DBI::SQLite";
	plan $@ ? ( skip_all => 'needs Class::DBI::SQLite for testing' ) : ( tests => 19 );
}

require_ok('MyService::Member');

MyService::Member->CONSTRUCT;
my @member = MyService::Member->retrieve_all;
@member = sort{ $a->member_id <=> $b->member_id } @member;

isa_ok($member[0], 'MyService::Member::Basic');
isa_ok($member[1], 'MyService::Member::Free');
isa_ok($member[2], 'MyService::Member::VIP');
is($member[0]->name, 'Mirko');
is($member[1]->name, 'Nogueira');
is($member[2]->name, 'Fedor');
is($member[0]->age, 30);
is($member[1]->age, 29);
is($member[2]->age, 28);
is($member[0]->member_type, 0);
is($member[1]->member_type, 1);
is($member[2]->member_type, 2);
is($member[0]->member_id, 1);
is($member[1]->member_id, 2);
is($member[2]->member_id, 3);
is($member[0]->monthly_cost, 500);
is($member[1]->monthly_cost, 0);
is($member[2]->monthly_cost, 250);
