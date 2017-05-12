#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Acme::Pinoko;
#use Acme::Ikamusume; # Acme::Ikamusume invades Text::MeCab globally
use Benchmark qw/cmpthese timethese/;
use open qw/:utf8 :std/;


my $kytea_pinoko = Acme::Pinoko->new(parser => 'Text::KyTea');
my $mecab_pinoko = Acme::Pinoko->new(parser => 'Text::MeCab');

my $text ='おはようございます。ﾋﾟﾉｺ' x 10;

cmpthese(
    timethese(-1, {
        'kytea_pinoko'  => \&kytea_pinoko,
        'mecab_pinoko'  => \&mecab_pinoko,
        #'geso'          => \&geso,
    })
);

sub kytea_pinoko
{
    my $result = $kytea_pinoko->say($text);
}

sub mecab_pinoko
{
    my $result = $mecab_pinoko->say($text);
}

=begin
sub geso
{
    my $result = Acme::Ikamusume->geso($text);
}
=end
=cut
