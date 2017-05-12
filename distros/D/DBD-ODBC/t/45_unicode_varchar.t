#!/usr/bin/perl -w -I./t
#
# Test insertion into varchar columns using unicode and codepage chrs
# Must be a unicode build of DBD::ODBC
# Currently needs MS SQL Server
#
use open ':std', ':encoding(utf8)';
use Test::More;
use strict;
use Data::Dumper;

$| = 1;

use DBI qw(:utils);
use DBI::Const::GetInfoType;
my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;

my $dbh;

BEGIN {
	if ($] < 5.008001) {
		plan skip_all => "Old Perl lacking unicode support";
	} elsif (!defined $ENV{DBI_DSN}) {
             plan skip_all => "DBI_DSN is undefined";
      }
}

END {
    # tidy up
    if ($dbh) {
        local $dbh->{PrintError} = 0;
        local $dbh->{PrintWarn} = 0;
        eval {
            $dbh->do(q/drop table PERL_DBD_TABLE1/);
        };
    }
}

# get the server, database and table collations
sub collations {
    my ($h, $table) = @_;

    # so we can use :: not meaning placeholders
    $h->{odbc_ignore_named_placeholders} = 1;

    # get database name to use later when finding collation for table
    my $database_name = $h->get_info($GetInfoType{SQL_DATABASE_NAME});
    diag "Database: ", $database_name;

    # now find out the collations
    # server collation:
    my $r = $h->selectrow_arrayref(
        q/SELECT CONVERT (varchar, SERVERPROPERTY('collation'))/);
    diag "Server collation: ", $r->[0], "\n";

    # database collation:
    $r = $h->selectrow_arrayref(
        q/SELECT CONVERT (varchar, DATABASEPROPERTYEX(?,'collation'))/,
        undef, $database_name);
    diag "Database collation: ", $r->[0];

    # now call sp_help to find out about our table
    # first result-set should be name, owner, type and create datetime
    # second result-set should be:
    #  column_name, type, computed, length, prec, scale, nullable, trimtrailingblanks,
    #  fixedlennullinsource, collation
    # third result-set is identity columns
    # fourth result-set is row guilded columns
    # there are other result-sets depending on the object
    # sp_help -> http://technet.microsoft.com/en-us/library/ms187335.aspx
    my $column_collation;
    diag "Calling sp_help for table:";
    my $s = $h->prepare(q/{call sp_help(?)}/);
    $s->execute($table);
    my $result_set = 1;
    do {
        my $rows = $s->fetchall_arrayref;
        if ($result_set <= 2) {
            foreach my $row (@{$rows}) {
                diag join(",", map {$_ ? $_ : 'undef'} @{$row});
            }
        }
        if ($result_set == 2) {
            foreach my $row (@{$rows}) {
                diag "column:", $row->[0], " collation:", $row->[9], "\n";
                $column_collation = $row->[9];
            }
        }
        $result_set++;
    } while $s->{odbc_more_results};

    # now using the last column collation from above find the codepage
    $r = $h->selectrow_arrayref(
        q/SELECT COLLATIONPROPERTY(?, 'CodePage')/,
        undef, $column_collation);
    diag "Code page for column collation: ", $r->[0];
}

# output various codepage information
sub code_page {
    eval {require Win32::API::More};
    if ($@) {
        diag("Win32::API::More not available");
        return;
    }
    Win32::API::More->Import("kernel32", "UINT GetConsoleOutputCP()");
    Win32::API::More->Import("kernel32", "UINT GetACP()");
    my $cp = GetConsoleOutputCP();
    diag "Current active console code page: $cp\n";
    $cp = GetACP();
    diag "active code page: $cp\n";
    1;
}

