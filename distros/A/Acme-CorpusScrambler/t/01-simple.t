#!/usr/bin/perl

use strict;
use warnings;
use Acme::CorpusScrambler;
use IO::All;

use Test::More tests => 3;

my $sc = Acme::CorpusScrambler->new;


# Scramble everything
my $text1 = $sc->scramble;
ok( length($text1) > 0 );

$sc->feed( "Java" => io("t/text/java.txt")->utf8->all );
$sc->feed( "Perl" => io("t/text/perl.txt")->utf8->all );
$sc->feed( "XML"  => io("t/text/xml.txt")->utf8->all );
$sc->feed( "Dream"  => io("t/text/dream.txt")->utf8->all );

# Scramble only XML with Perl
my $text2 = $sc->scramble(qw( XML Perl) );
ok( length($text2) > 0 );

my $text3 = $sc->scramble(qw( Opcafe ) );
ok( length($text3) == 0 );

