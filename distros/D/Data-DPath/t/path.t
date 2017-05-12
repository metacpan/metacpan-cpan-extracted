#! /usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 48;

use Data::Dumper;

use_ok( 'Data::DPath::Path' );

my $dpath;
my @kinds;
my @parts;
my @filters;
my @refs;
my @isas;

# -------------------- easy DPath --------------------

$dpath    = new Data::DPath::Path( path => '/AAA/*[0]/CCC' );
my @steps = @{$dpath->_steps};
@kinds   = map { $_->kind   } @steps;
@parts   = map { $_->part   } @steps;
@filters = map { $_->filter } @steps;
@refs    = map { ref $_       } @steps;
#print Dumper(@steps);
#print Dumper(\@kinds);
is_deeply(\@kinds, [qw/ROOT KEY ANYSTEP KEY/],       "kinds");
is_deeply(\@parts, ['', qw{ AAA * CCC } ],             "parts");
is_deeply(\@filters, [ undef, undef, '[0]', undef ], "filters");
is((scalar grep { $_ eq 'Data::DPath::Step' } @refs), (scalar @steps), "refs");


# -------------------- really strange DPath with lots of hardcore quoting --------------------

my $strange_path = '//A1/A2/A3/AAA/"BB BB"/BB2 BB2/"CC CC"["foo bar"]/"DD / DD"/"DD2\DD2"//EEE[ $_->isa("Foo::Bar") ]/"\"EE E2\""[ "\"affe\"" eq "Foo2::Bar2" ]/"\"EE E3\"[1]"/"\"EE E4\""[1]/"\"EE\E5\\\\\\""[1]/"\"FFF\""/"GGG[foo == bar]"/*/*[2]/XXX/YYY/ZZZ';

$dpath = new Data::DPath::Path( path => $strange_path );
@steps = @{$dpath->_steps};
@kinds   = map { $_->kind   } @steps;
@parts   = map { $_->part   } @steps;
@filters = map { $_->filter } @steps;
@refs    = map { ref $_     } @steps;

is_deeply(\@kinds, [qw/ROOT
                       ANYWHERE
                       KEY
                       KEY
                       KEY
                       KEY
                       KEY
                       KEY
                       KEY
                       KEY
                       KEY
                       ANYWHERE
                       KEY
                       KEY
                       KEY
                       KEY
                       KEY
                       KEY
                       KEY
                       ANYSTEP
                       ANYSTEP
                       KEY
                       KEY
                       KEY
                      /],
          "kinds2");

is_deeply(\@parts, [
                    '',
                    '',
                    'A1',
                    'A2',
                    'A3',
                    'AAA',
                    'BB BB',
                    'BB2 BB2',
                    'CC CC',
                    'DD / DD',
                    'DD2\DD2',
                    '',
                    'EEE',
                    '"EE E2"',
                    '"EE E3"[1]',
                    '"EE E4"',
                    '"EE\E5\\\\"',
                    '"FFF"',
                    'GGG[foo == bar]',
                    '*',
                    '*',
                    'XXX',
                    'YYY',
                    'ZZZ'
                   ],
          "parts2");
is_deeply(\@filters, [
                      undef,
                      undef,
                      undef,
                      undef,
                      undef,
                      undef,
                      undef,
                      undef,
                      '["foo bar"]',
                      undef,
                      undef,
                      undef,
                      '[ $_->isa("Foo::Bar") ]',
                      '[ "\"affe\"" eq "Foo2::Bar2" ]',
                      undef,
                      '[1]', '[1]',
                      undef,
                      undef,
                      undef,
                      '[2]',
                      undef,
                      undef,
                      undef,
                     ],
          "filters2");
is((scalar grep { $_ eq 'Data::DPath::Step' } @refs), (scalar @steps), "refs2");

# -------------------- same again but with other quote characters --------------------

