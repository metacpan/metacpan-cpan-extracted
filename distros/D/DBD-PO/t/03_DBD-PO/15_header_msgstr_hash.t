#!perl -T

use strict;
use warnings;

use Carp qw(croak);
use English qw(-no_match_vars $OS_ERROR $INPUT_RECORD_SEPARATOR);
use Test::DBD::PO::Defaults qw(
    $PATH $TRACE $DROP_TABLE
    trace_file_name
    $TABLE_15 $FILE_15
);
use Test::More tests => 40 + 1;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    require_ok('DBI');
}

my %test_data = (
    'Project-Id-Version' => [
        [qw( Project-Id-Version )],
        [qw( MyProject )],
    ],
    'Report-Msgid-Bugs-Mail' => [
        [qw( Report-Msgid-Bugs-To-Mail )],
        [qw( report.msgid.bugs.to@example.com )],
    ],
    'Last-Translator-Mail' => [
        [qw( Last-Translator-Mail )],
        [qw( last.translator@example.com )],
    ],
    extended => [
        [qw( extended )],
        [
            [
                'Extended-1' => 'extended_1',
                'Extended-2' => 'extended_2',
            ],
        ],
    ],
    all => [
        [qw(
            Project-Id-Version
            Report-Msgid-Bugs-To-Mail
            Last-Translator-Mail
            extended
        )],
        [
            'MyProject',
            'report.msgid.bugs.to@example.com',
            'last.translator@example.com',
            [
                'Extended-1' => 'extended_1',
                'Extended-2' => 'extended_2',
            ],
        ],
    ],
);

my ($dbh, $sth_update, $sth_select);

# connect
{
    $dbh = DBI->connect(
        "dbi:PO:f_dir=$PATH;po_eol=\n;po_charset=utf-8",
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
        CREATE TABLE $TABLE_15 (
            msgid VARCHAR,
            msgstr VARCHAR
        )
EO_SQL
    is($result, '0E0', 'create table');
    ok(-e $FILE_15, 'table file found');
}

# add header
{
    my $msgstr = $dbh->func(
        undef,
        'build_header_msgstr',
    );
    my $result = $dbh->do(<<"EO_SQL", undef, $msgstr);
        INSERT INTO $TABLE_15 (
            msgstr
        ) VALUES (?)
EO_SQL
    is($result, 1, 'add header');
}

# prepare
{
    $sth_update = $dbh->prepare(<<"EOT");
        UPDATE $TABLE_15
        SET    msgstr=?
        WHERE  msgid=''
EOT
    isa_ok($sth_update, 'DBI::st', 'prepare update');

    $sth_select = $dbh->prepare(<<"EOT");
        SELECT msgstr
        FROM $TABLE_15
        WHERE  msgid=''
EOT
    isa_ok($sth_update, 'DBI::st', 'prepare select');
}

sub update_header {
    my $name = shift;

    my ($test_keys, $test_values) = @{ $test_data{$name} };

    my %params;
    @params{ @{$test_keys} } = @{$test_values};

    my $msgstr = $dbh->func(
        \%params,
        'build_header_msgstr',
    );

    my $result = $sth_update->execute($msgstr);
    is($result, 1, "execute update header ($name)");

    return;
}

sub check_table_file {
    my $name = shift;

    my %test_of = map {$_ => 1} @{ $test_data{$name}->[0] };

    my $po = <<"EOT";
msgid ""
msgstr ""
EOT
    $po .= <<"EOT" if $test_of{'Project-Id-Version'};
"Project-Id-Version: MyProject\\n"
EOT
    $po .= <<"EOT" if $test_of{'Report-Msgid-Bugs-To-Mail'};
"Report-Msgid-Bugs-To:  <report.msgid.bugs.to\@example.com>\\n"
EOT
    $po .= <<"EOT" if $test_of{'Last-Translator-Mail'};
"Last-Translator:  <last.translator\@example.com>\\n"
EOT
    $po .= <<"EOT";
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=utf-8\\n"
EOT
    $po .= <<"EOT" if ! $test_of{extended};
"Content-Transfer-Encoding: 8bit"

EOT
    $po .= <<"EOT" if $test_of{extended};
"Content-Transfer-Encoding: 8bit\\n"
"Extended-1: extended_1\\n"
"Extended-2: extended_2"

EOT
    local $INPUT_RECORD_SEPARATOR = ();
    open my $file1, '< :encoding(utf-8)', $FILE_15 or croak $OS_ERROR;
    my $content1 = <$file1>;
    open my $file2, '< :encoding(utf-8)', \($po) or croak $OS_ERROR;
    my $content2 = <$file2>;
    eq_or_diff($content1, $content2, "check po file ($name)");

    return;
}

sub read_header {
    my $name = shift;

    my ($test_keys, $test_values) = @{ $test_data{$name} };

    for (0 .. $#{$test_keys}) {
        my $test_key   = $test_keys->[$_];
        my $test_value = $test_values->[$_];

        my $result = $sth_select->execute();
        is($result, 1, "execute ($name, $test_key)");

        my ($msgstr) = $sth_select->fetchrow_array();
        my $array_ref = $dbh->func(
            $msgstr,
            'split_header_msgstr',
        );
        is_deeply(
            $dbh->func(
                $array_ref,
                $test_key,
                'get_header_msgstr_data',
            ),
            $test_value,
            "read data from splitted header msgstr ($name $test_key)",
        );
    }

    return;
}

sub read_header_directly {
    my $name = shift;

    my ($test_keys, $test_values) = @{ $test_data{$name} };

    my $test_key   = @{$test_keys}
                     ? $test_keys
                     : $test_keys->[0];
    my $test_value = @{$test_values}
                     ? $test_values
                     : $test_values->[0];

    is_deeply(
        $dbh->func(
            {table => $TABLE_15},
            $test_key,
            'get_header_msgstr_data',
        ),
        $test_value,
        'read header data directly',
    );

    return;
}

# run for different headers
for my $name (keys %test_data) {
    update_header($name);
    check_table_file($name);
    read_header($name);
    read_header_directly($name);
}

# drop table
SKIP: {
    skip('drop table', 2)
        if ! $DROP_TABLE;

    my $result = $dbh->do(<<"EO_SQL");
        DROP TABLE $TABLE_15
EO_SQL
    is($result, '-1', 'drop table');
    ok(! -e $FILE_15, 'table file deleted');
}