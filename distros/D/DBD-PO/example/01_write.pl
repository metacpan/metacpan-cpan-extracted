#!perl
# $Id: 01_write.pl 378 2009-05-02 06:29:51Z steffenw $

use strict;
use warnings;

our $VERSION = 0;

use Carp qw(croak);
require DBI;

# for test examples only
our $PATH;
our $TABLE_2X;
() = eval 'use Test::DBD::PO::Defaults qw($PATH $TABLE_2X)'; ## no critic (StringyEval InterpolationOfMetachars)

my $path  = $PATH
            || q{.};
my $table = $TABLE_2X
            || 'table_xx.po'; # for langueage xx

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
            comment    VARCHAR,
            automatic  VARCHAR,
            reference  VARCHAR,
            obsolete   INTEGER,
            fuzzy      INTEGER,
            msgid      VARCHAR,
            msgstr     VARCHAR
        )
EOT

# build a default header
my $header_msgstr = $dbh->func(
    undef,                 # minimized
    'build_header_msgstr', # function name
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
        msgstr
    ) VALUES (?, ?)
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
        msgid  => 'text3 original %1',
        msgstr => 'text3 translated %1',
    },
    {
        msgid  => 'text4 original [quant,_1,o_one,o_more,o_nothing]',
        msgstr => 'text4 translated [quant,_1,t_one,t_more,t_nothing]',
    },
);

# write all the data into the po file (table)
for my $data (@data) {
    $sth->execute(
        $dbh->func(
            @{$data}{qw(msgid msgstr)},
            'maketext_to_gettext',
        ),
    );
};

# all done
$dbh->disconnect();