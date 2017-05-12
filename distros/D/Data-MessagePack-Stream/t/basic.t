use strict;
use warnings;
use Test::More;

use Data::MessagePack;
use Data::MessagePack::Stream;
use Encode ();

my $mp = Data::MessagePack->new;

{
    my $stream = Data::MessagePack::Stream->new;
    isa_ok $stream, 'Data::MessagePack::Stream';

    $stream->feed( $mp->encode('foo') );
    $stream->feed( $mp->encode('bar') );
    $stream->feed( $mp->encode(1) );
    $stream->feed( $mp->encode(2) );
    $stream->feed( $mp->encode(3) );
    $stream->feed( $mp->encode([qw/a b c/]) );
    $stream->feed( $mp->encode({ foo => 'bar' }) );

    ok !$stream->data, 'no data unless calling next';

    ok $stream->next, 'next ok';
    is $stream->data, 'foo';
    ok $stream->next, 'next ok';
    is $stream->data, 'bar';
    ok $stream->next, 'next ok';
    is $stream->data, 1;
    ok $stream->next, 'next ok';
    is $stream->data, 2;
    ok $stream->next, 'next ok';
    is $stream->data, 3;
    ok $stream->next, 'next ok';
    is_deeply $stream->data, [qw/a b c/];
    ok $stream->next, 'next ok';
    is_deeply $stream->data, { foo => 'bar' };

    ok !$stream->next, 'no more data ok';
}

{
    my $stream = Data::MessagePack::Stream->new;

    my $buf;
    $buf .= $mp->encode('hoge') for 1 .. 100;

    my $count = 0;
    for my $b (split '', $buf) {
        $stream->feed($b);

        while ($stream->next) {
            $count++;
            is $stream->data, 'hoge', 'data ok';
        }
    }

    is $count, 100, 'decoded count ok';
}

{
    # New specification: Str type
    my $utf8_mp = Data::MessagePack->new->utf8;

    my $stream = Data::MessagePack::Stream->new;

    $stream->feed( $utf8_mp->encode(Encode::decode_utf8("あいうえお")));
    ok $stream->next, 'next ok';
    is $stream->data, Encode::decode_utf8("あいうえお");
    ok !$stream->next, 'no more data ok';
}

done_testing;