$strange_path = q!//A1/A2/A3/AAA/"BB BB"/BB2 BB2/"CC CC"["foo bar"]/"DD / DD"/"DD2\DD2"//EEE[ $_->isa("Foo::Bar") ]/"\"EE E2\""[ "\"affe\"" eq "Foo2::Bar2" ]/"\"EE E3\"[1]"/"\"EE E4\""[1]/"\"EE\E5\\\\\\""[1]/"\"FFF\""/"GGG[foo == bar]"/*/*[2]/XXX/YYY/ZZZ!;

# "

$dpath = new Data::DPath::Path( path => $strange_path );
@steps = @{$dpath->_steps};
@kinds   = map { $_->kind   } @steps;
@parts   = map { $_->part   } @steps;
@filters = map { $_->filter } @steps;
@refs    = map { ref $_     } @steps;

is_deeply(\@kinds, [qw/ROOT
                       ANYWHERE
                       KEY
                       KEY
                       KEY
                       KEY
                       KEY
                       KEY
                       KEY
                       KEY
                       KEY
                       ANYWHERE
                       KEY
                       KEY
                       KEY
                       KEY
                       KEY
                       KEY
                       KEY
                       ANYSTEP
                       ANYSTEP
                       KEY
                       KEY
                       KEY
                      /],
          "kinds2");

is_deeply(\@parts, [
                    '',
                    '',
                    'A1',
                    'A2',
                    'A3',
                    'AAA',
                    'BB BB',
                    'BB2 BB2',
                    'CC CC',
                    'DD / DD',
                    'DD2\DD2',
                    '',
                    'EEE',
                    '"EE E2"',
                    '"EE E3"[1]',
                    '"EE E4"',
                    '"EE\E5\\\\"',
                    '"FFF"',
                    'GGG[foo == bar]',
                    '*',
                    '*',
                    'XXX',
                    'YYY',
                    'ZZZ'
                   ],
          "parts2");
is_deeply(\@filters, [
                      undef,
                      undef,
                      undef,
                      undef,
                      undef,
                      undef,
                      undef,
                      undef,
                      '["foo bar"]',
                      undef,
                      undef,
                      undef,
                      '[ $_->isa("Foo::Bar") ]',
                      '[ "\"affe\"" eq "Foo2::Bar2" ]',
                      undef,
                      '[1]', '[1]',
                      undef,
                      undef,
                      undef,
                      '[2]',
                      undef,
                      undef,
                      undef,
                     ],
          "filters2");
is((scalar grep { $_ eq 'Data::DPath::Step' } @refs), (scalar @steps), "refs2");

# ---------------------------- filter without path part ----------------------

$strange_path = q!//A1/[2]/A3/[key =~ qw(neigh.*hoods)]/A5///A6!;
$dpath = new Data::DPath::Path( path => $strange_path );
@steps = @{$dpath->_steps};
@kinds   = map { $_->kind   } @steps;
@parts   = map { $_->part   } @steps;
@filters = map { $_->filter } @steps;
@refs    = map { ref $_     } @steps;
@isas    = grep { $_->isa('Data::DPath::Step') } @steps;

is_deeply(\@kinds, [qw/ROOT
                       ANYWHERE
                       KEY
                       ANYWHERE
                       KEY
                       ANYWHERE
                       KEY
                       ANYWHERE
                       ANYWHERE
                       KEY
                      /],
          "kinds3");

is_deeply(\@parts, [
                    '',
                    '',
                    'A1',
                    '',
                    'A3',
                    '',
                    'A5',
                    '',
                    '',
                    'A6',
                   ],
          "parts3");
is_deeply(\@filters, [
                      undef,
                      undef,
                      undef,
                      '[2]',
                      undef,
                      '[key =~ qw(neigh.*hoods)]',
                      undef,
                      undef,
                      undef,
                      undef,
                     ],
          "filters3");
is((scalar grep { $_ eq 'Data::DPath::Step' } @refs), (scalar @steps), "refs3");
is((scalar @isas), (scalar @steps), "isas3");

# --------------------------------------------------

