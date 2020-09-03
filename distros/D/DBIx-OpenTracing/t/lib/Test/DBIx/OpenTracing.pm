package Test::DBIx::OpenTracing;
use strict;
use warnings;
use parent 'Exporter';
use syntax 'maybe';
use Test::Most;
use Test::OpenTracing::Integration;
use DBIx::OpenTracing::Constants ':ALL';

our @EXPORT_OK = qw[ any_caller_tags test_database ];

sub _sub_here { __PACKAGE__ . "::$_[0]" }

sub test_database {
    my %args        = @_;
    my $dbh         = $args{dbh};
    my $user        = $args{user};
    my $db_name     = $args{db_name};
    my $statements  = $args{statements};
    my $sql_invalid = $statements->{invalid};
    my $sql_simple  = $statements->{simple};
    my $sql_clear   = $statements->{clear};

    my %tag_base = (
              'caller.file'    => __FILE__,
              'caller.line'    => re(qr/\A\d+\z/),
              'caller.package' => __PACKAGE__,
              'db.type'        => 'sql',
        maybe 'db.instance'    => $db_name,
        maybe 'db.user'        => $user,
    );
    span_generation_ok($dbh, $statements, {%tag_base});
    error_detection_ok($dbh, $sql_invalid, {%tag_base});
    enable_disable_ok($dbh, $sql_simple);
    compatibility_ok($dbh, $statements);
    tag_control_ok($dbh, $statements->{bind}, {%tag_base});
    comments_ok($dbh, $statements->{comments});
    execute_ok($dbh, @$statements{qw[ clear insert select_all_multi ]}, {%tag_base});

    return;
}

sub span_generation_ok {
    my ($dbh, $statements, $tag_base) = @_;

    my $sql_create = $statements->{create};
    create_ok($dbh, $sql_create, $tag_base);

    my $sql_insert = $statements->{insert};
    insert_ok($dbh, $sql_insert, $tag_base);

    my $sql_delete = $statements->{delete};
    delete_ok($dbh, $sql_delete, $tag_base);

    my $sql_select_all_multi = $statements->{select_all_multi};
    selectall_multi_ok($dbh, $sql_select_all_multi, $tag_base);

    my $sql_select_all_single = $statements->{select_all_single};
    selectall_single_ok($dbh, $sql_select_all_single, $tag_base);

    my $sql_select_empty = $statements->{select_empty};
    selectall_empty_ok($dbh, $sql_select_empty, $tag_base);

    my $sql_select_column_multi = $statements->{select_column_multi};
    selectcol_ok($dbh, $sql_select_column_multi, $tag_base);

    return;
}

# CREATE TABLE things (id INTEGER PRIMARY KEY, description TEXT)
sub create_ok {
    my ($dbh, $sql_create, $tag_base) = @_;
    $tag_base->{'caller.subname'} = _sub_here('create_ok');

    $dbh->do($sql_create);
    global_tracer_cmp_easy([{
        operation_name => 'dbi_do',
        tags           => {
            %$tag_base,
            'db.statement'         => $sql_create,
            'db.statement_summary' => 'CREATE: things',
            'db.rows'              => 0,
        },
    }], 'do - table creation');

    return;
}

# INSERT INTO things (id, description)
# VALUES
#     (1, 'some thing'),
#     (2, 'other thing'),
#     (3, 'this is a thing'),
#     (4, 'cool thing'),
#     (5, 'very cool thing')
sub insert_ok {
    my ($dbh, $sql_insert, $tag_base) = @_;
    $tag_base->{'caller.subname'} = _sub_here('insert_ok');

    reset_spans();
    $dbh->do($sql_insert);
    global_tracer_cmp_easy([{
        operation_name => 'dbi_do',
        tags => {
            %$tag_base,
            'db.statement'         => $sql_insert,
            'db.statement_summary' => 'INSERT: things',
            'db.rows'              => 5,
        },
    }], 'do - insert');

    return;
}

# DELETE FROM things WHERE id IN (4, 5)
sub delete_ok {
    my ($dbh, $sql_delete, $tag_base) = @_;
    $tag_base->{'caller.subname'} = _sub_here('delete_ok');

    reset_spans();
    $dbh->do($sql_delete);
    global_tracer_cmp_easy([{
        operation_name => 'dbi_do',
        tags => {
            %$tag_base,
            'db.statement'         => $sql_delete,
            'db.statement_summary' => 'DELETE: things',
            'db.rows'              => 2,
        },
    }], 'do - delete');

    return;
}

