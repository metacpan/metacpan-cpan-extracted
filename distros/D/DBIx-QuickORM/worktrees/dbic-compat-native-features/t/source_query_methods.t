use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;

use lib 't/lib';
use DBIx::QuickORM::Test;

# A table can bind a DBIx::QuickORM::Handle subclass (per-source query methods).
# Handles created for that source are promoted into the class, and because every
# chained clone re-blesses into ref($self), the subclass and its methods survive
# an arbitrarily long ->active->where->in_org chain. A source with no binding
# stays a plain handle, and an orm-level default is replaced (not layered) by a
# per-table binding.

BEGIN {
    package DBIx::QuickORM::Handle::SQMUser;
    $INC{'DBIx/QuickORM/Handle/SQMUser.pm'} = __FILE__;
    use parent 'DBIx::QuickORM::Handle';
    # Refinements AND onto whatever WHERE is already present (->and, not ->where,
    # which would replace), so they stack in any order.
    sub active { $_[0]->and({active => 1}) }
    sub in_org { my ($self, $id) = @_; $self->and({org_id => $id}) }

    package DBIx::QuickORM::Handle::SQMBase;
    $INC{'DBIx/QuickORM/Handle/SQMBase.pm'} = __FILE__;
    use parent 'DBIx::QuickORM::Handle';
    sub base_marker { 1 }

    package SQM::NotAHandle;
    $INC{'SQM/NotAHandle.pm'} = __FILE__;
    sub new { bless {}, shift }
}

do_for_all_dbs {
    my $db = shift;

    db mydb => sub {
        dialect curdialect();
        db_name 'quickdb';
        connect sub { $db->connect };
    };

    orm myorm => sub {
        db 'mydb';
        autofill;
        handle_class '+DBIx::QuickORM::Handle::SQMBase';    # orm-wide default
        schema myschema => sub {
            table users => sub {
                handle_class '+DBIx::QuickORM::Handle::SQMUser';    # per-source
            };
            table widgets => sub { };    # no binding -> orm default
        };
    };

    my $con = orm('myorm')->connect;
    note "dialect: " . $con->dialect->dialect_name;

    my $h = $con->handle('users');

    subtest promotion => sub {
        isa_ok($h, ['DBIx::QuickORM::Handle::SQMUser'], "users handle promoted to bound class");
        # Per-table binding replaces the orm-level default, it does not layer.
        ok(!$h->isa('DBIx::QuickORM::Handle::SQMBase'), "per-table binding replaced the orm default (no layering)");

        my $w = $con->handle('widgets');
        isa_ok($w, ['DBIx::QuickORM::Handle::SQMBase'], "unbound source falls back to the orm-level default handle class");
        ok(!$w->isa('DBIx::QuickORM::Handle::SQMUser'), "unbound source is not the users class");
    };

    subtest chaining_preserves_class => sub {
        isa_ok($h->active,                 ['DBIx::QuickORM::Handle::SQMUser'], "->active preserves subclass");
        isa_ok($h->active->in_org(1),      ['DBIx::QuickORM::Handle::SQMUser'], "->active->in_org preserves subclass");
        # Generic immutators (where/order_by/limit) must also preserve it.
        isa_ok($h->where({active => 1})->order_by('name')->limit(5), ['DBIx::QuickORM::Handle::SQMUser'], "generic immutator chain preserves subclass");
        isa_ok($h->active->and({name => 'x'})->in_org(2), ['DBIx::QuickORM::Handle::SQMUser'], "custom+generic mixed chain preserves subclass");
    };

    subtest query_methods_filter => sub {
        $h->insert({name => 'ann', active => 1, org_id => 1});
        $h->insert({name => 'bob', active => 0, org_id => 1});
        $h->insert({name => 'cid', active => 1, org_id => 2});
        $h->insert({name => 'dot', active => 1, org_id => 1});

        my @active = sort map { $_->field('name') } $h->active->all;
        is(\@active, ['ann', 'cid', 'dot'], "->active returned only active users");

        my @org1_active = sort map { $_->field('name') } $h->active->in_org(1)->all;
        is(\@org1_active, ['ann', 'dot'], "->active->in_org(1) composed both predicates");

        # Order of custom methods does not matter (both add to WHERE).
        my @same = sort map { $_->field('name') } $h->in_org(1)->active->all;
        is(\@same, ['ann', 'dot'], "->in_org->active composes the same regardless of order");
    };

    subtest subquery_source_not_promoted => sub {
        # A handle used AS a source is a subquery source; it has no per-source
        # handle_class, so the outer handle keeps the connection default.
        my $outer = $con->handle($con->handle('users')->active);
        isa_ok($outer, ['DBIx::QuickORM::Handle::SQMBase'], "outer subquery handle uses the orm default, not the inner source's class");
        ok(!$outer->isa('DBIx::QuickORM::Handle::SQMUser'), "subquery source did not leak the inner class");
    };
};

subtest validation => sub {
    require DBIx::QuickORM::Schema::Table;
    require DBIx::QuickORM::Schema::Table::Column;
    my $col = DBIx::QuickORM::Schema::Table::Column->new(name => 'id', db_name => 'id', order => 1);
    my %base = (name => 'x', columns => {id => $col});

    like(
        dies { DBIx::QuickORM::Schema::Table->new(%base, handle_class => 'SQM::NotAHandle') },
        qr/is not a subclass of 'DBIx::QuickORM::Handle'/,
        "a non-Handle handle_class croaks at table build",
    );

    like(
        dies { DBIx::QuickORM::Schema::Table->new(%base, handle_class => 'SQM::No::Such::Class::XYZ') },
        qr/Could not load handle class/,
        "an unloadable handle_class croaks at table build",
    );

    ok(
        DBIx::QuickORM::Schema::Table->new(%base, handle_class => 'DBIx::QuickORM::Handle::SQMUser'),
        "a valid Handle subclass is accepted",
    );
};

done_testing;
