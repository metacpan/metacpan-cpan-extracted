#!perl -T

use strict;
use warnings;

use Carp qw(croak);
use English qw(-no_match_vars $OS_ERROR $INPUT_RECORD_SEPARATOR);
use Test::DBD::PO::Defaults qw(
    $PATH $EOL $SEPARATOR $TRACE
    trace_file_name
    $TABLE_0X
    $FILE_0X
);
use Test::More tests => 6 + 1;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    require_ok('DBI');
}

my $dbh = DBI->connect(
    "dbi:PO:f_dir=$PATH;po_eol=$EOL;po_separator=$SEPARATOR;po_charset=utf-8",
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

my $result = $dbh->do(<<"EO_SQL");
    CREATE TABLE $TABLE_0X (
        comment    VARCHAR,
        automatic  VARCHAR,
        reference  VARCHAR,
        obsolete   INTEGER,
        fuzzy      INTEGER,
        msgctxt    VARCHAR,
        msgid      VARCHAR,
        msgstr     VARCHAR
    )
EO_SQL
is($result, '0E0', 'create table');
ok(-e $TABLE_0X, 'table file found');

my @parameters = (
    join(
        $SEPARATOR,
        qw(
            comment1
            comment2
        ),
    ),
    $dbh->func(
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
                'steffenw@example.org',
            ],
            [
                'MyTeam',
                'cpan@example.org',
            ],
            undef,
            undef,
            undef,
            undef,
            [qw(
                X-Poedit-Language      German
                X-Poedit-Country       GERMANY
                X-Poedit-SourceCharset utf-8
            )],
        ],
        'build_header_msgstr',
    ),
);
$result = $dbh->do(<<"EO_SQL", undef, @parameters);
    INSERT INTO $TABLE_0X (
        comment,
        msgstr
    ) VALUES (?, ?)
EO_SQL
is($result, 1, 'insert header');

# check table file
{
    my $po = <<'EOT';
# comment1
# comment2
msgid ""
msgstr ""
"Project-Id-Version: Testproject\n"
"Report-Msgid-Bugs-To: Bug Reporter <bug@example.org>\n"
"POT-Creation-Date: no POT creation date\n"
"PO-Revision-Date: no PO revision date\n"
"Last-Translator: Steffen Winkler <steffenw@example.org>\n"
"Language-Team: MyTeam <cpan@example.org>\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=utf-8\n"
"Content-Transfer-Encoding: 8bit\n"
"X-Poedit-Language: German\n"
"X-Poedit-Country: GERMANY\n"
"X-Poedit-SourceCharset: utf-8"

EOT
    open my $file, '< :raw', $FILE_0X or croak $OS_ERROR;
    local $INPUT_RECORD_SEPARATOR = ();
    my $content = <$file>;
    $po =~ s{\n}{$EOL}xmsg;
    eq_or_diff($content, $po, 'check po file');
}