# SELECT * FROM things WHERE id IN (1, 3, 10)
sub selectall_multi_ok {
    my ($dbh, $sql_select, $tag_base) = @_;
    $tag_base->{'caller.subname'} = _sub_here('selectall_multi_ok');

    my @selectall_methods = qw[
        selectall_arrayref
        selectall_array
    ];
    foreach my $selectall (@selectall_methods) {
        reset_spans();

        $dbh->$selectall($sql_select);

        global_tracer_cmp_deeply([superhashof({
            operation_name => "dbi_$selectall",
            tags => {
                %$tag_base,
                'db.statement'         => $sql_select,
                'db.statement_summary' => 'SELECT: things',
                'db.rows'              => 2,
            },
        })], $selectall);
    }

    reset_spans();
    $dbh->selectall_hashref($sql_select, 'id');
    global_tracer_cmp_deeply([superhashof({
        operation_name => 'dbi_selectall_hashref',
        tags => {
            %$tag_base,
            'db.statement'         => $sql_select,
            'db.statement_summary' => 'SELECT: things',
            'db.rows'              => 2
        },
    })], 'selectall_hashref');

    return;
}

# SELECT * FROM things WHERE id = 2
sub selectall_single_ok {
    my ($dbh, $sql_select, $tag_base) = @_;
    $tag_base->{'caller.subname'} = _sub_here('selectall_single_ok');

    my @selectrow_methods = qw[
        selectrow_array
        selectrow_arrayref
        selectrow_hashref
    ];
    foreach my $selectrow (@selectrow_methods) {
        reset_spans();
        $dbh->$selectrow($sql_select);
        global_tracer_cmp_easy([{
            operation_name => "dbi_$selectrow",
            tags           => {
                %$tag_base,
                'db.statement'         => $sql_select,
                'db.statement_summary' => 'SELECT: things',
            },
        }], $selectrow);
    }

    return;
}

# SELECT * FROM things WHERE id = 999
sub selectall_empty_ok {
    my ($dbh, $sql_select, $tag_base) = @_;
    $tag_base->{'caller.subname'} = _sub_here('selectall_empty_ok');


    my @methods = qw[
        selectall_array
        selectall_arrayref
    ];
    foreach my $method (@methods) {
        reset_spans();

        $dbh->$method($sql_select);
        my $result = $dbh->$method($sql_select);
        my @result = $dbh->$method($sql_select);
        
        global_tracer_cmp_easy([
            ({
                operation_name => "dbi_$method",
                tags => {
                    %$tag_base,
                    'db.statement'         => $sql_select,
                    'db.statement_summary' => 'SELECT: things',
                    'db.rows'              => 0,
                },
            }) x 3,
        ], "$method - empty result");
    }

    reset_spans();
    $dbh->selectall_hashref($sql_select, 'id');
    my $result = $dbh->selectall_hashref($sql_select, 'id');
    my @result = $dbh->selectall_hashref($sql_select, 'id');

    global_tracer_cmp_easy([
        ({
            operation_name => 'dbi_selectall_hashref',
            tags => {
                %$tag_base,
                'db.statement'         => $sql_select,
                'db.statement_summary' => 'SELECT: things',
                'db.rows'              => 0,
            },
        }) x 3,
    ], 'selectall_hashref - empty result');

    return;
}

# SELECT description FROM things WHERE id IN (2, 3, 10)
sub selectcol_ok {
    my ($dbh, $sql_select, $tag_base) = @_;
    $tag_base->{'caller.subname'} = _sub_here('selectcol_ok');

    reset_spans();
    $dbh->selectcol_arrayref($sql_select);
    global_tracer_cmp_easy([{
        operation_name => 'dbi_selectcol_arrayref',
        tags => {
            %$tag_base,
            'db.statement'         => $sql_select,
            'db.statement_summary' => 'SELECT: things',
            'db.rows'              => 2,
        },
    }], 'selectcol_arrayref');

    return;
}

sub error_detection_ok {
    my ($dbh, $sql_invalid, $tag_base) = @_;

    my @methods = qw(
        do
        selectrow_array
        selectrow_arrayref
        selectall_arrayref
        selectall_array
    );
    foreach my $raise_error (0, 1) {
        my ($test, $type) = $raise_error ? (\&dies_ok, 'dies') : (\&lives_ok, 'lives');
        local $dbh->{RaiseError} = $raise_error;
        local $dbh->{PrintError} = 0;

        subtest "Exceptions with RaiseError = $raise_error" => sub {
            foreach my $method (@methods) {
                reset_spans();
                $test->(sub { $dbh->$method($sql_invalid) }, "$method $type");
                global_tracer_cmp_easy([{
                    operation_name => "dbi_$method",
                    tags => {
                        %$tag_base,
                        'caller.subname' => _sub_here('__ANON__'),
                        'db.statement'   => $sql_invalid,
                        error            => 1,
                    },
                }], "$method produces a span with correct tags");
            }
        };
    }

    return;
}

