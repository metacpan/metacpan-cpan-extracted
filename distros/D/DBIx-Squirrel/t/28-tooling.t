use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# DBIx::Squirrel::Tooling: every name a caller uses to do work, from one
# module, by Ekorn::Pipeline::Tooling's tags and DBIx::Squirrel's own,
# and DBIx::Squirrel's version of any name both export (roadmap
# 2026-0025).

use DBIx::Squirrel;
use DBIx::Squirrel::Tooling  ();
use Ekorn::Pipeline::Tooling ();

my $tooling = 'DBIx::Squirrel::Tooling';
my $ekorn   = 'Ekorn::Pipeline::Tooling';

# Each tag that follows a module, and the module: DBIx::Squirrel's where
# it has one.
my %module = (
    core    => [qw(DBIx::Squirrel::Stop DBIx::Squirrel::Gather)],
    flow    => ['DBIx::Squirrel::Stages::Flow'],
    batch   => ['DBIx::Squirrel::Stages::Batch'],
    taps    => ['DBIx::Squirrel::Stages::Taps'],
    rows    => ['DBIx::Squirrel::Stages::Rows'],
    context => ['DBIx::Squirrel::Context'],
    sources => ['Ekorn::Pipeline::Sources'],
    sinks   => ['Ekorn::Pipeline::Sinks'],
    json    => ['Ekorn::Pipeline::JSON'],
    words   => ['Ekorn::Pipeline::Factories'],
);


# The names a module exports, by default or on request, sorted.
sub exported_by ($module) {
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    my %names = map { $_ => 1 } @{ "${module}::EXPORT" },
        @{ "${module}::EXPORT_OK" };
    my @sorted = sort keys %names;
    return @sorted;
}


# The names a Tooling's tag holds, sorted.
sub tag ($name, $of = $tooling) {
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    return [sort @{ ${ "${of}::EXPORT_TAGS" }{$name} }];
}

subtest 'each tag holds every name its modules export' => sub {
    for my $tag (sort keys %module) {
        is tag($tag), [sort map { exported_by($_) } @{ $module{$tag} }], ":$tag";
    }
};

subtest ':stages is :flow, :batch, :taps and :rows' => sub {
    is tag('stages'), [sort map { @{ tag($_) } } qw(flow batch taps rows)];
};

subtest ':all is every tag, each name once' => sub {
    my %every = map { $_ => 1 } map { @{ tag($_) } } keys %module;
    is tag('all'), [sort keys %every];
    is [exported_by($tooling)], [sort keys %every], 'and is what it exports';
};

subtest "Ekorn's tags, by the same names, with the same words" => sub {
    no warnings 'once';
    for my $tag (sort keys %Ekorn::Pipeline::Tooling::EXPORT_TAGS) {
        my %ours = map { $_ => 1 } @{ tag($tag) };
        is [grep { !$ours{$_} } @{ tag($tag, $ekorn) }], [],
            ":$tag holds every name Ekorn's does";
    }
};

subtest 'not for callers: is_stage, is_sink, croakf, the operators' => sub {
    my %all = map { $_ => 1 } @{ tag('all') };
    ok !$all{$_}, "no $_" for qw(is_stage is_sink croakf chain drain);
};

subtest 'nothing by default' => sub {

    package Tooling::Nothing {
        use DBIx::Squirrel::Tooling;
    }
    ok !Tooling::Nothing->can($_), "no $_" for @{ tag('all') };
};

subtest "each name is its own module's sub, DBIx::Squirrel's first" => sub {
    for my $tag (sort keys %module) {
        for my $module (@{ $module{$tag} }) {
            for my $name (exported_by($module)) {
                ref_is $tooling->can($name), $module->can($name), "$name, from $module";
            }
        }
    }
    ref_is $tooling->can('gather'), DBIx::Squirrel::Gather->can('gather'),
        "gather, Factories' word too, is DBIx::Squirrel::Gather's";
};

subtest 'each name both export is one sub' => sub {
    my %ours = map  { $_ => 1 } @{ tag('all') };
    my @both = grep { $ours{$_} } @{ tag('all', $ekorn) };
    is scalar(@both), scalar @{ tag('all', $ekorn) },
        "every name Ekorn's exports, ours does";
    ref_is $tooling->can($_), $ekorn->can($_), $_ for @both;
};

