package DuckDBTest;

use strict;
use warnings;
use v5.10;

use Test::More ();

use Exporter 'import';
use DBI ();
use Carp;

our @EXPORT = qw(connect_ok run_sqllogictest);

my $parent;
my %dbfiles;

BEGIN {
    $parent = $$;
}

sub dbfile { $dbfiles{$_[0]} ||= (defined $_[0] && length $_[0] && $_[0] ne ':memory:') ? $_[0] . $$ : $_[0] }

sub connect_ok {

    my $attr   = {@_};
    my $dbfile = dbfile(defined $attr->{dbfile} ? delete $attr->{dbfile} : ':memory:');
    my @params = ("dbi:DuckDB:dbname=$dbfile", '', '');

    if (%$attr) {
        push @params, $attr;
    }

    my $dbh = DBI->connect(@params);

    $dbh->{RaiseError}         = 0;
    $dbh->{PrintError}         = 0;
    $dbh->{ShowErrorStatement} = 0;

    Test::More::isa_ok($dbh, 'DBI::db');
    return $dbh;

}

sub clean {

    return if $$ != $parent;

    for my $dbfile (values %dbfiles) {

        next           if $dbfile eq ':memory:';
        unlink $dbfile if -f $dbfile;

        my $wal = $dbfile . '.wal';
        unlink $wal if -f $wal;

    }

}

# Implement simple Sqllogictest
# https://www.sqlite.org/sqllogictest/doc/trunk/about.wiki

sub run_sqllogictest {

    my ($fh, $dbh) = @_;

    my $content = do { local $/; <$fh> };
    close $fh;

    my @tests = map { s/^\s+|\s+$//g; $_ } grep { $_ !~ /^$/ } split /^$/m, $content;

    my $test_id          = 1;
    my $test_description = undef;

    foreach my $test (@tests) {

        my @lines    = split /\n/, $test;
        my @comments = ($test =~ /(^#)/gm);

        if (scalar(@lines) == scalar(@comments)) {
            $test =~ s/^#\s//gm;
            $test_description = $test;
            next;
        }

        my $test_name = "SQLLogicTest #$test_id";

        if ($test_description) {
            $test_name .= " ($test_description)";
        }

        Test::More::subtest $test_name => sub {

            my (@expected, $mode, $sql, $output, $types, $sort_mode, $label);

            foreach my $line (split /\n/, $test) {

                if ($line =~ /^#/) {
                    next;
                }
                elsif ($line =~ /^statement\s+(ok|error)\s*$/) {
                    $mode = "statement:$1";
                }
                elsif ($line =~ /^query/) {
                    ($mode, $types, $sort_mode, $label) = split(/ /, $line);
                }
                elsif ($line =~ /^----\s*$/) {
                    $output = 1;
                    next;
                }
                else {
                    if (defined $mode) {
                        if ($mode =~ /^statement:/) {
                            $sql .= "$line\n";
                        }
                        if ($mode eq 'query' && !$output) {
                            $sql .= "$line\n";
                        }
                        if ($output) {
                            my @data = map { $_ eq 'TRUE' ? !!1 : $_ eq 'FALSE' ? !!0 : $_ eq 'NULL' ? undef : $_ }
                                split /\t/, $line;

                            push @expected, [@data];
                        }
                    }
                }

            }

            Test::More::diag $label if $label;
            Test::More::diag "SQL: $sql";

            if ($mode =~ /^statement:(ok|error)/) {

                my $expect_error = $1 eq 'error';
                my $expect_ok    = $1 eq 'ok';

                my $res = eval { $dbh->do($sql) };

                Test::More::diag "ERROR: " . $dbh->errstr if $dbh->errstr;

                if ($expect_ok) {
                    Test::More::ok !$dbh->errstr, 'Expected ok';
                }

                if ($expect_error) {
                    Test::More::ok $dbh->errstr, 'Expected error';
                }

                if ($expect_ok && $dbh->errstr) {
                    Test::More::fail 'Unexpected error';
                }

            }

            if ($mode eq 'query') {

                my $sth = $dbh->prepare($sql);
                $sth->execute;

                my $rows = $sth->fetchall_arrayref;

                my $expected_rows = scalar(@expected);
                my $expected_cols = scalar(split //, $types || '');

                Test::More::is $sth->rows,            $expected_rows, "Expected rows";
                Test::More::is scalar(@{$rows->[0]}), $expected_cols, "Expected columns";

                if (@expected) {
                    Test::More::is_deeply $rows, \@expected, 'Expected output';
                }

            }

        };

        $test_id++;
        $test_description = undef;

    }

    return 1;

}

BEGIN { clean() }
END   { clean() }

1;
