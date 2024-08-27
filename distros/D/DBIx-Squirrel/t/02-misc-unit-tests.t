use 5.010_001;
use strict;
use warnings;
use open ':std', ':encoding(utf8)';
use Test::More;
use Test::MockModule;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

BEGIN {
    use_ok('DBIx::Squirrel')            || print "Bail out!\n";
    use_ok('T::Squirrel', qw/diagdump/) || print "Bail out!\n";
    use_ok(
        'DBIx::Squirrel::util', qw/
          args_partition
          sql_trim
          statement_study
          transform
          result
          /,
    ) || print "Bail out!\n";
}

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");

{
    my $sub1 = sub {'DUMMY 1'};
    my $sub2 = sub {'DUMMY 2'};
    my $sub3 = sub {'DUMMY 3'};

    note('DBIx::Squirrel::util::args_partition');

    my @tests = (
        {lno => __LINE__, got => [args_partition()],                               exp => [[]]},
        {lno => __LINE__, got => [args_partition(1)],                              exp => [[], 1]},
        {lno => __LINE__, got => [args_partition(1, 2)],                           exp => [[], 1, 2]},
        {lno => __LINE__, got => [args_partition(1, 2, 3)],                        exp => [[], 1, 2, 3]},
        {lno => __LINE__, got => [args_partition($sub1)],                          exp => [[$sub1]]},
        {lno => __LINE__, got => [args_partition($sub1, $sub2)],                   exp => [[$sub1, $sub2]]},
        {lno => __LINE__, got => [args_partition($sub1, $sub2, $sub3)],            exp => [[$sub1, $sub2, $sub3]]},
        {lno => __LINE__, got => [args_partition(1 => $sub1)],                     exp => [[$sub1], 1]},
        {lno => __LINE__, got => [args_partition(1, 2 => $sub1)],                  exp => [[$sub1], 1, 2]},
        {lno => __LINE__, got => [args_partition(1, 2, 3 => $sub1)],               exp => [[$sub1], 1, 2, 3]},
        {lno => __LINE__, got => [args_partition(1, 2, 3 => $sub1, $sub2, $sub3)], exp => [[$sub1, $sub2, $sub3], 1, 2, 3]},
        {lno => __LINE__, got => [args_partition(1, $sub1, 3 => $sub2, $sub3)],    exp => [[$sub2, $sub3], 1, $sub1, 3]},
    );

    foreach my $test (@tests) {
        is_deeply($test->{got}, $test->{exp}, sprintf('line %d', $test->{lno}));
    }
}

##############

{
    note('DBIx::Squirrel::util::sql_trim');

    my @tests = (
        {lno => __LINE__, got => [sql_trim()],                           exp => [""]},
        {lno => __LINE__, got => [sql_trim(undef)],                      exp => [""]},
        {lno => __LINE__, got => [sql_trim("")],                         exp => [""]},
        {lno => __LINE__, got => [sql_trim("SELECT 1")],                 exp => ["SELECT 1"]},
        {lno => __LINE__, got => [sql_trim("SELECT 1  -- COMMENT")],     exp => ["SELECT 1"]},
        {lno => __LINE__, got => [sql_trim("SELECT 1\n-- COMMENT")],     exp => ["SELECT 1"]},
        {lno => __LINE__, got => [sql_trim("  SELECT 1\n-- COMMENT  ")], exp => ["SELECT 1"]},
        {lno => __LINE__, got => [sql_trim("\tSELECT 1\n-- COMMENT  ")], exp => ["SELECT 1"]},
    );

    foreach my $test (@tests) {
        is_deeply($test->{got}, $test->{exp}, sprintf('line %2d', $test->{lno}));
    }
}

##############

{
    note('DBIx::Squirrel::util::statement_study');

    my $dbix_squirrel_util = Test::MockModule->new('DBIx::Squirrel::util');
    $dbix_squirrel_util->mock(sql_digest => 'DETERMINISTIC');

    my @tests = (
        {lno => __LINE__, got => [statement_study('SELECT 1')], exp => [{}, 'SELECT 1', 'SELECT 1', 'DETERMINISTIC']},
        {lno => __LINE__, got => [statement_study('SELECT ?')], exp => [{}, 'SELECT ?', 'SELECT ?', 'DETERMINISTIC']},
        {   lno => __LINE__,
            got => [statement_study('SELECT ?1')],
            exp => [{1 => '?1'}, 'SELECT ?', 'SELECT ?1', 'DETERMINISTIC'],
        },
        {   lno => __LINE__,
            got => [statement_study('SELECT :1')],
            exp => [{1 => ':1'}, 'SELECT ?', 'SELECT :1', 'DETERMINISTIC'],
        },
        {   lno => __LINE__,
            got => [statement_study('SELECT :foo')],
            exp => [{1 => ':foo'}, 'SELECT ?', 'SELECT :foo', 'DETERMINISTIC'],
        },
        {lno => __LINE__, got => [statement_study('SELECT ?, ?')], exp => [{}, 'SELECT ?, ?', 'SELECT ?, ?', 'DETERMINISTIC']},
        {   lno => __LINE__,
            got => [statement_study('SELECT ?1, ?2')],
            exp => [{1 => '?1', 2 => '?2'}, 'SELECT ?, ?', 'SELECT ?1, ?2', 'DETERMINISTIC'],
        },
        {   lno => __LINE__,
            got => [statement_study('SELECT :1, :2')],
            exp => [{1 => ':1', 2 => ':2'}, 'SELECT ?, ?', 'SELECT :1, :2', 'DETERMINISTIC'],
        },
        {   lno => __LINE__,
            got => [statement_study('SELECT :foo, :bar')],
            exp => [{1 => ':foo', 2 => ':bar'}, 'SELECT ?, ?', 'SELECT :foo, :bar', 'DETERMINISTIC'],
        },
    );

    foreach my $test (@tests) {
        is_deeply($test->{got}, $test->{exp}, sprintf('line %d', $test->{lno}));
    }
}

##############

{
    no strict qw/subs/;    ## no critic

    note('DBIx::Squirrel::util::transform');

    my @tests = (
        {lno => __LINE__, got => sub {transform()},              exp => []},
        {lno => __LINE__, got => sub {transform(4)},             exp => [4]},
        {lno => __LINE__, got => sub {scalar(transform(4))},     exp => [1]},
        {lno => __LINE__, got => sub {scalar(transform(4)); $_}, exp => [4]},
        {   lno => __LINE__,
            got => sub {
                transform([sub {2 * $_[0]}], 2);
            },
            exp => [4],
        },
        {   lno => __LINE__,
            got => sub {
                transform([sub {2 * $_[0]} => sub {2 * $_[0]}], 2);
            },
            exp => [8],
        },
        {   lno => __LINE__,
            got => sub {
                transform([sub {3 * result}], 4);
            },
            exp => [12],
        },
        {   lno => __LINE__,
            got => sub {
                transform([sub {3 * result} => sub {3 * result}], 4);
            },
            exp => [36],
        },
        {   lno => __LINE__,
            got => sub {
                transform([sub {4 * $_}], 4);
            },
            exp => [16],
        },
        {   lno => __LINE__,
            got => sub {
                transform([sub {4 * $_} => sub {4 * $_}], 4);
            },
            exp => [64],
        },
    );

    foreach my $test (@tests) {
        my $got = [$test->{got}->()];
        is_deeply($got, $test->{exp}, sprintf('line %2d', $test->{lno}));
    }
}

done_testing();
