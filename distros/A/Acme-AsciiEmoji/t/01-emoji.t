use strict;
use warnings;
use Test::More;

use Acme::AsciiEmoji;

sub is_emoji {
	my %args = @_;
	is($args{meth}(), $args{expected});
};

is_emoji(
    meth => \&Acme::AsciiEmoji::innocent,
    expected => 'ʘ‿ʘ',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::disapproval,
    expected => 'ಠ_ಠ',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::table_flip,
    expected => '(╯°□°）╯︵ ┻━┻',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::put_the_table_back,
    expected => '┬─┬ノ( ゜-゜ノ)',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::double_flip,
    expected => '┻━┻︵ヽ(`Д´)ﾉ︵┻━┻',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::super_waving,
    expected => '( ﾟ∀ﾟ)ｱﾊﾊ八八ﾉヽﾉヽﾉヽﾉ ＼ / ＼/ ＼',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::fistacuffs,
    expected => 'ლ(｀ー´ლ)',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::cute_bear,
    expected => 'ʕ•ᴥ•ʔ',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::big_eyes,
    expected => '(｡◕‿◕｡)',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::surprised,
    expected => '（　ﾟДﾟ）',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::shrug,
    expected => '¯\_(ツ)_/¯',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::meh,
    expected => '¯\(°_o)/¯',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::feel_perky,
    expected => '(`･ω･´)',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::angry,
    expected => '(╬ ಠ益ಠ)',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::excited,
    expected => '☜(⌒ ▽⌒ )☞',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::running,
    expected => 'ε=ε=ε=┌(;*´Д`)ﾉ',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::happy,
    expected => 'ヽ(´▽ `)/',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::basking_in_glory,
    expected => 'ヽ(´ー｀)ノ',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::kitty,
    expected => 'ᵒᴥᵒ#',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::meow,
    expected => 'ฅ^•ﻌ•^ฅ',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::cheers,
    expected => '（ ^_^）o自自o（^_^ ）',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::chan,
    expected => '( ͡° ͜ʖ ͡°)',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::disagree,
    expected => '٩◔̯◔۶',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::do_you_lift_bro,
    expected => 'ᕦ(ò_óˇ)ᕤ',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::kirby,
    expected => '⊂(◉‿◉)つ',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::tripping_out,
    expected =>'q(❂‿❂)p'
);

is_emoji(
    meth => \&Acme::AsciiEmoji::discombobulated,
    expected =>'⊙﹏⊙',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::sad_shrug,
    expected => '¯\_(⊙ ︿⊙)_/¯',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::confused,
    expected => '¿ⓧ_ⓧﮌ',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::confused_scratch,
    expected => '(⊙.☉)7',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::dear_god_why,
    expected => 'щ（ﾟДﾟщ）',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::strut,
    expected => 'ᕕ( ᐛ )ᕗ',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::zoned,
    expected => '(⊙_◎)',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::crazy,
    expected => 'ミ●﹏☉ミ',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::trolling,
    expected => ' ༼∵༽ ༼⍨༽ ༼⍢༽ ༼⍤༽'
);

is_emoji(
    meth => \&Acme::AsciiEmoji::angry_troll,
    expected => 'ヽ༼ ಠ益ಠ ༽ﾉ',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::hugger,
    expected => '(づ￣ ³￣)づ',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::stranger_danger,
    expected => '(づ｡◕‿‿◕｡)づ',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::flip_friend,
    expected => '(ノಠ ∩ಠ)ノ彡( \o°o)\ ',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::cry,
    expected => '｡ﾟ( ﾟஇ‸இﾟ)ﾟ｡',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::tgif,
    expected => '“ヽ(´▽｀)ノ”',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::dancing,
    expected => '┌(ㆆ㉨ㆆ)ʃ',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::sleepy,
    expected => '눈_눈',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::shy,
    expected => '(๑•́ ₃ •̀๑)',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::fly_away,
    expected => '⁽⁽ଘ( ˊᵕˋ )ଓ⁾⁾',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::careless,
    expected => '◔_◔',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::love,
    expected => '♥‿♥',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::touchy,
    expected => 'ԅ(≖‿≖ԅ)',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::robot,
    expected => '{•̃_•̃}',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::seal,
    expected => '(ᵔᴥᵔ)',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::questionable,
    expected => '(Ծ‸ Ծ)',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::winning,
    expected => '(•̀ᴗ•́)و ̑̑',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::zombie,
    expected => '[¬º-°]¬',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::pointing,
    expected => '(☞ﾟヮﾟ)☞',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::chasing,
    expected => "''⌐(ಠ۾ಠ)¬'''",
);

is_emoji(
    meth => \&Acme::AsciiEmoji::okay,
    expected => '( •_•)',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::put_sunglasses_on,
    expected => '( •_•)>⌐■-■',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::sunglasses,
    expected => '(⌐■_■)',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::giving_up,
    expected => 'o(╥﹏╥)o'
);

is_emoji(
    meth => \&Acme::AsciiEmoji::magical,
    expected => '(ﾉ◕ヮ◕)ﾉ*:・ﾟ✧'
);

is_emoji(
    meth => \&Acme::AsciiEmoji::mustach,
    expected => '( ˇ෴ˇ )',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::friends,
    expected => '(ｏ・_・)ノ”(ᴗ_ ᴗ。)'
);

is_emoji(
    meth => \&Acme::AsciiEmoji::evil,
    expected => '(屮｀∀´)屮',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::devil,
    expected => '(◣∀◢)ψ'
);

is_emoji(
    meth => \&Acme::AsciiEmoji::salute,
    expected => '(￣ー￣)ゞ',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::inject,
    expected => '┌(◉ ͜ʖ◉)つ┣▇▇▇═──',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::why,
    expected => 'ヽ(｀⌒´メ)ノ'
);

is_emoji(
    meth => \&Acme::AsciiEmoji::execution,
    expected => '(⌐■_■)︻╦╤─ (╥﹏╥)',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::kicking,
    expected => 'ヽ( ･∀･)ﾉ┌┛Σ(ノ `Д´)ノ',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::success,
    expected => '✧*｡٩(ˊᗜˋ*)و✧*｡',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::punch,
    expected => '┏┫*｀ｰ´┣━━━━━━━━━●)ﾟOﾟ).｡ﾟ',
);

is_emoji(
    meth => \&Acme::AsciiEmoji::fu,
    expected => 'ᕕ╏ ͡ᵔ ‸ ͡ᵔ ╏凸'
);

is_emoji(
    meth => \&Acme::AsciiEmoji::vision,
    expected => '(-(-(-_-)-)-)'
);

is_emoji(
    meth => \&Acme::AsciiEmoji::eyes,
    expected => '╭(◕◕ ◉෴◉ ◕◕)╮'
);

is_emoji(
    meth => \&Acme::AsciiEmoji::wall,
    expected => '┴┬┴┤･_･├┴┬┴',
);

done_testing();
