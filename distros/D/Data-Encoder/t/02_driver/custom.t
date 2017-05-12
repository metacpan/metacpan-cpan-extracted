use strict;
use warnings;
use Data::Encoder::Custom;
use Test::More;

subtest 'simple' => sub {
    my $encoder = Data::Encoder::Custom->new({
        encoder => sub {
            my ($stuff, @args) = @_;
            $stuff =~ tr/a-zA-Z/A-Za-z/;
            $stuff;
        },
        decoder => sub {
            my ($stuff, @args) = @_;
            $stuff =~ tr/A-Za-z/a-zA-Z/;
            $stuff;
        },
    });

    is $encoder->encode('Hoge'), 'hOGE';
    is $encoder->decode('hOGE'), 'Hoge';

    done_testing;
};

done_testing;
