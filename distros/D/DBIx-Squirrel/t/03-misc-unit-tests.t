use 5.010_001;
use strict;
use warnings;
use open ':std', ':encoding(utf8)';
use Test::More;
use Test::MockModule;
use Test::Exception;
use Test::Warnings qw/warning/;
use FindBin        qw/$Bin/;
use lib "$Bin/lib";

BEGIN {
    use_ok('DBIx::Squirrel',           database_entity => 'db')            || print "Bail out!\n";
    use_ok('T::Squirrel',              qw/:var diagdump/)                  || print "Bail out!\n";
    use_ok('DBIx::Squirrel::Iterator', qw/result result_transform/)        || print "Bail out!\n";
    use_ok('DBIx::Squirrel::st',       qw/statement_trim statement_study/) || print "Bail out!\n";
    use_ok('DBIx::Squirrel::Utils',    qw/args_partition throw whine/)     || print "Bail out!\n";
}

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");

{
    no strict qw/subs/;    ## no critic

    note('DBIx::Squirrel::Utils::whine');

    my @tests = (
        {   line => __LINE__,
            got  => sub {whine},
            exp  => qr/Unhelpful warning issued/,
            name => 'no arguments',
        },
        {   line => __LINE__,
            got  => sub {whine ''},
            exp  => qr/Unhelpful warning issued/,
            name => 'an empty string',
        },
        {   line => __LINE__,
            got  => sub {whine 'Foo warning'},
            exp  => qr/Foo warning/,
            name => 'a string',
        },
        {   line => __LINE__,
            got  => sub {whine 'Foo warning (%d)', 99},
            exp  => qr/Foo warning \(99\)/,
            name => 'a format string with parameter(s)',
        },
    );

    foreach my $t (@tests) {
        like(warning {$t->{got}->()}, $t->{exp}, sprintf('line %d%s', $t->{line}, $t->{name} ? " - $t->{name}" : ''));
    }
}

##############

{
    no strict qw/subs/;    ## no critic

    note('DBIx::Squirrel::Utils::throw');

    my @tests = (
        {   line => __LINE__,
            got  => sub {throw},
            exp  => qr/Unknown exception thrown/,
            name => 'no arguments and $@ is not set',
        },
        {   line => __LINE__,
            got  => sub {
                eval {die 'Oh no, the foo!'};
                throw;
            },
            exp  => qr/Oh no, the foo!/,
            name => 'no arguments and $@ is set',
        },
        {   line => __LINE__,
            got  => sub {throw ''},
            exp  => qr/Unknown exception thrown/,
            name => 'an empty string and $@ is not set',
        },
        {   line => __LINE__,
            got  => sub {
                eval {die 'Oh no, the foo!'};
                throw '';
            },
            exp  => qr/Oh no, the foo!/,
            name => 'an empty string and $@ is set',
        },
        {   line => __LINE__,
            got  => sub {throw 'Foo thrown'},
            exp  => qr/Foo thrown/,
            name => 'a string',
        },
        {   line => __LINE__,
            got  => sub {throw 'Foo thrown (%d)', 99},
            exp  => qr/Foo thrown \(99\)/,
            name => 'a format string with parameter(s)',
        },
        {   line => __LINE__,
            got  => sub {throw bless({}, 'AnExceptionObject')},
            exp  => qr/AnExceptionObject=/,
            name => 'an exception object',
        },
    );

    foreach my $t (@tests) {
        throws_ok {$t->{got}->()} $t->{exp}, sprintf('line %d%s', $t->{line}, $t->{name} ? " - $t->{name}" : '');
    }
}

##############

