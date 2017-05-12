#!perl
#!perl -T

use strict;
use warnings;

use Carp qw(croak);
use English qw(-no_match_vars $OS_ERROR $INPUT_RECORD_SEPARATOR);
use Test::DBD::PO::Defaults qw(
    $PATH $TRACE $SEPARATOR $EOL
    trace_file_name
    $TABLE_0X $FILE_0X
);
use Test::More tests => 43 + 1;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    require_ok('DBI');
    require_ok('DBD::PO'); DBD::PO->init(qw(:plural c-format php-format));
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

# change header flags
{
    my $sth_update = $dbh->prepare(<<"EO_SQL");
        UPDATE $TABLE_0X
        SET    fuzzy=?
        WHERE  msgid=?
EO_SQL
    isa_ok($sth_update, 'DBI::st', 'prepare update header');

    my $sth_select = $dbh->prepare(<<"EO_SQL");
        SELECT fuzzy
        FROM   $TABLE_0X
        WHERE  msgid=?
EO_SQL
    isa_ok($sth_select, 'DBI::st', 'prepare select header');

    my @data = (
        {
            test     => 'header fuzzy=1',
            set      => 1,
            get      => [1],
            callback => sub { check_file(shift, 'header_fuzzy') },
        },
        {
            test     => 'header fuzzy=0',
            set      => 0,
            get      => [0],
            callback => sub { check_file(shift) },
        },
    );
    for my $data (@data) {
        my $result = $sth_update->execute($data->{set}, q{});
        is($result, 1, "update: $data->{test}");

        $result = $sth_select->execute(q{});
        is($result, 1, "select: $data->{test}");
        $result = $sth_select->fetchrow_arrayref();
        is_deeply($result, $data->{get}, "fetch result: $data->{test}");

        $data->{callback}->( $data->{test} );
    }
}

# change flags
{
    my $sth_update = $dbh->prepare(<<"EO_SQL");
        UPDATE $TABLE_0X
        SET    fuzzy=?, c_format=?, php_format=?
        WHERE  msgid=?
EO_SQL
    isa_ok($sth_update, 'DBI::st');

    my $sth_select = $dbh->prepare(<<"EO_SQL");
        SELECT fuzzy, c_format, php_format
        FROM   $TABLE_0X
        WHERE  msgid=?
EO_SQL
    isa_ok($sth_select, 'DBI::st');

    my @data = (
        {
            test     => 'fuzzy=1',
            set      => [1, 0, 0],
            get      => [
                {
                    fuzzy      => 1,
                    c_format   => 0,
                    php_format => 0,
                },
            ],
            callback => sub { check_file(shift, 'fuzzy') },
        },
        {
            test     => 'c-format=1',
            set      => [0, 1, 0],
            get      => [
                {
                    fuzzy      => 0,
                    c_format   => 1,
                    php_format => 0,
                },
            ],
            callback => sub { check_file(shift, 'c-format') },
        },
        {
            test     => 'php-format=1',
            set      => [0, 0, 1],
            get      => [
                {
                    fuzzy      => 0,
                    c_format   => 0,
                    php_format => 1,
                },
            ],
            callback => sub { check_file(shift, 'php-format') },
        },
        {
            test     => 'c-format=-1',
            set      => [0, -1, 0],
            get      => [
                {
                    fuzzy      => 0,
                    c_format   => -1,
                    php_format => 0,
                },
            ],
            callback => sub { check_file(shift, 'no-c-format') },
        },
        {
            test     => 'php-format=-1',
            set      => [0, 0, -1],
            get      => [
                {
                    fuzzy      => 0,
                    c_format   => 0,
                    php_format => -1,
                },
            ],
            callback => sub { check_file(shift, 'no-php-format') },
        },
        {
            test     => 'all=1',
            set      => [(1) x 3],
            get      => [
                {
                    fuzzy      => 1,
                    c_format   => 1,
                    php_format => 1,
                },
            ],
            callback => sub { check_file(shift, 'all') },
        },
        {
            test     => 'all=0',
            set      => [(0) x 3],
            get      => [
                {
                    fuzzy      => 0,
                    c_format   => 0,
                    php_format => 0,
                },
            ],
            callback => sub { check_file(shift) },
        },
    );
    for my $data (@data) {
        my $result = $sth_update->execute(
            @{ $data->{set} },
            "id_value1${SEPARATOR}id_value2",
        );
        is($result, 1, "update: $data->{test}");

        $result = $sth_select->execute("id_value1${SEPARATOR}id_value2");
        is($result, 1, "select: $data->{test}");
        $result = $sth_select->fetchall_arrayref({});
        is_deeply($result, $data->{get}, "fetch result: $data->{test}");

        $data->{callback}->( $data->{test} );
    }
}

# check table file
sub check_file {
    my $test = shift;
    my $flag = shift || q{};

    my $po = <<'EOT';
# comment1
# comment2
EOT
    $po .= <<'EOT' if $flag eq 'header_fuzzy';
#, fuzzy
EOT
    $po .= <<'EOT';
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
EOT
    $po .= <<'EOT' if $flag eq 'fuzzy';
#, fuzzy
EOT
    $po .= <<'EOT' if $flag eq 'c-format';
#, c-format
EOT
    $po .= <<'EOT' if $flag eq 'no-c-format';
#, no-c-format
EOT
    $po .= <<'EOT' if $flag eq 'php-format';
#, php-format
EOT
    $po .= <<'EOT' if $flag eq 'no-php-format';
#, no-php-format
EOT
    $po .= <<'EOT' if $flag eq 'all';
#, c-format, fuzzy, php-format
EOT
    $po .= <<'EOT';
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
msgstr "str_1u"

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
    eq_or_diff($content, $po, "check po file: $test");

    return;
}