# given a string call diag to output the ord of each character
sub ords {
    my $str = shift;

    use bytes;

    diag "    ords of output string:";
    foreach my $s(split(//, $str)) {
        diag sprintf("%x", ord($s)), ",";
    }
}

# read back the length of the data inserted according to the db and the data
# inserted (although nothing is done with the latter right now).
# given a perl expected length and a db expected length check them
# given a hex string of bytes the data should look like when cast to a
# binary check the inserted data matches what we expect.
sub show_it {
    my ($h, $expected_perl_length, $expected_db_length, $hex) = @_;

    my $r = $h->selectall_arrayref(q/select len(a), a from PERL_DBD_TABLE1 order by b asc/);

    diag( Dumper($r));
    foreach my $row(@$r) {
        is($row->[0], shift @{$expected_db_length}, "db character length") or
            diag("dsc: " . data_string_desc($row->[0]));
        if (!is(length($row->[1]), shift @{$expected_perl_length},
                "expected perl length")) {
            diag(data_string_desc($row->[1]));
            ords($row->[1]);
        }
    }

    if ($hex) {
        foreach my $hex_val(@$hex) {
            $r = $h->selectrow_arrayref(q/select count(*) from PERL_DBD_TABLE1 where cast(a as varbinary(100)) = / . $hex_val);
            is($r->[0], 1, "hex comparison $hex_val");
        }
    }
    $h->do(q/delete from PERL_DBD_TABLE1/);
}

# insert the string into the database
# daig output info about the inserted data
sub execute {
    my ($s, @strings) = @_;

    diag "  INPUT:";
    foreach my $string(@strings) {
        #diag "    input string: $string";
        diag "    data_string_desc of input string: ", data_string_desc($string);
        diag "    ords of input string: ";
        foreach my $s(split(//, $string)) {
            diag sprintf("%x,", ord($s));
        }

        {
            diag "    bytes of input string: ";
            use bytes;
            foreach my $s(split(//, $string)) {
                diag sprintf("%x,", ord($s));
            }
        }
    }

    ok($s->execute(@strings), "execute");
}

$dbh = DBI->connect();
unless($dbh) {
   BAIL_OUT("Unable to connect to the database $DBI::errstr\nTests skipped.\n");
   exit 0;
}
my $driver_name = $dbh->get_info($GetInfoType{SQL_DRIVER_NAME});
diag "Driver: ", $driver_name;

$dbh->{RaiseError} = 1;
eval {local $dbh->{PrintWarn} =0; $dbh->{PrintError} = 0;$dbh->do(q/drop table PERL_DBD_TABLE1/)};

my $dbname = $dbh->get_info($GetInfoType{SQL_DBMS_NAME});
if ($dbname !~ /Microsoft SQL Server/i) {
    note "Not MS SQL Server";
    plan skip_all => "Not MS SQL Server";
    exit;
}

if (!$dbh->{odbc_has_unicode}) {
    note "Not a unicode build of DBD::ODBC";
    plan skip_all => "Not a unicode build of DBD::ODBC";
    exit 0;
}

if ($^O eq 'MSWin32') {
    if (!code_page()) {
        note "Win32::API not found";
    }
}

eval {
    $dbh->do(q/create table PERL_DBD_TABLE1 (b integer, a varchar(100) collate Latin1_General_CI_AS)/);
};
if ($@) {
    fail("Cannot create table with collation - $@");
    done_testing();
    exit 0;
}

collations($dbh, 'PERL_DBD_TABLE1');

my $sql = q/insert into PERL_DBD_TABLE1 (b, a) values(?, ?)/;

my $s;
# a simple unicode string
my $unicode = "\x{20ac}\x{a3}";
diag "Inserting a unicode euro, utf8 flag on:\n";
$s = $dbh->prepare($sql); # redo to ensure no sticky params
execute($s, 1, $unicode);
show_it($dbh, [2], [2], ['0x80a3']);

my $codepage;
# a simple codepage string
{
    use bytes;
    $codepage = chr(0xa3) . chr(0x80); # it is important this is different to $unicode
}
diag "Inserting a codepage/bytes string:\n";
$s = $dbh->prepare($sql); # redo to ensure no sticky params
execute($s, 1, $codepage);
show_it($dbh, [2], [2], ['0xa380']);

# inserting a mixture of unicode chrs and codepage chrs per row in same insert
# unicode first - checks we rebind the 2nd parameter as SQL_CHAR
diag "Inserting a unicode followed by codepage chrs:\n";
$s = $dbh->prepare($sql); # redo to ensure no sticky params
execute($s, 1, $unicode);
execute($s, 2, $codepage);
show_it($dbh, [2,2], [2,2], ['0x80a3', '0x80a3']);

# inserting a mixture of unicode chrs and codepage chrs per row in same insert
# codepage first - checks we rebind the 2nd parameter SQL_WCHAR
diag "Inserting codepage chrs followed by unicode:\n";
$s = $dbh->prepare($sql); # redo to ensure no sticky params
execute($s, 1, $codepage);
execute($s, 2, $unicode);
show_it($dbh, [2,2], [2,2], ['0xa380', '0x80a3']);

Test::NoWarnings::had_no_warnings() if ($has_test_nowarnings);
done_testing();