{
    my $sub1 = sub {'DUMMY 1'};
    my $sub2 = sub {'DUMMY 2'};
    my $sub3 = sub {'DUMMY 3'};

    note('DBIx::Squirrel::Utils::args_partition');

    my @tests = (
        {line => __LINE__, got => [args_partition()],                               exp => [[]]},
        {line => __LINE__, got => [args_partition(1)],                              exp => [[], 1]},
        {line => __LINE__, got => [args_partition(1, 2)],                           exp => [[], 1, 2]},
        {line => __LINE__, got => [args_partition(1, 2, 3)],                        exp => [[], 1, 2, 3]},
        {line => __LINE__, got => [args_partition($sub1)],                          exp => [[$sub1]]},
        {line => __LINE__, got => [args_partition($sub1, $sub2)],                   exp => [[$sub1, $sub2]]},
        {line => __LINE__, got => [args_partition($sub1, $sub2, $sub3)],            exp => [[$sub1, $sub2, $sub3]]},
        {line => __LINE__, got => [args_partition(1 => $sub1)],                     exp => [[$sub1], 1]},
        {line => __LINE__, got => [args_partition(1, 2 => $sub1)],                  exp => [[$sub1], 1, 2]},
        {line => __LINE__, got => [args_partition(1, 2, 3 => $sub1)],               exp => [[$sub1], 1, 2, 3]},
        {line => __LINE__, got => [args_partition(1, 2, 3 => $sub1, $sub2, $sub3)], exp => [[$sub1, $sub2, $sub3], 1, 2, 3]},
        {line => __LINE__, got => [args_partition(1, $sub1, 3 => $sub2, $sub3)],    exp => [[$sub2, $sub3], 1, $sub1, 3]},
    );

    foreach my $t (@tests) {
        is_deeply($t->{got}, $t->{exp}, sprintf('line %d', $t->{line}));
    }
}

##############

{
    note('DBIx::Squirrel::st::statement_trim');

    my @tests = (
        {line => __LINE__, got => [statement_trim()],                           exp => [""]},
        {line => __LINE__, got => [statement_trim(undef)],                      exp => [""]},
        {line => __LINE__, got => [statement_trim("")],                         exp => [""]},
        {line => __LINE__, got => [statement_trim("SELECT 1")],                 exp => ["SELECT 1"]},
        {line => __LINE__, got => [statement_trim("SELECT 1  -- COMMENT")],     exp => ["SELECT 1"]},
        {line => __LINE__, got => [statement_trim("SELECT 1\n-- COMMENT")],     exp => ["SELECT 1"]},
        {line => __LINE__, got => [statement_trim("  SELECT 1\n-- COMMENT  ")], exp => ["SELECT 1"]},
        {line => __LINE__, got => [statement_trim("\tSELECT 1\n-- COMMENT  ")], exp => ["SELECT 1"]},
    );

    foreach my $t (@tests) {
        is_deeply($t->{got}, $t->{exp}, sprintf('line %2d', $t->{line}));
    }
}

##############

