#!perl -T

use strict;
use warnings;

use Test::DBD::PO::Defaults qw(
    $PATH $TRACE
    trace_file_name
    $TABLE_0X
);
use Test::More tests => 5 + 1;
use Test::NoWarnings;

BEGIN {
    require_ok('DBI');
}

my $dbh;

# connext
{
    $dbh = DBI->connect(
        "dbi:PO:f_dir=$PATH;po_charset=utf-8",
        undef,
        undef,
        {
            RaiseError => 1,
            PrintError => 0,
            AutoCommit => 1,
        },
    );
    isa_ok($dbh, 'DBI::db', 'connect');

    if ($TRACE) {
        open my $file, '>', trace_file_name();
        $dbh->trace(4, $file);
    }
}

my $sth = $dbh->prepare(<<"EO_SQL");
        SELECT msgstr
        FROM   $TABLE_0X
        WHERE  msgid=''
EO_SQL
isa_ok($sth, 'DBI::st', 'prepare');

is(
    $sth->execute(),
    1,
    'execute',
);

my ($msgstr) = $sth->fetchrow_array();
is_deeply(
    $dbh->func($msgstr, 'split_header_msgstr'),
    [
        'Testproject',
        [
            'Bug Reporter',
            'bug@example.org',
        ],
        'no POT creation date',
        'no PO revision date',
        [
            'Steffen Winkler',
            'steffenw@example.org'
        ],
        [
            'MyTeam',
            'cpan@example.org',
        ],
        '1.0',
        [
            'text/plain',
            'utf-8',
        ],
        '8bit',
        undef,
        [qw(
            X-Poedit-Language      German
            X-Poedit-Country       GERMANY
            X-Poedit-SourceCharset utf-8
        )],
    ],
    'split header msgstr',
);