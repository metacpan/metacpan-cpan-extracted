package Acme::AsciiEmoji;

use strict;
use warnings;
use Exporter::Shiny;

our $VERSION = '1.02';

our %EMOJI;

BEGIN {
    %EMOJI = (
        innocent    => [ 202, 152, 226, 128, 191, 202, 152 ],
        disapproval => [ 224, 178, 160, 95,  224, 178, 160 ],
        table_flip  => [
            40,  226, 149, 175, 194, 176, 226, 150, 161, 194,
            176, 239, 188, 137, 226, 149, 175, 239, 184, 181,
            32,  226, 148, 187, 226, 148, 129, 226, 148, 187
        ],
        put_the_table_back => [
            226, 148, 172, 226, 148, 128, 226, 148, 172, 227,
            131, 142, 40,  32,  227, 130, 156, 45,  227, 130,
            156, 227, 131, 142, 41
        ],
        double_flip => [
            226, 148, 187, 226, 148, 129, 226, 148, 187, 239,
            184, 181, 227, 131, 189, 40,  96,  208, 148, 194,
            180, 41,  239, 190, 137, 239, 184, 181, 226, 148,
            187, 226, 148, 129, 226, 148, 187
        ],
        super_waving => [
            40,  32,  239, 190, 159, 226, 136, 128, 239, 190, 159, 41,
            239, 189, 177, 239, 190, 138, 239, 190, 138, 229, 133, 171,
            229, 133, 171, 239, 190, 137, 227, 131, 189, 239, 190, 137,
            227, 131, 189, 239, 190, 137, 227, 131, 189, 239, 190, 137,
            32,  239, 188, 188, 32,  47,  32,  239, 188, 188, 47,  32,
            239, 188, 188
        ],
        fistacuffs => [
            225, 131, 154, 40,  239, 189, 128, 227,
            131, 188, 194, 180, 225, 131, 154, 41
        ],
        cute_bear =>
          [ 202, 149, 226, 128, 162, 225, 180, 165, 226, 128, 162, 202, 148 ],
        big_eyes => [
            40,  239, 189, 161, 226, 151, 149, 226, 128, 191,
            226, 151, 149, 239, 189, 161, 41
        ],
        surprised => [
            239, 188, 136, 227, 128, 128, 239, 190, 159, 208,
            148, 239, 190, 159, 239, 188, 137
        ],
        shrug => [ 194, 175, 92, 95, 40, 227, 131, 132, 41, 95, 47, 194, 175 ],
        meh => [ 194, 175, 92, 40, 194, 176, 95, 111, 41, 47, 194, 175 ],
        feel_perky =>
          [ 40, 96, 239, 189, 165, 207, 137, 239, 189, 165, 194, 180, 41 ],
        angry => [
            40,  226, 149, 172, 32,  224, 178, 160,
            231, 155, 138, 224, 178, 160, 41
        ],
        excited => [
            226, 152, 156, 40,  226, 140, 146, 32,  226, 150,
            189, 226, 140, 146, 32,  41,  226, 152, 158
        ],
        running => [
            206, 181, 61, 206, 181, 61,  206, 181, 61, 226, 148, 140,
            40,  59,  42, 194, 180, 208, 148, 96,  41, 239, 190, 137
        ],
        happy => [ 227, 131, 189, 40, 194, 180, 226, 150, 189, 32, 96, 41, 47 ],
        basking_in_glory => [
            227, 131, 189, 40,  194, 180, 227, 131,
            188, 239, 189, 128, 41,  227, 131, 142
        ],
        kitty => [ 225, 181, 146, 225, 180, 165, 225, 181, 146, 35 ],
        meow  => [
            224, 184, 133, 94, 226, 128, 162, 239, 187, 140,
            226, 128, 162, 94, 224, 184, 133
        ],
        cheers => [
            239, 188, 136, 32,  94,  95,  94,  239, 188, 137,
            111, 232, 135, 170, 232, 135, 170, 111, 239, 188,
            136, 94,  95,  94,  32,  239, 188, 137
        ],
        chan => [
            40,  32, 205, 161, 194, 176, 32, 205, 156, 202,
            150, 32, 205, 161, 194, 176, 41
        ],
        disagree =>
          [ 217, 169, 226, 151, 148, 204, 175, 226, 151, 148, 219, 182 ],
        flexing => [
            225, 149, 153, 40,  226, 135, 128, 226, 128, 184,
            226, 134, 188, 226, 128, 182, 41,  225, 149, 151
        ],
        do_you_lift_bro => [
            225, 149, 166, 40, 195, 178, 95, 195,
            179, 203, 135, 41, 225, 149, 164
        ],
        kirby => [
            226, 138, 130, 40, 226, 151, 137, 226, 128, 191,
            226, 151, 137, 41, 227, 129, 164
        ],
        tripping_out =>
          [ 113, 40, 226, 157, 130, 226, 128, 191, 226, 157, 130, 41, 112 ],
        discombobulated => [ 226, 138, 153, 239, 185, 143, 226, 138, 153 ],
        sad_shrug       => [
            194, 175, 92,  95,  40,  226, 138, 153, 32,  239,
            184, 191, 226, 138, 153, 41,  95,  47,  194, 175
        ],
        confused =>
          [ 194, 191, 226, 147, 167, 95, 226, 147, 167, 239, 174, 140 ],
        confused_scratch => [ 40, 226, 138, 153, 46, 226, 152, 137, 41, 55 ],
        worried => [ 40, 194, 180, 239, 189, 165, 95, 239, 189, 165, 96, 41 ],
        dear_god_why => [
            209, 137, 239, 188, 136, 239, 190, 159, 208, 148,
            239, 190, 159, 209, 137, 239, 188, 137
        ],
        staring => [
            217, 169, 40,  205, 161, 224, 185, 143,
            95,  224, 185, 143, 41,  219, 182
        ],
        strut =>
          [ 225, 149, 149, 40, 32, 225, 144, 155, 32, 41, 225, 149, 151 ],
        zoned => [ 40, 226, 138, 153, 95, 226, 151, 142, 41 ],
        crazy => [
            227, 131, 159, 226, 151, 143, 239, 185,
            143, 226, 152, 137, 227, 131, 159
        ],
        trolling => [
            32, 224, 188, 188, 226, 136, 181, 224, 188, 189,
            32, 224, 188, 188, 226, 141, 168, 224, 188, 189,
            32, 224, 188, 188, 226, 141, 162, 224, 188, 189,
            32, 224, 188, 188, 226, 141, 164, 224, 188, 189
        ],
        angry_troll => [
            227, 131, 189, 224, 188, 188, 32,  224, 178, 160, 231, 155,
            138, 224, 178, 160, 32,  224, 188, 189, 239, 190, 137
        ],
        hugger => [
            40,  227, 129, 165, 239, 191, 163, 32, 194, 179,
            239, 191, 163, 41,  227, 129, 165
        ],
        stranger_danger => [
            40,  227, 129, 165, 239, 189, 161, 226, 151, 149,
            226, 128, 191, 226, 128, 191, 226, 151, 149, 239,
            189, 161, 41,  227, 129, 165
        ],
        flip_friend => [
            40,  227, 131, 142, 224, 178, 160, 32,  226, 136, 169, 224,
            178, 160, 41,  227, 131, 142, 229, 189, 161, 40,  32,  92,
            111, 194, 176, 111, 41,  92,  32
        ],
        cry => [
            239, 189, 161, 239, 190, 159, 40,  32,  239, 190,
            159, 224, 174, 135, 226, 128, 184, 224, 174, 135,
            239, 190, 159, 41,  239, 190, 159, 239, 189, 161
        ],
        tgif => [
            226, 128, 156, 227, 131, 189, 40,  194, 180, 226, 150, 189,
            239, 189, 128, 41,  227, 131, 142, 226, 128, 157
        ],
        dancing => [
            226, 148, 140, 40,  227, 134, 134, 227,
            137, 168, 227, 134, 134, 41,  202, 131
        ],
        sleepy => [ 235, 136, 136, 95, 235, 136, 136 ],
        shy    => [
            40,  224, 185, 145, 226, 128, 162, 204, 129, 32,  226, 130,
            131, 32,  226, 128, 162, 204, 128, 224, 185, 145, 41
        ],
        fly_away => [
            226, 129, 189, 226, 129, 189, 224, 172, 152, 40,
            32,  203, 138, 225, 181, 149, 203, 139, 32,  41,
            224, 172, 147, 226, 129, 190, 226, 129, 190
        ],
        careless => [ 226, 151, 148, 95,  226, 151, 148 ],
        love     => [ 226, 153, 165, 226, 128, 191, 226, 153, 165 ],
        touchy => [
            212, 133, 40,  226, 137, 150, 226, 128,
            191, 226, 137, 150, 212, 133, 41
        ],
        robot =>
          [ 123, 226, 128, 162, 204, 131, 95, 226, 128, 162, 204, 131, 125 ],
        seal         => [ 40, 225, 181, 148, 225, 180, 165, 225, 181, 148, 41 ],
        questionable => [ 40, 212, 190, 226, 128, 184, 32,  212, 190, 41 ],
        winning      => [
            40,  226, 128, 162, 204, 128, 225, 180, 151, 226, 128, 162,
            204, 129, 41,  217, 136, 32,  204, 145, 204, 145
        ],
        zombie   => [ 91, 194, 172, 194, 186, 45, 194, 176, 93, 194, 172 ],
        pointing => [
            40,  226, 152, 158, 239, 190, 159, 227, 131, 174,
            239, 190, 159, 41,  226, 152, 158
        ],
        chasing => [
            39,  39,  226, 140, 144, 40,  224, 178, 160, 219,
            190, 224, 178, 160, 41,  194, 172, 39,  39,  39
        ],
        okay              => [ 40, 32, 226, 128, 162, 95, 226, 128, 162, 41 ],
        put_sunglasses_on => [
            40,  32,  226, 128, 162, 95, 226, 128, 162, 41, 62, 226,
            140, 144, 226, 150, 160, 45, 226, 150, 160
        ],
        sunglasses =>
          [ 40, 226, 140, 144, 226, 150, 160, 95, 226, 150, 160, 41 ],
        giving_up =>
          [ 111, 40, 226, 149, 165, 239, 185, 143, 226, 149, 165, 41, 111 ],
        magical => [
            40,  239, 190, 137, 226, 151, 149, 227, 131, 174,
            226, 151, 149, 41,  239, 190, 137, 42,  58,  227,
            131, 187, 239, 190, 159, 226, 156, 167
        ],
        mustach => [ 40, 32, 203, 135, 224, 183, 180, 203, 135, 32, 41 ],
        friends => [
            40,  239, 189, 143, 227, 131, 187, 95,  227, 131, 187, 41,
            227, 131, 142, 226, 128, 157, 40,  225, 180, 151, 95,  32,
            225, 180, 151, 227, 128, 130, 41
        ],
        evil => [
            40,  229, 177, 174, 239, 189, 128, 226,
            136, 128, 194, 180, 41,  229, 177, 174
        ],
        devil =>
          [ 40, 226, 151, 163, 226, 136, 128, 226, 151, 162, 41, 207, 136 ],
        salute => [
            40, 239, 191, 163, 227, 131, 188, 239, 191, 163, 41, 227, 130, 158
        ],
        inject => [
            226, 148, 140, 40,  226, 151, 137, 32,  205, 156,
            202, 150, 226, 151, 137, 41,  227, 129, 164, 226,
            148, 163, 226, 150, 135, 226, 150, 135, 226, 150,
            135, 226, 149, 144, 226, 148, 128, 226, 148, 128
        ],
        why => [
            227, 131, 189, 40,  239, 189, 128, 226, 140, 146,
            194, 180, 227, 131, 161, 41,  227, 131, 142
        ],
        execution => [
            40,  226, 140, 144, 226, 150, 160, 95,  226, 150, 160, 41,
            239, 184, 187, 226, 149, 166, 226, 149, 164, 226, 148, 128,
            32,  40,  226, 149, 165, 239, 185, 143, 226, 149, 165, 41
        ],
        kicking => [
            227, 131, 189, 40,  32,  239, 189, 165, 226, 136,
            128, 239, 189, 165, 41,  239, 190, 137, 226, 148,
            140, 226, 148, 155, 206, 163, 40,  227, 131, 142,
            32,  96,  208, 148, 194, 180, 41,  227, 131, 142
        ],
        success => [
            226, 156, 167, 42,  239, 189, 161, 217, 169, 40,
            203, 138, 225, 151, 156, 203, 139, 42,  41,  217,
            136, 226, 156, 167, 42,  239, 189, 161
        ],
        punch => [
            226, 148, 143, 226, 148, 171, 42,  239, 189, 128, 239, 189,
            176, 194, 180, 226, 148, 163, 226, 148, 129, 226, 148, 129,
            226, 148, 129, 226, 148, 129, 226, 148, 129, 226, 148, 129,
            226, 148, 129, 226, 148, 129, 226, 148, 129, 226, 151, 143,
            41,  239, 190, 159, 79,  239, 190, 159, 41,  46,  239, 189,
            161, 239, 190, 159
        ],
        fu => [
            225, 149, 149, 226, 149, 143, 32,  205, 161, 225,
            181, 148, 32,  226, 128, 184, 32,  205, 161, 225,
            181, 148, 32,  226, 149, 143, 229, 135, 184
        ],
        vision => [ 40, 45, 40, 45, 40, 45, 95, 45, 41, 45, 41, 45, 41 ],
        eyes   => [
            226, 149, 173, 40,  226, 151, 149, 226, 151, 149, 32,  226,
            151, 137, 224, 183, 180, 226, 151, 137, 32,  226, 151, 149,
            226, 151, 149, 41,  226, 149, 174
        ],
        wall => [
            226, 148, 180, 226, 148, 172, 226, 148,
            180,   226, 148, 164, 239, 189, 165, 95,
            239,   189, 165, 226, 148, 156, 226, 148,
            180,   226, 148, 172, 226, 148, 180
        ],
    );
}

