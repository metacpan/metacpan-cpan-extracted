#!perl -T
# /* vim:et: set ts=4 sw=4 sts=4 tw=78 encoding=utf-8: */

use 5.008005;        # require perl 5.8.5
                     # DBD::SQLite Unicode is not supported before 5.8.5
use strict;
use warnings;
use utf8; # yes this source code does contain utf8 characters

use ACME::QuoteDB;
use ACME::QuoteDB::LoadDB;

#use Test::More 'no_plan';
use Test::More tests => 8;
use File::Basename qw/dirname/;
use Data::Dumper qw/Dumper/;
use Carp qw/croak/;
use File::Temp;
use File::Spec;


BEGIN {
    eval "use DBD::SQLite";
    $@ and croak 'DBD::SQLite is a required dependancy';

    # give alternate path to the DB
    $ENV{ACME_QUOTEDB_PATH} = 
          File::Temp->new( UNLINK => 0,
                           EXLOCK => 0,
                           SUFFIX => '.dat',
                     );
}

# matches the data in our utf8.csv file, soon to be in our quote db
my $utf8_quotes = [
    '¥ · £ · € · $ · ¢ · ₡ · ₢ · ₣ · ₤ · ₥ · ₦ · ₧ · ₨ · ₩ · ₪ · ₫ · ₭ · ₮ · ₯',
    '我能吞下玻璃而不伤身体。',
    '私はガラスを食べられます。それは私を傷つけません。',
    '나는 유리를 먹을 수 있어요. 그래도 아프지 않아요',
    'Tsésǫʼ yishą́ągo bííníshghah dóó doo shił neezgai da. ',
    'Μπορώ να φάω σπασμένα γυαλιά χωρίς να πάθω τίποτα.',
    'मैं काँच खा सकता हूँ, मुझे उस से कोई पीडा नहीं होती.',
    'אני יכול לאכול זכוכית וזה לא מזיק לי',
];# any takers for specifying each multibyte code sequence for the above,.. ;)

{
    #make test db writeable
    use ACME::QuoteDB::DB::DBI;
    # yeah, this is supposed to be covered by the build process
    # but is failing sometimes,...
    chmod 0666, ACME::QuoteDB::DB::DBI->get_current_db_path;

    my $q = File::Spec->catfile((dirname(__FILE__),'data'), 
        'utf8.csv'
    );
    my $load_db = ACME::QuoteDB::LoadDB->new({
                                file        => $q,
                                file_format => 'csv',
                                delimiter   => "\t",
                                create_db   => 1
                            });

    isa_ok $load_db, 'ACME::QuoteDB::LoadDB';
    $load_db->data_to_db;
    is $load_db->success, 1;
}

my $sq = ACME::QuoteDB->new;

# matches the data in our utf8.csv file, attribution's to the 'quotes' above
my @expected_attribution_list = (
    'UTF-8 Sampler Currency',
    'I can eat grass (Chinese)',
    'I can eat grass (Japanese)',
    'I can eat grass (Korean)',
    'I can eat grass (Navajo)',
    'I can eat grass (Greek)',
    'I can eat grass (Hindi)',
    'I can eat grass (Hebrew)',
);
is( $sq->list_attr_names, join "\n", sort @expected_attribution_list);

ok $sq->get_quote; # default get random quote
ok $sq->get_quote =~ m{\w+};

is $sq->get_quote({AttrName => $expected_attribution_list[1]}),
      $utf8_quotes->[1] . "\n-- " . $expected_attribution_list[1];

is $sq->get_quote({AttrName => $expected_attribution_list[6]}),
      $utf8_quotes->[6] . "\n-- " . $expected_attribution_list[6];

is @{ $sq->get_quotes({ Rating => '10' })}, @{$utf8_quotes};

