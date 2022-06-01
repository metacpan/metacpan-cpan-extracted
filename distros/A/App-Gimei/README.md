[![Actions Status](https://github.com/youpong/App-Gimei/workflows/test/badge.svg)](https://github.com/youpong/App-Gimei/actions)
# NAME

App::Gimei - CLI for Data::Gimei

# SYNOPSIS

    > gimei [OPTIONS] [ARGS]

    > gimei
    松島 孝太
    > gimei name:kanji name:katakana
    谷川 加愛, タニガワ クレア
    > gimei -sep '/' address:prefecture-kanji address:town-kanji
    埼玉県/桜ケ丘町
    > gimei -n 3 name name:hiragana
    山本 公史, やまもと ひろし
    久保田 大志, くぼた たいし
    堀口 光太郎, ほりぐち こうたろう

Omitting ARGS is equivalent to specifying name:kanji.

## OPTIONS

    -sep string
        specify string used to separate fields(default: ", ").
    -n number
        display number record(s).
    -h|help
        display usage and exit.
    -v|version
        display version and exit.

## ARGS

    [WORD_TYPE] [: WORD_SUBTYPE] [- RENDERING]

    WORD_TYPE:     'name'   or 'address'
    WORD_SUBTYPE:  'last', 'first' or 'sex'
                 | 'prefecture', 'city' or 'town'
    RENDERING:     'kanji', 'hiragana', 'katakana' or 'romaji'

\- WORD\_TYPE 'address' does not support RENDERING romaji.
\- WORD\_SUBTYPE 'sex' ignore RENDERING.

# DESCRIPTION

App::Gimei is CLI for Data::Gimei generates fake data that people's name in Japanese.

# INSTALL

This app is available on CPAN. You can install this app by following the step below.

    $ cpanm App::Gimei

# DOCUMENTATION

After installing, you can find documentation for this module with the perldoc command.

    $ perldoc App::Gimei

You can also look for information at:

    GitHub Repository (report bugs here)
        https://github.com/youpong/App-Gimei

    Search CPAN
        https://metacpan.org/pod/App::Gimei

# LICENSE

MIT

# AUTHOR

NAKAJIMA Yusaku <youpong@cpan.org>
