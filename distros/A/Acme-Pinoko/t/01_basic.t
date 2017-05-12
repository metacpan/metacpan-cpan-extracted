use strict;
use warnings;
use Acme::Pinoko;
use Test::More;
use Test::Fatal;

can_ok('Acme::Pinoko', qw/new say/);

subtest 'valid new' => sub {
    my $pinoko;

    SKIP: {
        eval { require Text::MeCab; };
        skip 'Text::MeCab not installed', 1 if $@;
        is( exception{ $pinoko = Acme::Pinoko->new; }, undef, 'parser: default' );
        isa_ok($pinoko, 'Acme::Pinoko');
    }

    SKIP: {
        eval { require Text::MeCab; };
        skip 'Text::MeCab not installed', 1 if $@;
        is( exception{ $pinoko = Acme::Pinoko->new(parser => 'Text::MeCab'); }, undef, 'parser: mecab' );
        isa_ok($pinoko, 'Acme::Pinoko');
    }

    SKIP: {
        eval { require Text::KyTea; };
        skip 'Text::KyTea not installed', 1 if $@;
        is( exception{ $pinoko = Acme::Pinoko->new(parser => 'Text::KyTea'); }, undef, 'parser: kytea' );
        isa_ok($pinoko, 'Acme::Pinoko');
    }
};

subtest 'invalid new' => sub {
    my $exception = exception { Acme::Pinoko->new(parser => 'Text::ChaSen'); };
    like($exception, qr/Invalid parser: 'Text::ChaSen'/, 'Invalid parser');

    $exception = exception { Acme::Pinoko->new(parse => 'Text::MeCab'); };
    like($exception, qr/Unknown option: 'parse'/, 'Unknown option');
};

done_testing;
