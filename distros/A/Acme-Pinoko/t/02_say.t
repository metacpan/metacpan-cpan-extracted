use strict;
use warnings;
use Acme::Pinoko;
use Test::More;


SKIP: {
    eval { require Text::MeCab; };
    skip 'Text::MeCab not installed', 1 if $@;

    my $pinoko = Acme::Pinoko->new;
    is($pinoko->say('ABC'), 'ABC', 'normal text');
    is($pinoko->say(undef), undef, 'undefined text');
    is($pinoko->say(''),    '',    'empty text');
    is($pinoko->say(0),     '0',   'zero');
    is($pinoko->say("\n"),  "\n",  '\n');
    is($pinoko->say("\t"),  "\t",  '\t');
}

SKIP: {
    eval { require Text::KyTea; };
    skip 'Text::KyTea not installed', 1 if $@;

    my $pinoko = Acme::Pinoko->new(parser => 'Text::KyTea');
    is($pinoko->say('ABC'), 'ABC', 'normal text');
    is($pinoko->say(undef), undef, 'undefined text');
    is($pinoko->say(''),    '',    'empty text');
    is($pinoko->say(0),     '0',   'zero');
    is($pinoko->say("\n"),  "\n",  '\n');
    is($pinoko->say("\t"),  "\t",  '\t');
}

done_testing;