subtest 'both imported into one package, either order' => sub {
    my $warnings = warnings {
        eval <<~'PERL' or die $@;
            package Tooling::OursLast;
            use Ekorn::Pipeline::Tooling qw(:all);
            use DBIx::Squirrel::Tooling  qw(:all);
            package Tooling::OursFirst;
            use DBIx::Squirrel::Tooling  qw(:all);
            use Ekorn::Pipeline::Tooling qw(:all);
            1;
            PERL
    };
    is $warnings, [], 'warning of nothing';
    for my $package (qw(Tooling::OursLast Tooling::OursFirst)) {
        my @differ
            = grep { $package->can($_) != $tooling->can($_) } @{ tag('all') };
        is \@differ, [], "$package has DBIx::Squirrel's subs";
    }
};

my $dbh = DBIx::Squirrel->connect(
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);
$dbh->do(
    'CREATE TABLE track (id INTEGER PRIMARY KEY, name TEXT, plays INTEGER)');
$dbh->do('INSERT INTO track (name, plays) VALUES (?, ?)', @$_)
    for [Waterloo => 9000], [Parklife => 7000], [Badge => 5000],
    [Sunrise => 100];
my $sql = 'SELECT id, name, plays FROM track ORDER BY id';

subtest 'a tag imports its names, prototypes and all, on a statement' => sub {

    package Tooling::Some {
        use DBIx::Squirrel::Tooling qw(:stages :sinks);


        sub hits ($dbh, $sql) {
            return $dbh->iterate(
                $sql, take_if { $_->[2] > 6000 }, pluck('name'),
                keep_all,
            );
        }
    }
    is [Tooling::Some::hits($dbh, $sql)], [qw(Waterloo Parklife)];
    ok !Tooling::Some->can('from_file'), 'and only those';
};

subtest 'names can be asked for one by one' => sub {

    package Tooling::Named {
        use DBIx::Squirrel::Tooling qw(as_hash stage keep_first);


        sub loud ($dbh, $sql) {
            return $dbh->iterate($sql, as_hash, stage { uc $_->{name} }, keep_first);
        }
    }
    is Tooling::Named::loud($dbh, $sql), 'WATERLOO';
};

subtest ':all, its parts working together on a statement' => sub {

    package Tooling::All {
        use DBIx::Squirrel::Tooling qw(:all);


        sub numbered ($dbh, $sql) {
            return $dbh->iterate(
                $sql,
                drop_if { $_->[2] < 1000 },
                stage { result_number() . ' ' . result_original()->[1] },
                keep_all,
            );
        }


        sub until_badge ($dbh, $sql) {
            return $dbh->iterate(
                $sql,                                  pluck('name'),
                stage { Stop() if $_ eq 'Badge'; $_ }, count_items,
            );
        }


        sub pairs ($dbh, $sql) {
            return $dbh->iterate($sql, pluck('id'), batch(2), count_items);
        }
    }
    is [Tooling::All::numbered($dbh, $sql)],
        ['1 Waterloo', '2 Parklife', '3 Badge'],
        'stages, the context and a sink';
    is Tooling::All::until_badge($dbh, $sql), 2, 'Stop';
    is Tooling::All::pairs($dbh, $sql),       2, 'batch';
};

subtest ':json, rows as JSON Lines and back' => sub {

    package Tooling::Json {
        use DBIx::Squirrel::Tooling qw(:json :rows :sinks);


        sub lines ($dbh, $sql) {
            return $dbh->iterate(
                $sql, as_hash, to_jsonl(json => {canonical => 1}),
                keep_all,
            );
        }
    }
    my @lines = Tooling::Json::lines(
        $dbh,
        'SELECT id, name FROM track WHERE id < 3 ORDER BY id',
    );
    is \@lines, ['{"id":1,"name":"Waterloo"}', '{"id":2,"name":"Parklife"}'];
    is [Ekorn::Pipeline->new(Tooling::Json::from_jsonl())->(@lines)],
        [{id => 1, name => 'Waterloo'}, {id => 2, name => 'Parklife'}],
        'from_jsonl undoes it';
};

subtest "| isn't in force, though Operators is loaded" => sub {

    package Tooling::NoOperators {
        use DBIx::Squirrel::Tooling qw(:all);

        sub chained ($dbh, $sql) { return $dbh->iterate($sql) | count_items }
    }
    require Ekorn::Pipeline::Operators;
    like dies { Tooling::NoOperators::chained($dbh, $sql) },
        qr( \A Expected\ use\ Ekorn::Pipeline::Operators\ in\ scope )x;
};

subtest 'an unknown tag is reported by Exporter' => sub {
    my $died;
    my $warnings = warnings {
        $died = dies { DBIx::Squirrel::Tooling->import(':nonesuch') }
    };
    like $warnings, [qr( "nonesuch"\ is\ not\ defined )x],
        'it warns of the tag';
    like $died, qr( \A Can't\ continue\ after\ import\ errors )x, 'and dies';
};

done_testing;
