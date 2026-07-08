use Test2::V0 '!meta', '!pass';

# Coverage for the volatile-columns DSL surface: the `volatile` column marker
# (sub form and positional form) sets Column->volatile, and the `no_volatile`
# table marker sets Table->no_volatile.

use DBIx::QuickORM;

my $schema = schema volatile_dsl => sub {
    table widgets => sub {
        column id => sub {
            primary_key;
            affinity 'numeric';
        };
        column touched_at => sub {
            affinity 'string';
            volatile;                 # sub form
        };
        column note => 'string', 'volatile';   # positional form
        column plain => sub {
            affinity 'string';
        };
    };

    table safe_ones => sub {
        no_volatile;                  # table-level assertion
        column id => sub {
            primary_key;
            affinity 'numeric';
        };
    };
};

my $widgets = $schema->table('widgets');
my $safe    = $schema->table('safe_ones');

is($widgets->column('touched_at')->volatile, 1, "volatile sub-form marks the column");
is($widgets->column('note')->volatile,       1, "volatile positional-form marks the column");
ok(!$widgets->column('plain')->volatile,     "an unmarked column is not volatile");
ok(!$widgets->column('id')->volatile,        "the primary key is not volatile by declaration");

ok(!$widgets->no_volatile,   "a table without no_volatile is not marked volatile-free");
is($safe->no_volatile, 1,    "no_volatile marks a table volatile-free");

done_testing;
