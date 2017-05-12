#!perl -T

use strict;
use warnings;

use Carp qw(croak);
use English qw(-no_match_vars $OS_ERROR $INPUT_RECORD_SEPARATOR);
use Test::DBD::PO::Defaults qw(
    $TRACE $PATH $DROP_TABLE
    trace_file_name
    $TABLE_13 $FILE_13
);
use Test::More tests => 27 + 1;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    require_ok('DBI');
    require_ok('charnames');
    charnames->import(':full');
    require_ok('Encode');
    Encode->import('encode');
}

my $trace_file;
if ($TRACE) {
    open $trace_file, '>', trace_file_name();
}

# build table
sub build_table {
    my $param = shift;

    my $charset = $param->{charset};
    my $dbh = $param->{dbh} = DBI->connect(
        "dbi:PO:f_dir=$PATH;po_eol=\n;po_charset=$charset",
        undef,
        undef,
        {
            RaiseError => 1,
            PrintError => 0,
            AutoCommit => 1,
        },
    );
    isa_ok($dbh, 'DBI::db', "connect ($charset)");

    if ($trace_file) {
        $dbh->trace(4, $trace_file);
    }

    @{$param}{qw(table table_file)} = (
        $TABLE_13,
        $FILE_13,
    );
    for my $name (@{$param}{qw(table table_file)}) {
        $name =~ s{\?}{$charset}xms;
    }

    my $result = $dbh->do(<<"EO_SQL");
        CREATE TABLE $param->{table} (
            msgid VARCHAR,
            msgstr VARCHAR
        )
EO_SQL
    is($result, '0E0', "create table ($charset)");
    ok(-e $param->{table_file}, "table file found ($charset)");

    return;
}

sub add_header {
    my $param = shift;

    my $dbh = $param->{dbh};
    my $charset = $param->{charset};
    my $msgstr = $dbh->func(
        ($charset ? {charset => $charset} : undef),
        'build_header_msgstr',
    );
    my $result = $dbh->do(<<"EO_SQL", undef, $msgstr);
        INSERT INTO $param->{table} (
            msgstr
        ) VALUES (?)
EO_SQL
    is($result, 1, "add header ($param->{charset})");

    return;
}

sub add_line {
    my $param = shift;

    my $charset = $param->{charset};
    my $section_sign = $charset
                       ? "\N{SECTION SIGN}"
                       : encode 'iso-8859-1', "\N{SECTION SIGN}";
    my $msgid  = "id_$section_sign";
    my $msgstr = "str_$section_sign";
    my $result = $param->{dbh}->do(<<"EO_SQL", undef, $msgid, $msgstr);
        INSERT INTO $param->{table} (
            msgid,
            msgstr
        ) VALUES (?, ?)
EO_SQL
    is($result, 1, "add line ($charset)");

    return;
}

sub check_table_file {
    my $param = shift;

    my $charset = $param->{charset};
    my $po_charset = $charset || 'iso-8859-1';
    my $po = <<"EOT";
msgid ""
msgstr ""
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=$po_charset\\n"
"Content-Transfer-Encoding: 8bit"

msgid "id_\N{SECTION SIGN}"
msgstr "str_\N{SECTION SIGN}"

EOT
    local $INPUT_RECORD_SEPARATOR = ();
    open
        my $file1,
        "< :encoding($po_charset)",
        $param->{table_file}
        or croak $OS_ERROR;
    my $content1 = <$file1>;
    open
        my $file2,
        "< :encoding(utf-8)",
        \($po)
        or croak $OS_ERROR;
    my $content2 = <$file2>;
    eq_or_diff($content1, $content2, "check po file ($charset)");

    return;
}

sub drop_table {
    my $param = shift;

    SKIP: {
        skip('drop table', 2)
            if ! $DROP_TABLE;

        my $result = $param->{dbh}->do(<<"EO_SQL");
            DROP TABLE $param->{table}
EO_SQL
        is($result, '-1', 'drop table');
        ok(! -e $param->{table_file}, "drop table ($param->{charset})");
    }

    return;
}

for ( qw(utf-8 iso-8859-1), q{} ) {
    my $param = {charset => $_};
    build_table($param);
    add_header($param);
    add_line($param);
    check_table_file($param);
    drop_table($param);
}