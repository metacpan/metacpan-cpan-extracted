package DuckDBTest;

use strict;
use warnings;
use v5.10;

use Test::More ();

use Exporter 'import';
use DBI ();
use Carp;
use Digest::MD5;
use JSON::PP qw(decode_json);

use DBD::DuckDB::FFI qw(duckdb_library_version);


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

    my ($fh, $dbh, $options) = @_;

    $options //= {hash_threshold => 8};

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

            my (@expected, $mode, $sql, $output, $types, $sort_mode, $label, $hash_mode, $onlyif);

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
                elsif ($line =~ /^onlyif\s+(.*)$/) {
                    $onlyif = $1;
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
                            if ($line =~ /(\d+) values hashing to ([a-f\d]{32}|[A-F\d]{32})/) {
                                push @expected, [$line, $1, $2];
                                $hash_mode = 1;
                            }
                            else {
                                my @data = map {
                                          $_ eq 'TRUE'                 ? !!1
                                        : $_ eq 'FALSE'                ? !!0
                                        : $_ eq 'NULL'                 ? undef
                                        : substr($_, 0, 1) =~ /({|\[)/ ? decode_json($_)    # Detect JSON data
                                        : $_
                                } split /\t/, $line;

                                push @expected, [@data];
                            }
                        }
                    }
                }

            }

            Test::More::diag $label if $label;
            Test::More::diag "SQL: $sql";

            if ($onlyif) {

                my $skip = 0;

                if ($onlyif =~ /([=<>]+)/) {

                    my ($token, $op, $value) = $onlyif =~ /(\w+)([=<>]+)(.*)$/;
                    Test::More::diag "ONLYIF $token $op $value";

                    for ($token) {
                        if (/version/) {

                            my $version = duckdb_library_version;
                            $version =~ s/v//;

                            Test::More::diag "VERSION=$version";

                            if ($op eq '>=') {
                                $skip = 1 unless (version->parse($version) >= version->parse($value));
                            }
                            if ($op eq '<=') {
                                $skip = 1 unless (version->parse($version) <= version->parse($value));
                            }
                            if ($op eq '>') {
                                $skip = 1 unless (version->parse($version) > version->parse($value));
                            }
                            if ($op eq '<') {
                                $skip = 1 unless (version->parse($version) < version->parse($value));
                            }

                        }
                    }
                }

                if ($skip) {
                    Test::More::pass "SKIP";
                    goto END_SQLLOGICTEST;
                }

            }

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

                Test::More::diag(Test::More::explain($rows));

                if ($hash_mode) {

                    my ($expected_result, $expected_n_values, $expected_digest) = @{$expected[0]};

                    my $n_values = $sth->rows * scalar(@{$rows->[0]});
                    Test::More::is $n_values, $expected_n_values, "Expected $expected_n_values values";

                    Test::More::diag('Option: Hash Threshold: ', $options->{hash_threshold});

                    if ($options->{hash_threshold} > 0 && $n_values > $options->{hash_threshold}) {

                        my $md5 = Digest::MD5->new;

                    DIGEST: foreach my $row (@{$rows}) {
                            foreach my $value (@{$row}) {
                                $md5->add("$value\n");
                            }
                        }

                        my $digest = $md5->hexdigest;

                        Test::More::is $digest, $expected_digest, "Expected hash $expected_digest";
                        Test::More::is sprintf('%s values hashing to %s', $n_values, $digest), $expected_result,
                            $expected_result;

                    }
                }
                else {
                    Test::More::is $sth->rows,            $expected_rows, "Expected $expected_rows rows";
                    Test::More::is scalar(@{$rows->[0]}), $expected_cols, "Expected $expected_cols columns";

                    if (@expected) {
                        Test::More::is_deeply $rows, \@expected, 'Expected output';
                    }
                }
            }

        END_SQLLOGICTEST: {
                $test_id++;
                $test_description = undef;
            }

        };

    }

    return 1;

}

BEGIN { clean() }
END   { clean() }

1;
