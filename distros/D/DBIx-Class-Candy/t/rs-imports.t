use strict;
use warnings;
use Test::More;
use MRO::Compat;

use lib 't/lib';


use IRC::Schema;

is(mro::get_mro('IRC::Schema::ResultSet::User'), 'c3', 'mro');
ok(IRC::Schema::ResultSet::User->isa('IRC::Schema::ResultSet'), 'base');

ok(IRC::Schema::ResultSet::Channel->isa('IRC::Schema::ResultSet'), 'base defaulted');

done_testing;
