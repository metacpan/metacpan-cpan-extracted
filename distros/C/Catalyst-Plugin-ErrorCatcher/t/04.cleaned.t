#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Catalyst::Plugin::ErrorCatcher;

my @test_cases = (
    {
        original    => q{Caught exception in SomeApp::Controller::Root->error500 "Can't locate object method "foo_forward" via package "SomeApp" at /home/person/development/someapp/script/../lib/SomeApp/Controller/Root.pm line 87."},
        cleaned     => q{Can't locate object method "foo_forward" via package "SomeApp"},
    },
    {
        original    => q{Error: DBIx::Class::ResultSetColumn::all(): DBI Exception: DBD::Pg::st execute failed: ERROR:  column me.name does not exist at character 8 [for Statement "SELECT me.name FROM product.product_channel me JOIN public.channel channel ON channel.id = me.channel_id WHERE ( ( me.product_id = ? AND me.creation_status_id = ? ) )" with ParamValues: 1='76660', 2='17'] at /opt/someapp/script/lib/SomeModule line 40},
        cleaned     => q{column me.name does not exist},
    },
    {
        original    => q{DBIx::Class::Schema::txn_do(): txn death at /home/chisel/development/github/TxnDo/script/../lib/TxnDo/Controller/Root.pm line 41.},
        cleaned     => q{txn death},
    },

    {
        original    => qq{Error: encountered object 'DBIx::Class::AuditLog::delete(): DBI Exception: DBD::Pg::st execute failed: ERROR:  update or delete on table "TheTable" violates foreign key constraint "foo_fkey" on table "fkey_table"\nDETAIL:  Key (id, thing_id)=(1, 5) is still referenced from table "fkey_table". [for Statement "DELETE FROM public.thingy WHERE ( id = ? )" with ParamValues: 1='1']},
        cleaned     => q{Foreign key constraint violation: TheTable -> fkey_table [foo_fkey]},
    },

    {
        original    => q{Error: DBIx::Class::AuditLog::update(): DBI Exception: DBD::Pg::st execute failed: ERROR:  current transaction is aborted, commands ignored until end of transaction block [for Statement "INSERT INTO some.table ( col1, col2 ) VALUES ( ?, ? ) RETURNING id" with ParamValues: 1='one', 2='two'] at /opt/someapp/script/lib/SomeModule line 69},
        cleaned     => q{current transaction is aborted, commands ignored until end of transaction block},
    },

    {
        original    => q{Error: DBIx::Class::Relationship::CascadeActions::update(): DBI Exception: DBD::Pg::st execute failed: ERROR:  duplicate key value violates unique constraint "my_really_unique_constraint"
DETAIL:  Key (field_wot_is_unique)=(OHNOESADUPEVALUE) already exists. [for Statement "UPDATE some.table SET something=something" with ParamValues: 5='OHNOESADUPEVALUE', 9='2'] at /opt/someapp/script/lib/SomeModule line 2666},
        cleaned     => q{Unique constraint violation: field_wot_is_unique -> OHNOESADUPEVALUE [my_really_unique_constraint]},
    },
);

foreach my $test (@test_cases) {
    is(
        Catalyst::Plugin::ErrorCatcher::_cleaned_error_message($test->{original}),
        $test->{cleaned},
        'cleaned to: ' . $test->{cleaned},
    );
}

done_testing;
