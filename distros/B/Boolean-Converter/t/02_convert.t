use strict;
use warnings;
use utf8;

use Test::More;
use Boolean::Converter;
use JSON::PP;

my $converter = Boolean::Converter->new;

subtest 'JSON::PP' => sub {
    ok +$converter->can_convert_to('JSON::PP');
    ok +$converter->convert_to(JSON::PP::true, 'JSON::PP');
    ok !$converter->convert_to(JSON::PP::false, 'JSON::PP');
    isa_ok $converter->convert_to(JSON::PP::true(), 'JSON::PP'), ref JSON::PP::true();

    subtest 'premitive value' => sub {
        ok +$converter->convert_to(1, 'JSON::PP');
        ok !$converter->convert_to(0, 'JSON::PP');
        isa_ok $converter->convert_to(1, 'JSON::PP'), ref JSON::PP::true();
    };

    subtest 'custom converter' => sub {
        my $converter = Boolean::Converter->new(converter => { 'SCALAR' => sub { $_[0] ? \1 : \0 } });
        is ${$converter->convert_to(1, 'SCALAR')}, 1;
        is ${$converter->convert_to(0, 'SCALAR')}, 0;
        isa_ok $converter->convert_to(1, 'SCALAR'), 'SCALAR';
    };

};

if (eval { require JSON::XS; 1 }) {
    subtest 'JSON::XS' => sub {
        ok +$converter->can_convert_to('JSON::XS');
        ok +$converter->convert_to(JSON::PP::true(), 'JSON::XS');
        ok !$converter->convert_to(JSON::PP::false(), 'JSON::XS');
        isa_ok $converter->convert_to(JSON::PP::true(), 'JSON::XS'), ref JSON::XS::true();
    };
}

if (eval { require Data::MessagePack; 1 }) {
    subtest 'Data::MessagePack' => sub {
        ok +$converter->can_convert_to('Data::MessagePack');
        ok +$converter->convert_to(JSON::PP::true(), 'Data::MessagePack');
        ok !$converter->convert_to(JSON::PP::false(), 'Data::MessagePack');
        isa_ok $converter->convert_to(JSON::PP::true(), 'Data::MessagePack'), ref Data::MessagePack::true();
    };
}

if (eval { require boolean; 1 }) {
    subtest 'boolean' => sub {
        ok +$converter->can_convert_to('boolean');
        ok +$converter->convert_to(JSON::PP::true(), 'boolean');
        ok !$converter->convert_to(JSON::PP::false(), 'boolean');
        isa_ok $converter->convert_to(JSON::PP::true(), 'boolean'), ref boolean::true();
    };
}

if (eval { require Types::Serialiser; 1 }) {
    subtest 'Types::Serialiser' => sub {
        ok +$converter->can_convert_to('Types::Serialiser');
        ok +$converter->convert_to(JSON::PP::true(), 'Types::Serialiser');
        ok !$converter->convert_to(JSON::PP::false(), 'Types::Serialiser');
        isa_ok $converter->convert_to(JSON::PP::true(), 'Types::Serialiser'), ref Types::Serialiser::true();
    };
}

done_testing;
