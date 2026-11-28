# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM::DSL();

my $DSL = 'DBIx::QuickORM::DSL';

# Compile and run a package from source, as loading its module would.
sub load {
    my ($code) = @_;
    eval "$code\n;1" or die $@;
}

sub has_sub {
    my ($package, $name) = @_;
    no strict 'refs';
    return defined(&{"$package\::$name"}) ? 1 : 0;
}

subtest import => sub {
    load('package DSLT::Import; use DBIx::QuickORM::DSL qw/:table/;');
    ok(has_sub('DSLT::Import',  $_), "'$_' is imported") for qw/table name omit default_fields type fk row_class/;
    ok(!has_sub('DSLT::Import', $_), "'$_' is not")      for qw/row orm parent tables/;

    like(dies { load('package DSLT::None; use DBIx::QuickORM::DSL;') },                                             qr/^Name the tags to import/,                            "Importing nothing croaks");
    like(dies { load('package DSLT::Bad; use DBIx::QuickORM::DSL qw/:view/;') },                                    qr/does not export the :view tag/,                       "An unknown tag croaks");
    like(dies { load('package DSLT::Plain; use DBIx::QuickORM::DSL qw/table/;') },                                  qr/^Import the DSL by tag \(:orm, :table, :row\)/,       "A block by name croaks");
    like(dies { load('package DSLT::Part; use DBIx::QuickORM::DSL qw/:table !fk/;') },                              qr/^Import the DSL by tag/,                              "and so does part of a tag");
    like(dies { load('package DSLT::Kw; use DBIx::QuickORM::DSL qw/:row name/;') },                                 qr/^Import the DSL by tag/,                              "or a keyword of a block not imported");
    like(dies { load('package DSLT::Both; use DBIx::QuickORM::DSL qw/:orm :table/;') },                             qr/^DSLT::Both cannot be both an ORM class and a table/, "orm with table croaks");
    like(dies { load('package DSLT::Both2; use DBIx::QuickORM::DSL qw/:row/; use DBIx::QuickORM::DSL qw/:orm/;') }, qr/cannot be both an ORM class/,                         "even in separate imports");
    like(
        dies { load('package DSLT::Had; sub type { 1 } BEGIN { DBIx::QuickORM::DSL->import(":table") }') },
        qr/^DSLT::Had already has a sub named 'type', which the DSL would replace/,
        "Importing over an existing sub croaks",
    );
};

subtest table => sub {
    load(<<'    EOT');
        package DSLT::Table;
        use DBIx::QuickORM::DSL qw/:table/;
        our @name = ('kept');
        sub upper { uc $_[0] }
        table {
            name 'users';
            omit qw/bio/;
            omit qw/notes/;
            type prefs  => 'JSON';
            type legacy => undef;
            type token  => {class => 'UUID', format => \&DSLT::Table::upper};
            fk orgs     => {org_id => 'id'};
            fk orgs     => {alt_org => 'id'};
            row_class 'My::Row';
        };
    EOT

    is(
        $DSL->table_spec('DSLT::Table'),
        {
            name      => 'users',
            omit      => [qw/bio notes/],
            types     => {prefs => 'JSON', legacy => undef, token => {class => 'UUID', format => \&DSLT::Table::upper}},
            fks       => {orgs  => [{org_id => 'id'}, {alt_org => 'id'}]},
            row_class => 'My::Row',
        },
        "The block collects new() arguments for its table",
    );
    ok(!has_sub('DSLT::Table', $_), "'$_' is gone once the block finishes") for qw/table name omit default_fields type fk row_class/;
    is(do { no warnings 'once'; \@DSLT::Table::name }, ['kept'], "Other slots of a removed name survive");
    is($DSL->orm_spec('DSLT::Table'),                  undef,    "No orm spec");

    load('package DSLT::Fields; use DBIx::QuickORM::DSL qw/:table/; table { name "t"; default_fields qw/a b/ };');
    is($DSL->table_spec('DSLT::Fields'), {name => 't', default_fields => [qw/a b/]}, "default_fields");

    like(dies { load('package DSLT::NoName; use DBIx::QuickORM::DSL qw/:table/; table { omit "x" };') }, qr/^The 'table' block in DSLT::NoName needs a 'name'/, "A block without 'name' croaks");
    like(
        dies { load('package DSLT::Omit; use DBIx::QuickORM::DSL qw/:table/; table { name "t"; omit "a"; default_fields "b" };') },
        qr/^The 'table' block in DSLT::Omit gives both 'omit' and 'default_fields'/,
        "omit with default_fields croaks",
    );
    like(dies { load('package DSLT::Twice; use DBIx::QuickORM::DSL qw/:table/; table { name "a" }; table { name "b" };') }, qr/^The 'table' block in DSLT::Twice already ran; each block runs once per package/, "A second block croaks");
};