sub enable_disable_ok {
    my ($dbh, $sql) = @_;

    my @actions = (
        sub { $dbh->do($sql) },
        sub { $dbh->prepare($sql)->execute() },
        sub { $dbh->selectall_arrayref($sql) },
        sub { $dbh->selectall_array($sql) },
        sub { $dbh->selectall_hashref($sql, '1') },
        sub { $dbh->selectrow_array($sql) },
        sub { $dbh->selectrow_arrayref($sql) },
        sub { $dbh->selectrow_hashref($sql) },
        sub { $dbh->selectcol_arrayref($sql) },
    );
    my $run_all_actions = sub { $_->() foreach @actions };

    reset_spans();

    DBIx::OpenTracing->disable();
    $run_all_actions->();
    global_tracer_cmp_deeply([], 'no spans when plugin is disabled');

    reset_spans();
    DBIx::OpenTracing->enable();
    $run_all_actions->();
    my $span = superhashof({
        tags => superhashof({ 'db.statement' => $sql })
    });
    global_tracer_cmp_deeply([($span) x @actions], 'correct number of spans when plugin is enabled');

    reset_spans();
    DBIx::OpenTracing->enable();
    $run_all_actions->();
    global_tracer_cmp_deeply([($span) x @actions], 'double enable');

    reset_spans();
    {
        DBIx::OpenTracing->disable_temporarily();
        $dbh->do($sql);
    }
    global_tracer_cmp_deeply([], 'no spans when temporarily disabled');
    $dbh->do($sql);
    global_tracer_cmp_easy([{ operation_name => 'dbi_do' }], 'functionality back when out of scope');

    reset_spans();
    DBIx::OpenTracing->disable();
    {
        DBIx::OpenTracing->enable_temporarily();
        $dbh->do($sql);
    }
    global_tracer_cmp_easy([{ operation_name => 'dbi_do' }], 'functionality back when temporarily enabled');
    $dbh->do($sql);
    global_tracer_cmp_deeply([ superhashof({}) ], 'no extra spans when disabled again');

    reset_spans();
    DBIx::OpenTracing->enable();
    {
        DBIx::OpenTracing->disable_temporarily();
        { DBIx::OpenTracing->disable_temporarily() }
        $dbh->do($sql);
    }
    global_tracer_cmp_deeply([], 'no spans when temporarily disabled twice');
    
    reset_spans();
    DBIx::OpenTracing->disable();
    {
        DBIx::OpenTracing->enable_temporarily();
        { DBIx::OpenTracing->enable_temporarily() }
        $dbh->do($sql);
    }
    global_tracer_cmp_easy([{ operation_name => 'dbi_do' }], 'span appears when temprarily enabled twice');

    reset_spans();
    DBIx::OpenTracing->enable();
    {
        DBIx::OpenTracing->suspend();
        $run_all_actions->();

        DBIx::OpenTracing->enable();
        $run_all_actions->();
        DBIx::OpenTracing->disable();
        $run_all_actions->();

        { DBIx::OpenTracing->enable_temporarily();  $run_all_actions->(); }
        $run_all_actions->();
        { DBIx::OpenTracing->disable_temporarily(); $run_all_actions->(); }
        $run_all_actions->();
    }
    global_tracer_cmp_deeply([], 'nothing is traced when suspended');
    $dbh->do($sql);
    global_tracer_cmp_easy([{ operation_name => 'dbi_do' }], 'functionality back after suspend');

    return;
}

