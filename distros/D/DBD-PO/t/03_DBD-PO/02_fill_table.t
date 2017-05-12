#!perl 
#!perl -T

use strict;
use warnings;

use Carp qw(croak);
use English qw(-no_match_vars $OS_ERROR $INPUT_RECORD_SEPARATOR);
use Test::DBD::PO::Defaults qw(
    $PATH $TRACE $SEPARATOR $EOL
    trace_file_name $TABLE_0X $FILE_0X
);
use Test::More tests => 15 + 1;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    require_ok('DBI');
    require_ok('DBD::PO'); DBD::PO->init(':plural');
}

my ($dbh, $sth);

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

# full row
{
    $sth = $dbh->prepare(<<"EO_SQL");
        INSERT INTO $TABLE_0X (
            msgid,
            msgstr,
            msgctxt,
            reference,
            comment,
            automatic
        ) VALUES (?, ?, ?, ?, ?, ?)
EO_SQL
    isa_ok($sth, 'DBI::st', 'prepare insert');

    my $result = $sth->execute(qw(
        id_value
        str_value
        context_value
        ref_value
        comment_value
        automatic_value
    ));
    is($result, 1, "insert full row");
}

# full row, all are arrays
{
    my $result = $sth->execute(
        "id_value1${SEPARATOR}id_value2",
        "str_value1${SEPARATOR}str_value2",
        "context_value1${SEPARATOR}context_value2",
        "ref_value1${SEPARATOR}ref_value2",
        "comment_value1${SEPARATOR}comment_value2",
        "automatic_value1${SEPARATOR}automatic_value2",
    );
    is($result, 1, "insert full row, all are arrays");
}

# minimized row
{
    my $result = $dbh->do(<<"EO_SQL", undef, 'id_value_mini');
        INSERT INTO $TABLE_0X (msgid) VALUES (?)
EO_SQL
    is($result, 1, "insert minimized row");
}

# typical rows
{
    $sth = $dbh->prepare(<<"EO_SQL");
        INSERT INTO $TABLE_0X (msgid, msgstr) VALUES (?, ?)
EO_SQL
    isa_ok($sth, 'DBI::st', 'prepare insert');

    for (1 .. 2) {
        my $result = $sth->execute("id_$_", "str_$_");
        is($result, 1, "insert row $_");
    }
}

# plural rows
{
    $sth = $dbh->prepare(<<"EO_SQL");
        INSERT INTO $TABLE_0X (msgid, msgid_plural, msgstr_0, msgstr_1)
        VALUES                (?,     ?,            ?,        ?       )
EO_SQL
    isa_ok($sth, 'DBI::st', 'prepare insert');

    my $result = $sth->execute(
        'id_singular',
        'id_plural',
        'str_singular',
        'str_plural',
    );
    is($result, 1, 'insert row, plural, single line');
    $result = $sth->execute(
        "id_singular1${SEPARATOR}id_singular2",
        "id_plural1${SEPARATOR}id_plural2",
        "str_singular1${SEPARATOR}str_singular2",
        "str_plural1${SEPARATOR}str_plural2",
    );
    is($result, 1, 'insert row, plural, multi line');
}

# minimized plural row
{
    my $result = $dbh->do(<<"EO_SQL", undef, qw(id_value_singular_mini id_value_plural_mini) );
        INSERT INTO $TABLE_0X (msgid, msgid_plural) VALUES (?, ?)
EO_SQL
    is($result, 1, "insert minimized plural row");
}

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

# comment_value
#. automatic_value
#: ref_value
msgctxt "context_value"
msgid "id_value"
msgstr "str_value"

# comment_value1
# comment_value2
#. automatic_value1
#. automatic_value2
#: ref_value1
#: ref_value2
msgctxt ""
"context_value1\n"
"context_value2"
msgid ""
"id_value1\n"
"id_value2"
msgstr ""
"str_value1\n"
"str_value2"

msgid "id_value_mini"
msgstr ""

msgid "id_1"
msgstr "str_1"

msgid "id_2"
msgstr "str_2"

msgid "id_singular"
msgid_plural "id_plural"
msgstr[0] "str_singular"
msgstr[1] "str_plural"

msgid ""
"id_singular1\n"
"id_singular2"
msgid_plural ""
"id_plural1\n"
"id_plural2"
msgstr[0] ""
"str_singular1\n"
"str_singular2"
msgstr[1] ""
"str_plural1\n"
"str_plural2"

msgid "id_value_singular_mini"
msgid_plural "id_value_plural_mini"
msgstr[0] ""

EOT
    open my $file, '< :raw', $FILE_0X or croak $OS_ERROR;
    local $INPUT_RECORD_SEPARATOR = ();
    my $content = <$file>;
    $po =~ s{\n}{$EOL}xmsg;
    eq_or_diff($content, $po, 'check po file');
}
