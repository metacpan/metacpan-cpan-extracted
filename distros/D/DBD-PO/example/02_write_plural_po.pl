#!perl
# $Id: 01_write.pl 315 2008-12-17 21:09:23Z steffenw $

use strict;
use warnings;

our $VERSION = 0;

use Carp qw(croak);
use File::Path qw(mkpath);
require DBI;
require DBD::PO; DBD::PO->init(':plural');

# for test examples only
our $PATH_P;
our $TABLE_2P;
() = eval 'use Test::DBD::PO::Defaults qw($PATH_P $TABLE_2P)'; ## no critic (StringyEval InterpolationOfMetachars)

my $path  = $PATH_P
            || q{./LocaleData/de/LC_MESSAGES};
my $table = $TABLE_2P
            || 'table_plural.po';

mkpath $path;

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

# create the new po file (table)
$dbh->do(<<"EOT");
    CREATE TABLE
        $table (
            comment      VARCHAR,
            automatic    VARCHAR,
            reference    VARCHAR,
            obsolete     INTEGER,
            fuzzy        INTEGER,
            msgid        VARCHAR,
            msgid_plural VARCHAR,
            msgstr_0     VARCHAR,
            msgstr_1     VARCHAR
        )
EOT

# build a header
my $header_msgstr = $dbh->func(
    {
        # an English/German example
        'Plural-Forms' => 'nplurals=2; plural=n != 1;',
    },
    # function name
    'build_header_msgstr',
);

# write the header (first row)
# header msgid is always empty, will set to NULL or q{} and get back as q{}
# header msgstr must have a length
$dbh->do(<<"EOT", undef, $header_msgstr);
    INSERT INTO $table (
        msgstr
    ) VALUES (?)
EOT

# prepare to write some po entrys (rows)
# row msgid must have a length
# row msgstr can be empty (NULL or q{}), will get back as q{}
my $sth = $dbh->prepare(<<"EOT");
    INSERT INTO $table (
        msgid,
        msgid_plural,
        msgstr,
        msgstr_0,
        msgstr_1
    ) VALUES (?, ?, ?, ?, ?)
EOT

# declare some data only
my @data = (
    {
        msgid  => 'text1 original',
        msgstr => 'text1 translated',
    },
    {
        msgid  => "text2 original\n2nd line of text2",
        msgstr => "text2 translated\n2nd line of text2",
    },
    {
        msgid  => 'text5 original {text}',
        msgstr => 'text5 translated {text}',
    },
    {
        msgid        => 'text6 original {num} singular',
        msgid_plural => 'text6 original {num} plural',
        msgstr_0     => 'text6 translated {num} singular',
        msgstr_1     => 'text6 translated {num} plural',
    },
);

# write all the data into the po file (table)
for my $data (@data) {
    $sth->execute(
        @{$data}{qw(msgid msgid_plural msgstr msgstr_0 msgstr_1)},
    );
};

# all done
$dbh->disconnect();