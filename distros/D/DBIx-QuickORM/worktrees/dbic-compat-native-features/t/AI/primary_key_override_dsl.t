use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;

# The primary_key DSL builder accepts a leading options hashref. The only
# option is `override`, which sets the table's primary_key_override flag so a
# user-declared key wins over a conflicting database-introspected key. The
# option works at both table and column scope; unknown options croak.

subtest table_scope_override => sub {
    schema pk_override_table => sub {
        table widgets => sub {
            column id  => sub { type \'INTEGER'; affinity 'numeric' };
            column alt => sub { type \'INTEGER'; affinity 'numeric' };

            primary_key({override => 1}, 'id', 'alt');
        };
    };

    my $table = schema('pk_override_table')->{tables}->{widgets};
    is($table->primary_key, ['id', 'alt'], "declared primary key columns are set");
    ok($table->primary_key_override, "override flag is set from the options hashref");
};

subtest no_override_by_default => sub {
    schema pk_plain => sub {
        table widgets => sub {
            column id => sub { type \'INTEGER'; affinity 'numeric' };

            primary_key('id');
        };
    };

    my $table = schema('pk_plain')->{tables}->{widgets};
    is($table->primary_key, ['id'], "primary key set");
    ok(!$table->primary_key_override, "override flag is not set without the option");
};

subtest column_scope_override => sub {
    schema pk_override_column => sub {
        table widgets => sub {
            column id => sub {
                type \'INTEGER';
                affinity 'numeric';
                primary_key({override => 1});
            };
        };
    };

    my $table = schema('pk_override_column')->{tables}->{widgets};
    is($table->primary_key, ['id'], "column-scope primary key uses the column name");
    ok($table->primary_key_override, "override flag is set from the column-scope option");
};

subtest unknown_option_croaks => sub {
    my $err = dies {
        schema pk_bad_option => sub {
            table widgets => sub {
                column id => sub { type \'INTEGER'; affinity 'numeric' };
                primary_key({bogus => 1}, 'id');
            };
        };
    };

    ok($err, "unknown option croaks");
    like($err, qr/Unknown primary_key option\(s\): bogus/, "message names the bad option");
};

done_testing;