sub compatibility_ok {
    my ($dbh, $statements) = @_;
    my $sql_selectall = $statements->{select_all_multi};
    my $sql_selectrow = $statements->{select_all_single};
    my $sql_selectcol = $statements->{select_column_multi};
    my ($sql_bind, @bind_vals) = @{ $statements->{bind} };

    my @cases = (
        {
            method          => 'selectrow_array',
            args            => [$sql_selectrow],
            expected_list   => [2, 'other thing'],
        },
        {
            method          => 'selectrow_array',
            args            => [$sql_selectcol],
            expected_scalar => 'other thing',
            expected_list   => ['other thing'],
        },
        {
            method          => 'selectrow_arrayref',
            args            => [$sql_selectrow],
            expected_scalar => [2, 'other thing'],
            expected_list   => [[2, 'other thing']],
        },
        {
            method          => 'selectrow_hashref',
            args            => [$sql_selectrow],
            expected_scalar => { id => 2, description => 'other thing' },
            expected_list   => [ { id => 2, description => 'other thing' } ],
        },
        {
            method          => 'selectall_arrayref',
            args            => [$sql_selectall],
            expected_scalar => [ [ 1, 'some thing' ], [ 3, 'this is a thing' ] ],
            expected_list   => [ [ [ 1, 'some thing' ], [ 3, 'this is a thing' ] ] ],
        },
        {
            method          => 'selectall_arrayref',
            args            => [$sql_selectall, { Slice => {} }],
            expected_scalar => [
                { id => 1, description => 'some thing' },
                { id => 3, description => 'this is a thing' },
            ],
            expected_list => [[
                { id => 1, description => 'some thing' },
                { id => 3, description => 'this is a thing' },
            ]],
        },
        {
            method          => 'selectall_array',
            args            => [$sql_selectall],
            expected_scalar => 2,
            expected_list   => [ [ 1, 'some thing' ], [ 3, 'this is a thing' ] ],
        },
        {
            method          => 'selectall_hashref',
            args            => [ $sql_selectall, 'id' ],
            expected_scalar => {
                1 => { id => 1, description => 'some thing' },
                3 => { id => 3, description => 'this is a thing' }
            },
            expected_list => [{
                1 => { id => 1, description => 'some thing' },
                3 => { id => 3, description => 'this is a thing' }
            }],
        },
        {
            method          => 'selectcol_arrayref',
            args            => [$sql_selectcol],
            expected_scalar => ['other thing', 'this is a thing'],
            expected_list   => [['other thing', 'this is a thing']],
        },
        {
            method          => 'selectall_arrayref',
            args            => [ $sql_bind, { Slice => {} }, @bind_vals ],
            expected_scalar => [
                { id => 1, description => 'some thing' },
                { id => 3, description => 'this is a thing' },
            ],
            expected_list => [[
                { id => 1, description => 'some thing' },
                { id => 3, description => 'this is a thing' },
            ]],
        },
    );
    foreach (@cases) {
        my ($method, $args) = @$_{qw[ method args ]};

        if (exists $_->{expected_scalar}) {
            my $exp_scalar = $_->{expected_scalar};
            my $got_scalar = $dbh->$method(@$args);
            is_deeply $got_scalar, $exp_scalar,
                "$method return correctly in scalar context";
        }

        if (exists $_->{expected_list}) {
            my $exp_list = $_->{expected_list};
            my @got_list = $dbh->$method(@$args);
            is_deeply \@got_list, $exp_list,
                "$method returns correctly in list context";
        }
    }
}

