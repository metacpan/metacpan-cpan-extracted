use strict;
use warnings;
use utf8;

use Test::More;
use Boolean::Converter;
use JSON::PP;

my $converter = Boolean::Converter->new;

subtest 'premitive value' => sub {
    ok +$converter->can_evaluate(1);
    ok +$converter->evaluate(1);
    ok !$converter->evaluate(0);
};

subtest 'custom evaluator' => sub {
    my $converter = Boolean::Converter->new(evaluator => { 'SCALAR' => sub { !!${$_[0]} } });
    ok +$converter->can_evaluate(\1);
    ok +$converter->evaluate(\1);
    ok !$converter->evaluate(\0);
};

subtest 'JSON::PP' => sub {
    ok +$converter->can_evaluate(JSON::PP::true);
    ok +$converter->can_evaluate(JSON::PP::false);
    ok +$converter->evaluate(JSON::PP::true);
    ok !$converter->evaluate(JSON::PP::false);
};

if (eval { require JSON::XS; 1 }) {
    subtest 'JSON::XS' => sub {
        ok +$converter->can_evaluate(JSON::XS::true());
        ok +$converter->can_evaluate(JSON::XS::false());
        ok +$converter->evaluate(JSON::XS::true());
        ok !$converter->evaluate(JSON::XS::false());
    };
}

if (eval { require Data::MessagePack; 1 }) {
    subtest 'Data::MessagePack' => sub {
        ok +$converter->can_evaluate(Data::MessagePack::true());
        ok +$converter->can_evaluate(Data::MessagePack::false());
        ok +$converter->evaluate(Data::MessagePack::true());
        ok !$converter->evaluate(Data::MessagePack::false());
    };
}

if (eval { require boolean; 1 }) {
    subtest 'boolean' => sub {
        ok +$converter->can_evaluate(boolean::true());
        ok +$converter->can_evaluate(boolean::false());
        ok +$converter->evaluate(boolean::true());
        ok !$converter->evaluate(boolean::false());
    };
}

if (eval { require Types::Serialiser; 1 }) {
    subtest 'Types::Serialiser' => sub {
        ok +$converter->can_evaluate(Types::Serialiser::true());
        ok +$converter->can_evaluate(Types::Serialiser::false());
        ok +$converter->evaluate(Types::Serialiser::true());
        ok !$converter->evaluate(Types::Serialiser::false());
    };
}

done_testing;