$strange_path = q!/*[2]!;
$dpath = new Data::DPath::Path( path => $strange_path );
@steps = @{$dpath->_steps};
@kinds   = map { $_->kind   } @steps;
@parts   = map { $_->part   } @steps;
@filters = map { $_->filter } @steps;
@refs    = map { ref $_     } @steps;
@isas    = grep { $_->isa('Data::DPath::Step') } @steps;

is_deeply(\@kinds, [qw/ROOT
                       ANYSTEP
                      /],
          "kinds4");

is_deeply(\@parts, [
                    '',
                    '*',
                   ],
          "parts4");

is_deeply(\@filters, [
                      undef,
                      '[2]',
                     ],
          "filters4");

is((scalar grep { $_ eq 'Data::DPath::Step' } @refs), (scalar @steps), "refs4");
is((scalar @isas), (scalar @steps), "isas4");

# ---------------------------- filter with slashes ----------------------

$strange_path = q!//A1/*[2]/A3/.[key =~ /neigh.*hoods/]/A5///A6!;
$dpath = new Data::DPath::Path( path => $strange_path );
@steps = @{$dpath->_steps};
@kinds   = map { $_->kind   } @steps;
@parts   = map { $_->part   } @steps;
@filters = map { $_->filter } @steps;
@refs    = map { ref $_     } @steps;
@isas    = grep { $_->isa('Data::DPath::Step') } @steps;

is_deeply(\@kinds, [qw/ROOT
                       ANYWHERE
                       KEY
                       ANYSTEP
                       KEY
                       NOSTEP
                       KEY
                       ANYWHERE
                       ANYWHERE
                       KEY
                      /],
          "kinds5");

is_deeply(\@parts, [
                    '',
                    '',
                    'A1',
                    '*',
                    'A3',
                    '.',
                    'A5',
                    '',
                    '',
                    'A6',
                   ],
          "parts5");
is_deeply(\@filters, [
                      undef,
                      undef,
                      undef,
                      '[2]',
                      undef,
                      '[key =~ /neigh.*hoods/]',
                      undef,
                      undef,
                      undef,
                      undef,
                     ],
          "filters5");
is((scalar grep { $_ eq 'Data::DPath::Step' } @refs), (scalar @steps), "refs5");
is((scalar @isas), (scalar @steps), "isas5");

# ---------------------------- filter with slashes ----------------------

$strange_path = q!//A1/*[2]/A3/.[//]/A5///A6!;
$dpath = new Data::DPath::Path( path => $strange_path );
@steps = @{$dpath->_steps};
@kinds   = map { $_->kind   } @steps;
@parts   = map { $_->part   } @steps;
@filters = map { $_->filter } @steps;
@refs    = map { ref $_     } @steps;
@isas    = grep { $_->isa('Data::DPath::Step') } @steps;

is_deeply(\@kinds, [qw/ROOT
                       ANYWHERE
                       KEY
                       ANYSTEP
                       KEY
                       NOSTEP
                       KEY
                       ANYWHERE
                       ANYWHERE
                       KEY
                      /],
          "kinds6");

is_deeply(\@parts, [
                    '',
                    '',
                    'A1',
                    '*',
                    'A3',
                    '.',
                    'A5',
                    '',
                    '',
                    'A6',
                   ],
          "parts6");
is_deeply(\@filters, [
                      undef,
                      undef,
                      undef,
                      '[2]',
                      undef,
                      '[//]',
                      undef,
                      undef,
                      undef,
                      undef,
                     ],
          "filters6");
is((scalar grep { $_ eq 'Data::DPath::Step' } @refs), (scalar @steps), "refs6");
is((scalar @isas), (scalar @steps), "isas6");

# ---------------------------- filter with strange perl variables ------------

$strange_path = q!//A1/*[2]/A3/.[ local $/ = $/ ]/A5///A6!;
$dpath = new Data::DPath::Path( path => $strange_path );
@steps = @{$dpath->_steps};
@kinds   = map { $_->kind   } @steps;
@parts   = map { $_->part   } @steps;
@filters = map { $_->filter } @steps;
@refs    = map { ref $_     } @steps;
@isas    = grep { $_->isa('Data::DPath::Step') } @steps;

is_deeply(\@kinds, [qw/ROOT
                       ANYWHERE
                       KEY
                       ANYSTEP
                       KEY
                       NOSTEP
                       KEY
                       ANYWHERE
                       ANYWHERE
                       KEY
                      /],
          "kinds7");

is_deeply(\@parts, [
                    '',
                    '',
                    'A1',
                    '*',
                    'A3',
                    '.',
                    'A5',
                    '',
                    '',
                    'A6',
                   ],
          "parts7");
is_deeply(\@filters, [
                      undef,
                      undef,
                      undef,
                      '[2]',
                      undef,
                      '[ local $/ = $/ ]',
                      undef,
                      undef,
                      undef,
                      undef,
                     ],
          "filters7");
is((scalar grep { $_ eq 'Data::DPath::Step' } @refs), (scalar @steps), "refs7");
is((scalar @isas), (scalar @steps), "isas7");

# ---------------------------- filter with strange perl variables ------------

$strange_path = q!//A1/*[2]/A3/.[ local $] = $] ]/A5///A6!;
$dpath = new Data::DPath::Path( path => $strange_path );
@steps = @{$dpath->_steps};
@kinds   = map { $_->kind   } @steps;
@parts   = map { $_->part   } @steps;
@filters = map { $_->filter } @steps;
@refs    = map { ref $_     } @steps;
@isas    = grep { $_->isa('Data::DPath::Step') } @steps;

is_deeply(\@kinds, [qw/ROOT
                       ANYWHERE
                       KEY
                       ANYSTEP
                       KEY
                       NOSTEP
                       KEY
                       ANYWHERE
                       ANYWHERE
                       KEY
                      /],
          "kinds8");

is_deeply(\@parts, [
                    '',
                    '',
                    'A1',
                    '*',
                    'A3',
                    '.',
                    'A5',
                    '',
                    '',
                    'A6',
                   ],
          "parts8");
is_deeply(\@filters, [
                      undef,
                      undef,
                      undef,
                      '[2]',
                      undef,
                      '[ local $] = $] ]',
                      undef,
                      undef,
                      undef,
                      undef,
                     ],
          "filters8");
is((scalar grep { $_ eq 'Data::DPath::Step' } @refs), (scalar @steps), "refs8");
is((scalar @isas), (scalar @steps), "isas8");

# --------------------------------------------------

# ---------------------------- filter with perl variables $/ and $] combined ------------

$strange_path = q!//A1/*[2]/A3/.[ local $/ = $/; local $] = $] ]/A5///A6!;
$dpath = new Data::DPath::Path( path => $strange_path );
@steps = @{$dpath->_steps};
@kinds   = map { $_->kind   } @steps;
@parts   = map { $_->part   } @steps;
@filters = map { $_->filter } @steps;
@refs    = map { ref $_     } @steps;
@isas    = grep { $_->isa('Data::DPath::Step') } @steps;

is_deeply(\@kinds, [qw/ROOT
                       ANYWHERE
                       KEY
                       ANYSTEP
                       KEY
                       NOSTEP
                       KEY
                       ANYWHERE
                       ANYWHERE
                       KEY
                      /],
          "kinds9");

is_deeply(\@parts, [
                    '',
                    '',
                    'A1',
                    '*',
                    'A3',
                    '.',
                    'A5',
                    '',
                    '',
                    'A6',
                   ],
          "parts9");
is_deeply(\@filters, [
                      undef,
                      undef,
                      undef,
                      '[2]',
                      undef,
                      '[ local $/ = $/; local $] = $] ]',
                      undef,
                      undef,
                      undef,
                      undef,
                     ],
          "filters9");
is((scalar grep { $_ eq 'Data::DPath::Step' } @refs), (scalar @steps), "refs9");
is((scalar @isas), (scalar @steps), "isas9");

# --------------------------------------------------