sub tag_control_ok {  # SELECT id, description FROM things WHERE id IN (?, ?) -- bind: 1, 3
    my ($dbh, $statement, $tag_base) = @_;
    my ($sql, @bind) = @$statement;

    my $run_query = sub { $dbh->selectall_arrayref($sql, {}, @bind) };
    $tag_base->{'caller.subname'} = _sub_here('__ANON__');

    my $full = {
        tags => {
            %$tag_base,
            'db.statement'         => $sql,
            'db.statement_summary' => 'SELECT: things',
            'db.bind_values'       => '`1`,`3`',
            'db.rows'              => 2,
        },
    };
    my $no_sql = {
        tags => {
            %$tag_base,
            'db.statement_summary' => 'SELECT: things',
            'db.bind_values' => '`1`,`3`',
            'db.rows'        => 2,
        },
    };
    my $no_sql_no_bind = {
        tags => {
            %$tag_base,
            'db.statement_summary' => 'SELECT: things',
            'db.rows' => 2,
        },
    };

    reset_spans();
    $run_query->();
    global_tracer_cmp_easy([$full], 'bind values tag present');

    reset_spans();
    DBIx::OpenTracing->hide_tags(DB_TAG_SQL);
    $run_query->();
    global_tracer_cmp_easy([$no_sql], 'statement tag hidden');

    reset_spans();
    DBIx::OpenTracing->hide_tags(DB_TAG_BIND);
    $run_query->();
    global_tracer_cmp_easy([$no_sql_no_bind], 'bind values tag hidden');

    reset_spans();
    DBIx::OpenTracing->show_tags(DB_TAG_BIND);
    $run_query->();
    global_tracer_cmp_easy([$no_sql], 'bind values tag shown after hiding');

    reset_spans();
    DBIx::OpenTracing->show_tags(DB_TAG_BIND);
    $run_query->();
    global_tracer_cmp_easy([$no_sql], 'bind values tag set to shown twice');

    reset_spans();
    {
        DBIx::OpenTracing->hide_tags_temporarily(DB_TAG_BIND);
        $run_query->();
    }
    global_tracer_cmp_easy([$no_sql_no_bind], 'bind values temporarily hidden');
    $run_query->();
    global_tracer_cmp_easy([$no_sql], 'bind values back when out of scope');

    reset_spans();
    {
        DBIx::OpenTracing->show_tags_temporarily(DB_TAG_SQL);
        $run_query->();
    }
    global_tracer_cmp_easy([$full], 'sql statement back when shown temporarily');
    $run_query->();
    global_tracer_cmp_easy([$no_sql], 'sql statement hidden again when out of scope');

    reset_spans();
    DBIx::OpenTracing->show_tags(DB_TAG_SQL);
    {
        DBIx::OpenTracing->hide_tags_temporarily(DB_TAG_SQL);
        { DBIx::OpenTracing->hide_tags_temporarily(DB_TAG_SQL) }
        $run_query->();
    }
    global_tracer_cmp_easy([$no_sql], 'sql statement hidden when temporarily disabled twice');
    
    reset_spans();
    DBIx::OpenTracing->hide_tags(DB_TAG_SQL);
    {
        DBIx::OpenTracing->show_tags_temporarily(DB_TAG_SQL);
        { DBIx::OpenTracing->show_tags_temporarily(DB_TAG_SQL) }
        $run_query->();
    }
    global_tracer_cmp_easy([$full], 'sql statement shown when temprarily enabled twice');

    reset_spans();
    DBIx::OpenTracing->show_tags(DB_TAGS_ALL);
    {
        DBIx::OpenTracing->disable_tags(DB_TAG_SQL, DB_TAG_BIND);
        $run_query->();

        DBIx::OpenTracing->show_tags(DB_TAG_SQL);
        $run_query->();
        DBIx::OpenTracing->hide_tags(DB_TAG_SQL);
        $run_query->();
        DBIx::OpenTracing->show_tags(DB_TAG_SQL);
        $run_query->();

        { DBIx::OpenTracing->show_tags_temporarily(DB_TAG_SQL); $run_query->(); }
        $run_query->();
        { DBIx::OpenTracing->hide_tags_temporarily(DB_TAG_SQL); $run_query->(); }
        $run_query->();
    }
    global_tracer_cmp_deeply(
        [ (superhashof($no_sql_no_bind)) x 8 ],
        'disabled tags cannot be shown in any way'
    );

    reset_spans();
    $run_query->();
    global_tracer_cmp_easy([$full], 'tags back after disable is out of scope');

    return;
}

sub comments_ok {
    my ($dbh, $sql_sets) = @_;
    return if not $sql_sets;
    
    DBIx::OpenTracing->show_tags(DB_TAG_SQL);
    
    subtest 'comment removal' => sub {
        foreach (@$sql_sets) {
            reset_spans();

            my ($name, $original, $no_comments) = @$_;
            $dbh->do($original);
            
            global_tracer_cmp_easy([{
                tags => superhashof({ 'db.statement' ,=> $no_comments }),
            }], $name);
        }
    };
    return;
}

sub execute_ok {
    my ($dbh, $sql_clear, $sql_insert, $sql_select, $tag_base) = @_;
    $tag_base->{'caller.subname'} = _sub_here('execute_ok');

    reset_spans();

    $dbh->prepare($sql_clear)->execute();
    $dbh->prepare($sql_insert)->execute();
    $dbh->prepare($sql_select)->execute();

    global_tracer_cmp_easy([
        {
            operation_name => 'dbi_execute',
            tags           => {
                %$tag_base,
                'db.statement'         => $sql_clear,
                'db.statement_summary' => 'DELETE: things',
                'db.rows'              => ignore(),
            },
        },
        {
            operation_name => 'dbi_execute',
            tags           => {
                %$tag_base,
                'db.statement'         => $sql_insert,
                'db.statement_summary' => 'INSERT: things',
                'db.rows'              => 5
            },
        },
        {
            operation_name => 'dbi_execute',
            tags           => {
                %$tag_base,
                'db.statement'         => $sql_select,
                'db.statement_summary' => 'SELECT: things',
            },
        },
    ], 'execute produces correct tags');
}

1;