subtest row => sub {
    load('package DSLT::Row; use DBIx::QuickORM::DSL qw/:row/; row { parent };');
    is(\@DSLT::Row::ISA, ['DBIx::QuickORM::Row'], "parent defaults to DBIx::QuickORM::Row");
    ok(!has_sub('DSLT::Row', $_), "'$_' is gone once the block finishes") for qw/row parent with_role/;
    is($DSL->table_spec('DSLT::Row'), undef, "A row block registers nothing");

    load('package DSLT::Row2; use DBIx::QuickORM::DSL qw/:row/; row { parent "DBIx::QuickORM::Test::Row" };');
    is(\@DSLT::Row2::ISA, ['DBIx::QuickORM::Test::Row'], "parent takes a class, loading it");

    load('package DSLT::InMemoryBase; our @ISA = ("DBIx::QuickORM::Row");');
    load('package DSLT::RowInMemory; use DBIx::QuickORM::DSL qw/:row/; row { parent "DSLT::InMemoryBase" };');
    is(\@DSLT::RowInMemory::ISA, ['DSLT::InMemoryBase'], "parent takes a class already defined with no .pm file");

    load('package DSLT::Row3; use DBIx::QuickORM::DSL qw/:row/; row { parent; parent };');
    is(\@DSLT::Row3::ISA, ['DBIx::QuickORM::Row'], "parent twice adds the class once");

    like(
        dies { load('package DSLT::RowMissing; use DBIx::QuickORM::DSL qw/:row/; row { parent "No::Such::Parent" };') },
        qr{^parent names the class 'No::Such::Parent', which could not be loaded: Can't locate No/Such/Parent\.pm},
        "A parent that cannot be loaded croaks",
    );

    load('package DSLT::Role; use Object::HashBase qw/<orm <table row_data/; use DBIx::QuickORM::DSL qw/:row/; row { with_role };');
    ok(DSLT::Role->DOES('DBIx::QuickORM::Role::Row'), "with_role defaults to DBIx::QuickORM::Role::Row");
    can_ok('DSLT::Role', [qw/field update follow_fk/], "and applies it");
};

subtest combined => sub {
    load(<<'    EOT');
        package DSLT::Combined;
        use DBIx::QuickORM::DSL qw/:table :row/;
        table { name 'users' };
        row { parent };
        sub display_name { 'x' }
    EOT

    is($DSL->table_spec('DSLT::Combined'), {name => 'users', row_class => 'DSLT::Combined'}, "A table and row package is its table's row class");
    is(DSLT::Combined->can('table'),       DBIx::QuickORM::Row->can('table'),                "'table' is the row accessor again once the block is gone");
    ok(!DSLT::Combined->can($_), "no '$_' method left") for qw/row name type parent/;

    load('package DSLT::Same; use DBIx::QuickORM::DSL qw/:table :row/; table { name "t"; row_class "DSLT::Same" }; row { parent };');
    is($DSL->table_spec('DSLT::Same')->{row_class}, 'DSLT::Same', "row_class may name the package itself");

    load('package DSLT::RowFirst; use DBIx::QuickORM::DSL qw/:table :row/; row { parent }; table { name "t" };');
    is($DSL->table_spec('DSLT::RowFirst')->{row_class}, 'DSLT::RowFirst', "The row block may come first");

    load('package DSLT::NoRow; use DBIx::QuickORM::DSL qw/:table :row/; table { name "t" };');
    is($DSL->table_spec('DSLT::NoRow'), {name => 't'}, "Importing :row registers nothing: without a row block the table keeps the default row class");

    load('package DSLT::Later; use DBIx::QuickORM::DSL qw/:table :row/; table { name "t" };');
    is($DSL->table_spec('DSLT::Later'), {name => 't'}, "Before its row block runs, the package is not the row class");
    load('package DSLT::Later; row { parent };');
    is($DSL->table_spec('DSLT::Later')->{row_class}, 'DSLT::Later', "and becomes it when the row block runs");

    load('package DSLT::NoTable; use DBIx::QuickORM::DSL qw/:table :row/;');
    is($DSL->table_spec('DSLT::NoTable'), undef, "Importing :table registers nothing until the table block runs");

    like(
        dies { load('package DSLT::Other; use DBIx::QuickORM::DSL qw/:table :row/; table { name "t"; row_class "My::Row" }; row { parent };') },
        qr/^DSLT::Other is the row class of the table 't', but its 'row_class' names My::Row/,
        "row_class naming another class croaks when the row block runs",
    );
    like(
        dies { load('package DSLT::OtherFirst; use DBIx::QuickORM::DSL qw/:table :row/; row { parent }; table { name "t"; row_class "My::Row" };') },
        qr/^DSLT::OtherFirst is the row class of the table 't', but its 'row_class' names My::Row/,
        "or when the table block runs after it",
    );
    like(dies { load('package DSLT::Undef; use DBIx::QuickORM::DSL qw/:table :row/; table { name "t"; row_class undef }; row { parent };') }, qr/'row_class' names undef/,                       "and so does undef");
    like(dies { load('package DSLT::Wrong; use DBIx::QuickORM::DSL qw/:table :row/; row { name "t" };') },                                    qr/^'name' can only be used inside 'table' block/, "A keyword in another block croaks");
};

subtest collision => sub {
    my $warnings = warnings {
        like(
            dies { load('package DSLT::CollideName; use DBIx::QuickORM::DSL qw/:table/; table { name "t" }; sub name { "mine" }') },
            qr/^The DSL keyword 'name' in DSLT::CollideName, installed as 'name', was replaced or removed before its 'table' block ran/,
            "A sub named like a keyword after the block, with no 'no', croaks",
        );
    };
    like($warnings, [qr/^Subroutine name redefined/], "after Perl's own warning");

    $warnings = warnings {
        like(
            dies { load('package DSLT::Collide; use DBIx::QuickORM::DSL qw/:table :row/; table { name "t" }; sub type { "row method" }') },
            qr/^The DSL keyword 'type' in DSLT::Collide, installed as 'type', was replaced or removed before its 'table' block ran; rename the keyword \(e\.g\. type => \{-as => 'my_type'\}\), move any sub named 'type' to another package, or put 'no DBIx::QuickORM::DSL' before that sub/,
            "A row method named like a keyword croaks before the block runs",
        );
    };
    like($warnings, [qr/^Subroutine type redefined/], "after Perl's own warning at compile time");
    is($DSL->table_spec('DSLT::Collide'), undef, "and nothing is registered");
};

subtest orm => sub {
    load(<<'    EOT');
        package DSLT::ORM;
        use DBIx::QuickORM::DSL qw/:orm/;
        orm {
            row_class undef;
            autotype qw/UUID JSON/;
            append_autotype '+My::Type';
            retain_cache 1;
            tables [qw/My::A My::B/];
            override(types => {t => {f => 'JSON'}}, time_zone => 'UTC');
            override(types => {u => {g => undef}});
        };
    EOT

    is(
        $DSL->orm_spec('DSLT::ORM'),
        {
            row_class       => undef,
            autotype        => [qw/UUID JSON/],
            append_autotype => ['+My::Type'],
            retain_cache    => 1,
            tables          => [qw/My::A My::B/],
            override        => {types => {u => {g => undef}}, time_zone => 'UTC'},
        },
        "The block collects new() arguments; a later override() replaces an argument an earlier one gave",
    );
    isa_ok('DSLT::ORM', ['DBIx::QuickORM::ORM'], "The package becomes a DBIx::QuickORM::ORM subclass");
    ok(!has_sub('DSLT::ORM', $_), "'$_' is gone once the block finishes") for qw/orm row_class autotype append_autotype retain_cache tables override/;
    is($DSL->table_spec('DSLT::ORM'), undef, "No table spec");

    load('package DSLT::Off; use DBIx::QuickORM::DSL qw/:orm/; orm { autotype };');
    is($DSL->orm_spec('DSLT::Off'), {autotype => []}, "autotype with no types turns autotyping off");

    like(
        dies { load('package DSLT::Conn; use DBIx::QuickORM::DSL qw/:orm/; orm { override(dbh => 1, credentials => {}, retain_cache => 1) };') },
        qr/^override\(\) cannot take the connection argument\(s\): credentials, dbh/,
        "override() croaks on the connection forms",
    );
};

subtest unimport => sub {
    load('package DSLT::No; use DBIx::QuickORM::DSL qw/:table :row/; no DBIx::QuickORM::DSL;');
    ok(!has_sub('DSLT::No', $_), "'$_' is gone") for qw/table row name parent/;

    load('package DSLT::NoTable; use DBIx::QuickORM::DSL qw/:table :row/; no DBIx::QuickORM::DSL qw/:table/;');
    ok(!has_sub('DSLT::NoTable', $_), "'$_' is gone") for qw/table name type/;
    ok(has_sub('DSLT::NoTable',  $_), "'$_' stays")   for qw/row parent/;

    load('package DSLT::Early; use DBIx::QuickORM::DSL qw/:table/; table { name "early" }; no DBIx::QuickORM::DSL;');
    is($DSL->table_spec('DSLT::Early'), {name => 'early'}, "A block compiled before a trailing 'no' still runs");

    my $warnings = warnings {
        like(
            dies { load('package DSLT::Late; use DBIx::QuickORM::DSL qw/:table/; table { name "t" }; sub name { "mine" }; no DBIx::QuickORM::DSL;') },
            qr/^The DSL keyword 'name' in DSLT::Late, installed as 'name', was replaced or removed/,
            "A sub defined before a trailing 'no' replaces the keyword, so the block croaks",
        );
    };
    like($warnings, [qr/^Subroutine name redefined/], "after Perl's own warning");
    is($DSL->table_spec('DSLT::Late'), undef, "and nothing is registered");

    $warnings = warnings { load('package DSLT::After; use DBIx::QuickORM::DSL qw/:table/; table { name "after" }; no DBIx::QuickORM::DSL; sub name { "mine" }') };
    is($warnings,                       [],                "A sub defined after 'no' lands in a new name, no warning");
    is($DSL->table_spec('DSLT::After'), {name => 'after'}, "and the block still uses the keyword");
    is(DSLT::After->can('name')->(),    'mine',            "while the sub is callable on its own");

    like(dies { load('package DSLT::NoBad; no DBIx::QuickORM::DSL qw/table/;') }, qr/^Unknown tag\(s\): table; give :orm, :table, or :row/, "Anything but a tag croaks");
};

subtest rename => sub {
    load(<<'    EOT');
        package DSLT::Renamed;
        use DBIx::QuickORM::DSL ':table', type => {-as => 'col_type'}, ':row';
        BEGIN { main::ok(!main::has_sub('DSLT::Renamed', 'type'), "A renamed keyword is not also installed under its own name") }
        table { name 'users'; col_type prefs => 'JSON' };
        row { parent };
        sub type { 'row method' }
    EOT
    is($DSL->table_spec('DSLT::Renamed'), {name => 'users', types => {prefs => 'JSON'}, row_class => 'DSLT::Renamed'}, "The renamed keyword works inside the block");
    ok(!has_sub('DSLT::Renamed', 'col_type'), "and is removed once the block finishes");
    is(DSLT::Renamed->type, 'row method', "while a sub of the keyword's own name is left alone");

    load('package DSLT::Prefixed; use DBIx::QuickORM::DSL ":table" => {-prefix => "t_"}; t_table { t_name "p" };');
    is($DSL->table_spec('DSLT::Prefixed'), {name => 'p'}, "A prefix renames the whole tag");
    ok(!has_sub('DSLT::Prefixed', $_), "'$_' is gone") for qw/t_table t_name t_type/;

    like(
        dies { load('package DSLT::RenHad; sub col_type { 1 } BEGIN { DBIx::QuickORM::DSL->import(":table", type => {-as => "col_type"}) }') },
        qr/^DSLT::RenHad already has a sub named 'col_type', which the DSL would replace/,
        "Importing a renamed keyword over an existing sub croaks",
    );

    my $warnings = warnings {
        like(
            dies { load('package DSLT::RenCollide; use DBIx::QuickORM::DSL ":table", type => {-as => "col_type"}; table { name "t" }; sub col_type { 1 }') },
            qr/^The DSL keyword 'type' in DSLT::RenCollide, installed as 'col_type', was replaced or removed before its 'table' block ran/,
            "A sub taking over a renamed keyword croaks before the block runs",
        );
    };
    like($warnings, [qr/^Subroutine col_type redefined/], "after Perl's own warning");

    load('package DSLT::RenTrail; use DBIx::QuickORM::DSL ":table", type => {-as => "col_type"}; table { name "t"; col_type a => "JSON" }; no DBIx::QuickORM::DSL;');
    is($DSL->table_spec('DSLT::RenTrail'), {name => 't', types => {a => 'JSON'}}, "A renamed keyword works with a trailing 'no'");

    load(<<'    EOT');
        package DSLT::RenNo;
        use DBIx::QuickORM::DSL ':table', type => {-as => 'col_type'}, ':row';
        no DBIx::QuickORM::DSL ':row';
        BEGIN { main::ok(!main::has_sub('DSLT::RenNo', $_), "'$_' is removed by 'no'") for qw/row parent/ }
        BEGIN { main::ok(main::has_sub('DSLT::RenNo', 'col_type'), "while the table keywords stay") }
        no DBIx::QuickORM::DSL;
        BEGIN { main::ok(!main::has_sub('DSLT::RenNo', 'col_type'), "a bare 'no' removes a renamed keyword too") }
    EOT
};

subtest outside => sub {
    like(dies { DBIx::QuickORM::DSL::name('x') },      qr/^'name' can only be used inside 'table' block/,               "A keyword outside its block croaks");
    like(dies { DBIx::QuickORM::DSL::row_class('x') }, qr/^'row_class' can only be used inside 'orm' or 'table' block/, "naming every block that takes it");
};

done_testing;
