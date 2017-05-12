#!perl
# $Id: 04_join.pl 324 2009-02-12 07:49:29Z steffenw $

use strict;
use warnings;

our $VERSION = 0;

use Carp qw(croak);
use English qw(-no_match_vars $OS_ERROR);
use DBI ();

# for test examples only
our $PATH;
() = eval 'use Test::DBD::PO::Defaults qw($PATH)'; ## no critic (StringyEval InterpolationOfMetachars)

my $path = $PATH
           || q{.};
my @table = qw(de ru de_to_ru);

# write a file to disk only
{
    my $file_name = "$path/$table[0].po";
    open my $file, '>', $file_name ## no critic (BriefOpen)
        or croak "Can't open file $file_name: $OS_ERROR";
    print {$file} <<'EOT' or croak "Can't write file $file_name: $OS_ERROR";
msgid ""
msgstr ""
"Content-Type: text/plain; charset=utf-8\n"
"Content-Transfer-Encoding: 8bit"

msgid "text 1 en"
msgstr "text 1 de"

msgid "text 2 en"
msgstr "text 3 de"

msgid "text3 en"
msgstr "text3 de"


EOT
}

# write a file to disk only
{
    my $file_name = "$path/$table[1].po";
    open my $file, '>', $file_name ## no critic (BriefOpen)
        or croak "Can't open file $file_name: $OS_ERROR";
    print {$file} <<'EOT' or croak "Can't write file $file_name: $OS_ERROR";
msgid ""
msgstr ""
"Content-Type: text/plain; charset=utf-8\n"
"Content-Transfer-Encoding: 8bit"

msgid "text 1 en"
msgstr "text 1 ru"

msgid "text 2 en"
msgstr "text 3 ru"

msgid "text3 en"
msgstr "text3 ru"


EOT
}

# connect to database (directory)
my $dbh = DBI->connect(
    "DBI:PO:f_dir=$path;po_charset=utf-8",
    undef,
    undef,
    {
        RaiseError => 1,
        PrintError => 0,
    },
) or croak 'Cannot connect: ' . DBI->errstr();
for (@table) {
    $dbh->{po_tables}->{$_} = {file => "$_.po"};
}

# create the joined po file (table)
$dbh->do(<<"EOT");
    CREATE TABLE $table[2]
    (
        msgid  VARCHAR,
        msgstr VARCHAR
    )
EOT

# prepare to write the joined po file (table)
my $sth_insert = $dbh->prepare(<<"EOT");
    INSERT INTO $table[2]
    (msgid, msgstr)
    VALUES (?, ?)
EOT

# build and write the header of the joined po file (table)
$sth_insert->execute(
    q{},
    $dbh->func(
        undef,                 # minimized
        'build_header_msgstr', # function name
    ),
);

# require joined data
my $sth_select = $dbh->prepare(<<"EOT");
    SELECT $table[0].msgstr, $table[1].msgstr
    FROM $table[0]
    INNER JOIN $table[1] ON $table[0].msgid = $table[1].msgid
    WHERE $table[0].msgid <> ''
EOT
$sth_select->execute();

# get the joined data
while ( my @data = $sth_select->fetchrow_array() ) {
    $sth_insert->execute(@data);
}

# all done
$dbh->disconnect();