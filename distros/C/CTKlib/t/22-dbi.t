#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 22-dbi.t 272 2019-09-26 08:45:46Z minus $
#
#########################################################################
use strict;
use warnings;
use Test::More;
plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";
plan tests => 9;

use CTK::DBI;

use constant {
        DB_DSN  => 'DBI:Sponge:',
    };

use constant SELECT_TABLE => <<SQL;
    SELECT
        *
    FROM
        test
    WHERE
        uid = ?
SQL

use constant SELECT_FIELD => <<SQL;
    SELECT SYSDATE() FROM DUAL;
SQL

use constant SELECT_INCORRECT_FIELD => <<SQL;
    SELECT MYFAKEFUNC() FROM DUAL;
SQL

# Connect
my $mso = new CTK::DBI(
        -dsn        => DB_DSN,
        #-user       => 'login',
        #-pass       => 'password',
        -connect_to => 5,
        -request_to => 7,
        -attr       => {
                PrintError => 0,
                RaiseError => 0,
            },
        #-debug     => 1,
        -prepare_attr => {
                rows => [
                    [1, 'foo', 1],
                    [2, 'bar', 1],
                    [3, 'baz', 2],
                ],
                NAME => [qw/id name uid/],
            },
    );
#my $dbh = $mso->connect;
ok(!$mso->error, "Connect") or diag($mso->error);
#exit 1 if $mso->error;

#note(explain($mso));

# Execute SQL
{
    my $sth = $mso->execute(SELECT_TABLE);
    ok($sth, "Execute statement") or diag($mso->error);
    ok($sth && $sth->finish, "Finish transaction") or diag($mso->error);
}

# Get table (table as hash)
{
    my %tbl = $mso->tableh("id", SELECT_TABLE, 1);
    ok(scalar(%tbl), "Get table (table as hash)") or diag($mso->error);
    #note(explain(\%tbl));
}

# Get table (table as array)
{
    my @tbl = $mso->table(SELECT_TABLE, 1);
    ok(!$mso->error, "Get table (table as array)") or diag($mso->error);
    #note(explain(\@tbl));
}

# Get record (record as hash)
{
    my %row = $mso->recordh(SELECT_TABLE, 1);
    ok(!$mso->error, "Get record (record as hash)") or diag($mso->error);
    #note(explain(\%row));
}

# Get record (record as array)
{
    my @row = $mso->record(SELECT_TABLE, 1);
    ok(!$mso->error, "Get record (record as array)") or diag($mso->error);
    #note(explain(\@row));
}

# Get field (first element from record)
{
    my $fld = $mso->field(SELECT_FIELD);
    ok(!$mso->error, "Get field (first element from record)") or diag($mso->error);
    #note(explain([$fld]));
}

# Get incorrect field (first element from record)
{
    my $fld = $mso->field(SELECT_INCORRECT_FIELD);
    ok(!$fld, "Get incorrect field (first element from record)") or diag($mso->error);
    #note(explain([$fld]));
}

1;

__END__