our @EXPORT    = keys %EMOJI;
our @EXPORT_OK = keys %EMOJI;

=head1 NAME

Acme::AsciiEmoji - Emoji

=head1 VERSION

Version 1.02

=cut

=encoding utf8

=head1 SYNOPSIS

    use Acme::AsciiEmoji;
    ...
    print innocent;
    # ʘ‿ʘ

=cut

=head1 EXPORT

=cut

sub ascii_emoji {
    return pack( 'C*', @{ $EMOJI{ $_[0] } } );
}

=head2 innocent

ʘ‿ʘ
Innocent face 

=cut

sub innocent {
    return ascii_emoji('innocent');
}

=head2 disapproval

ಠ_ಠ
Reddit disapproval face 

=cut

sub disapproval {
    return ascii_emoji('disapproval');
}

=head2 table_flip

(╯°□°）╯︵ ┻━┻
Table Flip / Flipping Table 

=cut

sub table_flip {
    return ascii_emoji('table_flip');
}

=head2 put_the_table_back

┬─┬ ノ( ゜-゜ノ)
Put the table back

=cut

sub put_the_table_back {
    return ascii_emoji('put_the_table_back');
}

=head2 double_flip 

┻━┻ ︵ヽ(`Д´)ﾉ︵ ┻━┻
Double Flip / Double Angry

=cut

sub double_flip {
    return ascii_emoji('double_flip');
}

=head2 super_waving

( ﾟ∀ﾟ)ｱﾊﾊ八八ﾉヽﾉヽﾉヽﾉ ＼ / ＼/ ＼
Super waving

=cut

sub super_waving {
    return ascii_emoji('super_waving');
}

=head2 fistacuffs

ლ(｀ー´ლ)
Fistacuffs

=cut

sub fistacuffs {
    return ascii_emoji('fistacuffs');
}

=head2 cute_bear 

ʕ•ᴥ•ʔ
Cute bear 

=cut

sub cute_bear {
    return ascii_emoji('cute_bear');
}

=head2 big_eyes 

(｡◕‿◕｡)
Big eyes 

=cut

sub big_eyes {
    return ascii_emoji('big_eyes');
}

=head2 surprised

（　ﾟДﾟ）
surprised / loudmouthed 

=cut

sub surprised {
    return ascii_emoji('surprised');
}

=head2 shrug

¯\_(ツ)_/¯
shrug face  

=cut

sub shrug {
    return ascii_emoji('shrug');
}

=head2 meh

¯\(°_o)/¯
meh

=cut

sub meh {
    return ascii_emoji('meh');
}

=head2 feel_perky 

(`･ω･´)
feel perky  

=cut

sub feel_perky {
    return ascii_emoji('feel_perky');
}

=head2 angry 

(╬ ಠ益ಠ)
angry face

=cut

sub angry {
    return ascii_emoji('angry');
}

=head2 excited

☜(⌒▽⌒)☞
excited 

=cut

sub excited {
    return ascii_emoji('excited');
}

=head2 running

ε=ε=ε=┌(;*´Д`)ﾉ
running 

=cut

sub running {
    return ascii_emoji('running');
}

=head2 happy

ヽ(´▽`)/
happy face  

=cut

sub happy {
    return ascii_emoji('happy');
}

=head2 basking_in_glory

ヽ(´ー｀)ノ
basking in glory  

=cut

sub basking_in_glory {
    return ascii_emoji('basking_in_glory');
}

=head2 kitty

ᵒᴥᵒ#
kitty emote

=cut

sub kitty {
    return ascii_emoji('kitty');
}

=head2 meow

ฅ^•ﻌ•^ฅ
meow

=cut

sub meow {
    return ascii_emoji('meow');
}

=head2 cheers

（ ^_^）o自自o（^_^ ）
Cheers  

=cut

sub cheers {
    return ascii_emoji('cheers');
}

=head2 devious

ಠ‿ಠ
devious smile

=cut

sub devious {
    return ascii_emoji('devious');
}

=head2 chan

( ͡° ͜ʖ ͡°)
4chan emoticon  

=cut

sub chan {
    return ascii_emoji('chan');
}

=head2 disagree

٩◔̯◔۶
disagree

=cut

sub disagree {
    return ascii_emoji('disagree');
}

=head2 flexing

ᕙ(⇀‸↼‶)ᕗ
flexing 

=cut

sub flexing {
    return ascii_emoji('flexing');
}

=head2 do_you_lift_bro

ᕦ(ò_óˇ)ᕤ
do you even lift bro?

=cut

sub do_you_lift_bro {
    return ascii_emoji('do_you_lift_bro');
}

=head2 kirby

⊂(◉‿◉)つ
kirby

=cut

sub kirby {
    return ascii_emoji('kirby');
}

=head2 tripping_out

q(❂‿❂)p
tripping out  

=cut

sub tripping_out {
    return ascii_emoji('tripping_out');
}

=head2 discombobulated

⊙﹏⊙
discombobulated 

=cut

sub discombobulated {
    return ascii_emoji('discombobulated');
}

=head2 sad_shrug

¯\_(⊙︿⊙)_/¯
sad and confused  

=cut

sub sad_shrug {
    return ascii_emoji('sad_shrug');
}

=head2 confused

¿ⓧ_ⓧﮌ
confused  

=cut

sub confused {
    return ascii_emoji('confused');
}

=head2 confused_scratch

(⊙.☉)7
confused scratch

=cut

sub confused_scratch {
    return ascii_emoji('confused_scratch');
}

=head2 worried

(´･_･`)
worried

=cut

sub worried {
    return ascii_emoji('worried');
}

=head2 dear_god_why

щ（ﾟДﾟщ）
dear god why  

=cut

sub dear_god_why {
    return ascii_emoji('dear_god_why');
}

=head2 staring

٩(͡๏_๏)۶
staring 

=cut

sub staring {
    return ascii_emoji('staring');
}

=head2 strut

ᕕ( ᐛ )ᕗ
strut

=cut

sub strut {
    return ascii_emoji('strut');
}

=head2 zoned

(⊙_◎)
zoned

=cut

sub zoned {
    return ascii_emoji('zoned');
}

=head2 crazy

ミ●﹏☉ミ
crazy

=cut

sub crazy {
    return ascii_emoji('crazy');
}

=head2 trolling

༼∵༽ ༼⍨༽ ༼⍢༽ ༼⍤༽
trolling

=cut

sub trolling {
    return ascii_emoji('trolling');
}

=head2 angry_troll

ヽ༼ ಠ益ಠ ༽ﾉ
angry troll

=cut

sub angry_troll {
    return ascii_emoji('angry_troll');
}

=head2 hugger

(づ￣ ³￣)づ
hugger

=cut

sub hugger {
    return ascii_emoji('hugger');
}

=head2 stranger_danger

(づ｡◕‿‿◕｡)づ
stranger danger

=cut

sub stranger_danger {
    return ascii_emoji('stranger_danger');
}

=head2 flip_friend

(ノಠ ∩ಠ)ノ彡( \o°o)\
flip friend

=cut

sub flip_friend {
    return ascii_emoji('flip_friend');
}

=head2 cry

｡ﾟ( ﾟஇ‸இﾟ)ﾟ｡
cry face

=cut

sub cry {
    return ascii_emoji('cry');
}

=head2 tgif

“ヽ(´▽｀)ノ”
TGIF

=cut

sub tgif {
    return ascii_emoji('tgif');
}

=head2 dancing

┌(ㆆ㉨ㆆ)ʃ
dancing 

=cut

sub dancing {
    return ascii_emoji('dancing');
}

=head2 sleepy

눈_눈
sleepy

=cut

sub sleepy {
    return ascii_emoji('sleepy');
}

=head2 fly_away

⁽⁽ଘ( ˊᵕˋ )ଓ⁾⁾
fly away

=cut

sub fly_away {
    return ascii_emoji('fly_away');
}

=head2 careless

◔_◔
careless

=cut

sub careless {
    return ascii_emoji('careless');
}

=head2 love

♥‿♥
love

=cut

sub love {
    return ascii_emoji('love');
}

=head2 touch

ԅ(≖‿≖ԅ)
Touchy Feely

=cut

sub touchy {
    return ascii_emoji('touchy');
}

=head2 robot
  
{•̃_•̃}
robot

=cut

sub robot {
    return ascii_emoji('robot');
}

=head2 seal

(ᵔᴥᵔ)
seal
``
=cut

sub seal {
    return ascii_emoji('seal');
}

=head2 questionable

(Ծ‸ Ծ)
questionable / dislike

=cut

sub questionable {
    return ascii_emoji('questionable');
}

=head2 winning

(•̀ᴗ•́)و ̑̑
Winning!

=cut

sub winning {
    return ascii_emoji('winning');
}

=head2 zombie

[¬º-°]¬
Zombie

=cut

sub zombie {
    return ascii_emoji('zombie');
}

=head2 pointing

(☞ﾟヮﾟ)☞
pointing

=cut

sub pointing {
    return ascii_emoji('pointing');
}

=head2 chasing

''⌐(ಠ۾ಠ)¬'''
chasing / running away

=cut

sub chasing {
    return ascii_emoji('chasing');
}

=head2 shy 

(๑•́ ₃ •̀๑) 
shy 

=cut

sub shy {
    return ascii_emoji('shy');
}

=head2 okay

( •_•)
okay..

=cut

sub okay {
    return ascii_emoji('okay');
}

=head2 put_sunglasses_on

( •_•)>⌐■-■
Put Sunglasses on.

=cut

sub put_sunglasses_on {
    return ascii_emoji('put_sunglasses_on');
}

=head2 sunglasses 

(⌐■_■)
sunglasses

=cut

sub sunglasses {
    return ascii_emoji('sunglasses');
}

=head2 giving_up

o(╥﹏╥)o
Giving Up

=cut

sub giving_up {
    return ascii_emoji('giving_up');
}

=head2 magical

(ﾉ◕ヮ◕)ﾉ*:・ﾟ✧
Magical

=cut

sub magical {
    return ascii_emoji('magical');
}

=head2 mustach

( ˇ෴ˇ )
Mustach

=cut

sub mustach {
    return ascii_emoji('mustach');
}

=head2 friends

(ｏ・_・)ノ”(ᴗ_ ᴗ。)
Friends

=cut

sub friends {
    return ascii_emoji('friends');
}

=head2 evil

(屮｀∀´)屮
Evil

=cut

sub evil {
    return ascii_emoji('evil');
}

=head2 devil

(◣∀◢)ψ
Devil

=cut

sub devil {
    return ascii_emoji('devil');
}

=head2 salute

(￣ー￣)ゞ
Salute

=cut

sub salute {
    return ascii_emoji('salute');
}

=head2 inject

┌(◉ ͜ʖ◉)つ┣▇▇▇═──
inject

=cut

sub inject {
    return ascii_emoji('inject');
}

=head2 why 

ヽ(｀⌒´メ)ノ
why

=cut

sub why {
    return ascii_emoji('why');
}

=head2 execution

(⌐■_■)︻╦╤─ (╥﹏╥)
execution

=cut

sub execution {
    return ascii_emoji('execution');
}

=head2 kicking

ヽ( ･∀･)ﾉ┌┛Σ(ノ `Д´)ノ
kicking

=cut

sub kicking {
    return ascii_emoji('kicking');
}

=head2 success

✧*｡٩(ˊᗜˋ*)و✧*｡
yay

=cut

sub success {
    return ascii_emoji('success');
}

=head2 punch

┏┫*｀ｰ´┣━━━━━━━━━●)ﾟOﾟ).｡ﾟ
punch

=cut

sub punch {
    return ascii_emoji('punch');
}

=head2 fu

ᕕ╏ ͡ᵔ ‸ ͡ᵔ ╏凸
*fu*

=cut

sub fu {
    return ascii_emoji('fu');
}

=head2 vision

(-(-(-_-)-)-)
vision

=cut

sub vision {
    return ascii_emoji('vision');
}

=head2 eyes

╭(◕◕ ◉෴◉ ◕◕)╮
eyes

=cut

sub eyes {
    return ascii_emoji('eyes');
}

=head2 wall

┴┬┴┤･_･├┴┬┴
wall

=cut

sub wall {
    return ascii_emoji('wall');
}

=head1 AUTHOR

Robert Acock, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-asciiemoji at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-AsciiEmoji>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::AsciiEmoji


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-AsciiEmoji>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-AsciiEmoji>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-AsciiEmoji>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-AsciiEmoji/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2017->2020 LNATION.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;    # End of Acme::AsciiEmoji
