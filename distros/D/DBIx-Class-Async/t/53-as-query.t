#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use DBIx::Class::Async::ResultSet;

# Define a real Result class for the metadata schema to use
{
    package Mock::Result::User;
    use base 'DBIx::Class::Core';
    __PACKAGE__->table('users');
    __PACKAGE__->add_columns(qw/id status age/);
    __PACKAGE__->set_primary_key('id');

    package Mock::Schema::Full;
    use base 'DBIx::Class::Schema';
    # Register the real class we just made
    __PACKAGE__->register_class('User', 'Mock::Result::User');
}

subtest 'as_query SQL generation bridge' => sub {
    my $bridge = bless {
        schema_class => 'Mock::Schema::Full'
    }, 'Mock::DB';

    my $async_schema = bless { db => $bridge }, 'Mock::AsyncSchema';

    my $rs = DBIx::Class::Async::ResultSet->new(
        source_name => 'User',
        schema      => $async_schema,
        async_db    => $bridge,
        cond        => { status => 'active' },
        attrs       => { order_by => 'id DESC' },
    );

    $rs->{_cond}  = { status => 'active' };
    $rs->{_attrs} = { order_by => 'id DESC' };

    my $query_ref;
    eval { $query_ref = $rs->as_query };

    ok(!$@, 'as_query executed without crashing') or diag("Error: $@");

    # Check that we got a reference to an array
    # In DBIC, as_query usually returns \[ $sql, @bind ]
    is(ref($query_ref), 'REF', 'Returns a reference to a reference');
    is(ref($$query_ref), 'ARRAY', 'De-referenced value is an ARRAY');

    my ($sql, @bind) = @{ $$query_ref };
    like($sql, qr/WHERE/i, 'SQL now contains WHERE clause');
    like($sql, qr/status/i, 'SQL contains column name');

    done_testing;
};

done_testing;