{
    note('DBIx::Squirrel::st::statement_study');

    throws_ok {statement_study(bless({}, 'NotAStatementHandle'))} qr/Expected a statement handle/, 'got expected exception';

    my $db1              = DBIx::Squirrel->connect(@MOCK_DB_CONNECT_ARGS);
    my $st1              = $db1->prepare('SELECT :foo, :bar');
    my $db2              = DBI->connect(@MOCK_DB_CONNECT_ARGS);
    my $st2              = $db2->prepare('SELECT ?, ?');
    my $dbix_squirrel_st = Test::MockModule->new('DBIx::Squirrel::st');
    $dbix_squirrel_st->mock(statement_digest => 'DETERMINISTIC');    # in case we use algo that isn't!

    my @tests = (
        {line => __LINE__, got => [statement_study('')],         exp => []},
        {line => __LINE__, got => [statement_study('SELECT 1')], exp => [{}, 'SELECT 1', 'SELECT 1', 'DETERMINISTIC']},
        {line => __LINE__, got => [statement_study('SELECT ?')], exp => [{}, 'SELECT ?', 'SELECT ?', 'DETERMINISTIC']},
        {   line => __LINE__,
            got  => [statement_study('SELECT ?1')],
            exp  => [{1 => '?1'}, 'SELECT ?', 'SELECT ?1', 'DETERMINISTIC'],
        },
        {   line => __LINE__,
            got  => [statement_study('SELECT :1')],
            exp  => [{1 => ':1'}, 'SELECT ?', 'SELECT :1', 'DETERMINISTIC'],
        },
        {   line => __LINE__,
            got  => [statement_study('SELECT $1')],
            exp  => [{1 => '$1'}, 'SELECT ?', 'SELECT $1', 'DETERMINISTIC'],
        },
        {   line => __LINE__,
            got  => [statement_study('SELECT :foo')],
            exp  => [{1 => ':foo'}, 'SELECT ?', 'SELECT :foo', 'DETERMINISTIC'],
        },
        {line => __LINE__, got => [statement_study('SELECT ?, ?')], exp => [{}, 'SELECT ?, ?', 'SELECT ?, ?', 'DETERMINISTIC']},
        {   line => __LINE__,
            got  => [statement_study('SELECT ?1, ?2')],
            exp  => [{1 => '?1', 2 => '?2'}, 'SELECT ?, ?', 'SELECT ?1, ?2', 'DETERMINISTIC'],
        },
        {   line => __LINE__,
            got  => [statement_study('SELECT :1, :2')],
            exp  => [{1 => ':1', 2 => ':2'}, 'SELECT ?, ?', 'SELECT :1, :2', 'DETERMINISTIC'],
        },
        {   line => __LINE__,
            got  => [statement_study('SELECT $1, $2')],
            exp  => [{1 => '$1', 2 => '$2'}, 'SELECT ?, ?', 'SELECT $1, $2', 'DETERMINISTIC'],
        },
        {   line => __LINE__,
            got  => [statement_study('SELECT :foo, :bar')],
            exp  => [{1 => ':foo', 2 => ':bar'}, 'SELECT ?, ?', 'SELECT :foo, :bar', 'DETERMINISTIC'],
        },
        {   line => __LINE__,
            got  => [statement_study($st1)],
            exp  => [{1 => ':foo', 2 => ':bar'}, 'SELECT ?, ?', 'SELECT :foo, :bar', 'DETERMINISTIC'],
        },
        {   line => __LINE__,
            got  => [statement_study($st2)],
            exp  => [{}, 'SELECT ?, ?', 'SELECT ?, ?', 'DETERMINISTIC'],
        },
    );

    foreach my $t (@tests) {
        is_deeply($t->{got}, $t->{exp}, sprintf('line %d', $t->{line}));
    }

    $db2->disconnect;
    $db1->disconnect;
}

##############

{
    no strict qw/subs/;    ## no critic

    note('DBIx::Squirrel::Iterator::result_transform');

    my @tests = (
        {line => __LINE__, got => sub {result_transform()},              exp => []},
        {line => __LINE__, got => sub {result_transform(4)},             exp => [4]},
        {line => __LINE__, got => sub {scalar(result_transform(4))},     exp => [1]},
        {line => __LINE__, got => sub {scalar(result_transform(4)); $_}, exp => [4]},
        {   line => __LINE__,
            got  => sub {
                result_transform([sub {2 * $_[0]}], 2);
            },
            exp => [4],
        },
        {   line => __LINE__,
            got  => sub {
                result_transform([sub {2 * $_[0]} => sub {2 * $_[0]}], 2);
            },
            exp => [8],
        },
        {   line => __LINE__,
            got  => sub {
                result_transform([sub {4 * $_}], 4);
            },
            exp => [16],
        },
        {   line => __LINE__,
            got  => sub {
                result_transform([sub {4 * $_} => sub {4 * $_}], 4);
            },
            exp => [64],
        },
    );

    foreach my $t (@tests) {
        my $got = [$t->{got}->()];
        is_deeply($got, $t->{exp}, sprintf('line %2d', $t->{line}));
    }
}

##############

{
    no strict qw/subs/;    ## no critic

    note('DBIx::Squirrel::Iterator::ResultClass');

    my @tests = (
        {   line => __LINE__,
            got  => sub {
                result_transform([sub {3 * result}], 4);
            },
            exp => [12],
        },
        {   line => __LINE__,
            got  => sub {
                result_transform([sub {3 * result} => sub {3 * result}], 4);
            },
            exp => [36],
        },
    );

    foreach my $t (@tests) {
        my $got = [$t->{got}->()];
        is_deeply($got, $t->{exp}, sprintf('line %2d', $t->{line}));
    }
}

done_testing();
