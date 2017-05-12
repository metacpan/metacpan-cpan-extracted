#!perl
# $Id: 21_read.pl 347 2009-04-27 18:15:05Z steffenw $

use strict;
use warnings;

our $VERSION = 0;

use Carp qw(croak);
require DBI;
require DBD::PO; DBD::PO->init(':plural');
require Data::Dumper;

# for test examples only
our $PATH_P;
our $TABLE_2P;
() = eval 'use Test::DBD::PO::Defaults qw($PATH_P $TABLE_2P)'; ## no critic (StringyEval InterpolationOfMetachars)

my $path  = $PATH_P
            || q{./LocaleData/de/LC_MESSAGES};
my $table = $TABLE_2P
            || 'table_plural.po';

my $dbh;
# Read the charset from the po file (table)
# and than change the encoding to this charset.
# This is the way to read unicode chars from unknown po files.
my $po_charset = q{};
for (1 .. 2) {
    $dbh = DBI->connect(
        "DBI:PO:f_dir=$path;po_charset=$po_charset",
        undef,
        undef,
        {
            RaiseError => 1,
            PrintError => 0,
        },
    ) or croak 'Cannot connect: ' . DBI->errstr();
    $po_charset = $dbh->func(
        {table => $table},        # wich table
        'charset',                # what to get
        'get_header_msgstr_data', # function name
    );
}

# get the header (first row) from po file (table)
# header msgid is always empty but not NULL
{
    my $header_data_ref = $dbh->func(
        {table => $table},              # wich table
        DBD::PO->get_all_header_keys(), # what to get
        'get_header_msgstr_data',       # function name
    );

    print Data::Dumper->new([@{$header_data_ref}], [DBD::PO->get_all_header_keys()]) ## no critic (LongChainsOfMethodCalls CheckedSyscalls)
                      ->Quotekeys(0)
                      ->Useqq(1)
                      ->Dump();
}

# get all the po entys (rows) from po file (table)
# row msgid is never empty
{
    my $sth = $dbh->prepare(<<"EOT");
        SELECT msgid, msgid_plural, msgstr, msgstr_0, msgstr_1
        FROM   $table
        WHERE  msgid <> ''
EOT

    $sth->execute();

    while (my $row = $sth->fetchrow_hashref()) {
        # and show each po entry (row)
        print Data::Dumper->new([$row], [qw(row)]) ## no critic (LongChainsOfMethodCalls CheckedSyscalls)
                          ->Quotekeys(0)
                          ->Useqq(1)
                          ->Dump();
    }
}

# all done
$dbh->disconnect();