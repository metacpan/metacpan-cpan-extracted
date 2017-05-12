use strict;
use warnings;
use Acme::Pinoko;
use Test::More;
use Test::Fatal;

subtest 'mecab' => sub {
    eval { require Text::MeCab; };
    plan skip_all => 'Text::MeCab not installed' if $@;

    is( exception { Acme::Pinoko->new(parser_config => { unk_format => 'hoge' }) }, undef );
};

subtest 'kytea' => sub {
    eval { require Text::KyTea; };
    plan skip_all => 'Text::KyTea not installed' if $@;

    is(
        exception {
            Acme::Pinoko->new(
                parser        => 'Text::KyTea',
                parser_config => { tagmax => 3 })
        },
        undef
    );

    my $exception = exception { Acme::Pinoko->new(parser => 'Text::KyTea', parser_config => { hogehoge => 1 }); };
    like($exception, qr/Unknown option/, 'Unknown option');
};

done_testing;
