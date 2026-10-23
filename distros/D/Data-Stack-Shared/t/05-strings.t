use strict;
use warnings;
use Test::More;
use Data::Stack::Shared;

sub byte_length { use bytes; length $_[0] }

my $text = "A\x{e9}\x{20ac}\x{1f642}Z";
for my $limit (1 .. byte_length($text)) {
    my $s = Data::Stack::Shared::Str->new(undef, 1, $limit);
    my $expected = $text;
    chop $expected while byte_length($expected) > $limit;
    for my $push (qw(push push_wait)) {
        ok $s->$push($text), "$push with byte limit $limit";
        for my $read (qw(peek pop_wait)) {
            my $got = $s->$read;
            ok utf8::valid($got), "$read returns valid UTF-8 at limit $limit";
            is $got, $expected, "$read keeps complete characters at limit $limit";
        }
    }
}

my $s = Data::Stack::Shared::Str->new(undef, 1, 2);
for my $push (qw(push push_wait)) {
    $s->$push("\x{1f642}");
    is $s->pop, '', "$push drops a character that cannot fit";
    my $bytes = "\xe2\x82\xac";
    $s->$push($bytes);
    my $got = $s->pop;
    is $got, substr($bytes, 0, 2), "$push truncates binary data by bytes";
    ok !utf8::is_utf8($got), 'binary data stays unflagged';
}

done_testing;
