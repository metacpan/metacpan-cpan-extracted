#!perl -T

use strict;
use warnings;

use Carp qw(croak);
use English qw(-no_match_vars $OS_ERROR $INPUT_RECORD_SEPARATOR);
use Test::DBD::PO::Defaults qw(
    $PATH $TRACE $DROP_TABLE
    trace_file_name
    $TABLE_14 $FILE_14
);
use Test::More tests => 17 + 1;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    require_ok('DBI');
    require_ok('DBD::PO::Text::PO');
}

my $test_string = join "\n", (
    (
        map {
            join q{}, map { chr $_ } 8 * $_ .. 8 * $_ + 7;
        } 0 .. 15
    ),
    (
        map {
            join q{}, map { "\\" . chr $_ } 8 * $_ .. 8 * $_ + 7;
        } 0 .. 15
    ),
);

sub quote {
    my $string = shift;
    my $eol    = shift;

    my %named = (
        #qq{\a} => qq{\\a}, # BEL
        #qq{\b} => qq{\\b}, # BS
        #qq{\t} => qq{\\t}, # TAB
        qq{\n} => qq{\\n}, # LF
        #qq{\f} => qq{\\f}, # FF
        #qq{\r} => qq{\\r}, # CR
        qq{"}  => qq{\\"},
        qq{\\} => qq{\\\\},
    );
    $string =~ s{
        ( [^ !#$%&'()*+,\-.\/0-9:;<=>?@A-Z\[\]\^_`a-z{|}~] )
    }{
        ord $1 < 0x80
        ? (
            exists $named{$1}
            ? $named{$1}
            : sprintf '\x%02x', ord $1
        )
        : $1;
    }xmsge;
    $string = qq{"$string"};
    # multiline
    if ($string =~ s{\A ( " .*? \\n )}{""\n$1}xms) {
        $string =~ s{\\n}{\\n"$eol"}xmsg;
    }

    return $string;
}

my $po_string = quote($test_string, "\n");

my $dbh;

# connect
{
    $dbh = DBI->connect(
        "dbi:PO:f_dir=$PATH;po_charset=utf-8;po_eol=\n",
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
        CREATE TABLE $TABLE_14 (
            msgid VARCHAR,
            msgstr VARCHAR
        )
EO_SQL
    is($result, '0E0', 'create table');
    ok(-e $FILE_14, 'table file found');
}

# quote
{
    my @data = (
        qq{\0} => qq{'\0'},
        qq{\\} => qq{'_Q_U_O_T_E_D_:\\\\'},
        qq{"}  => qq{'"'},
        qq{'}  => qq{'_Q_U_O_T_E_D_:\\''},
        qq{\n} => qq{'\n'},
        qq{\r} => qq{'\r'},
    );

    while (my ($raw, $quoted) = splice @data, 0, 2) {
        is(
            $dbh->quote($raw),
            $quoted,
            "quote $raw",
        );
    }
}

# add header
{
    my $msgstr = $dbh->func(
        undef,
        'build_header_msgstr',
    );
    my $result = $dbh->do(<<"EO_SQL", undef, $msgstr);
        INSERT INTO $TABLE_14 (
            msgstr
        ) VALUES (?)
EO_SQL
    is($result, 1, 'add header');
}

# add line as parameter
{
    my $msgid  = 'id_1';
    my $msgstr = $test_string;
    my $result = $dbh->do(<<"EO_SQL", undef, $msgid, $msgstr);
        INSERT INTO $TABLE_14 (
            msgid,
            msgstr
        ) VALUES (?, ?)
EO_SQL
    is($result, 1, 'add line as parameter');
}

# add line using method quote
{
    my $msgid  = $dbh->quote('id_2');
    my $msgstr = $dbh->quote($test_string);
    my $result = $dbh->do(<<"EO_SQL");
        INSERT INTO $TABLE_14 (
            msgid,
            msgstr
        ) VALUES ($msgid, $msgstr)
EO_SQL
    is($result, 1, 'add line using method quote');
}

# check_table_file
{
    my $po = <<"EOT";
msgid ""
msgstr ""
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=utf-8\\n"
"Content-Transfer-Encoding: 8bit"

msgid "id_1"
msgstr $po_string

EOT
    $po .= <<"EOT";
msgid "id_2"
msgstr $po_string

EOT
    local $INPUT_RECORD_SEPARATOR = ();
    open my $file1, '< :encoding(utf-8)', $TABLE_14 or croak $OS_ERROR;
    my $content1 = <$file1>;
    open my $file2, '< :encoding(utf-8)', \($po) or croak $OS_ERROR;
    my $content2 = <$file2>;
    eq_or_diff($content1, $content2, 'check po file');
}

# drop table
SKIP: {
    skip('drop table', 2)
        if ! $DROP_TABLE;

    my $result = $dbh->do(<<"EO_SQL");
        DROP TABLE $TABLE_14
EO_SQL
    is($result, '-1', 'drop table');
    ok(! -e $FILE_14, 'table file deleted');
}