use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings;

use Courriel::Header::ContentType;

{
    my $ct = Courriel::Header::ContentType->new_from_value(
        value => 'text/plain' );

    is( $ct->value,     'text/plain', 'got expected value' );
    is( $ct->mime_type, 'text/plain', 'got expected mime_type' );
}

{
    my $ct = Courriel::Header::ContentType->new_from_value(
        name  => 'content-type',
        value => 'text/plain',
    );

    is( $ct->name,      'content-type', 'name from parameters is used' );
    is( $ct->mime_type, 'text/plain',   'got expected mime_type' );
}

{
    my $ct = Courriel::Header::ContentType->new_from_value(
        name  => 'content-type',
        value => 'text/plain; charset=ISO-8859-2',
    );

    is(
        $ct->attribute_value('charset'),
        'ISO-8859-2',
        'got charset attribute value'
    );

    is(
        $ct->attribute_value('nonexistent'),
        undef,
        'got nonexistent attribute value as undef'
    );
}

done_testing();
