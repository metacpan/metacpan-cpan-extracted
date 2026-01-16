[![Actions Status](https://github.com/youpong/App-Gimei/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/youpong/App-Gimei/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/App-Gimei.svg)](https://metacpan.org/release/App-Gimei)
# NAME

App::Gimei - A CLI app for Data::Gimei, a module generating fake
Japanese names and addresses.

# SYNOPSIS

    > gimei [OPTIONS] [ARGS]

    > gimei
    松島 孝太
    > gimei name:kanji name:katakana name:romaji
    谷川 加愛, タニガワ クレア, Kurea Tanigawa
    > gimei -sep '/' address:prefecture:kanji address:town:kanji
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

    WORD_TYPE [: WORD_SUBTYPE] [: RENDERING]

    WORD_TYPE:               'name' or 'address'
    WORD_SUBTYPE('name'):    'last', 'first' or 'sex'
    WORD_SUBTYPE('address'): 'prefecture', 'city' or 'town'
    RENDERING:               'kanji', 'hiragana', 'katakana' or 'romaji'

- WORD\_TYPE 'address' does not support RENDERING romaji.
- WORD\_SUBTYPE('name') 'sex' ignore RENDERING.

# DESCRIPTION

App::Gimei is a command-line tool for Data::Gimei, a module that generates fake
Japanese names and addresses.
Generated names include a first name, a last name, and their associated gender. Names
are available in kanji, hiragana, katakana, and romanized forms, where hiragana, 
katakana, and romanized forms are phonetic renderings for kanji.
Addresses include a prefecture, city, and town, and can be generated in kanji,
hiragana or katakana.
The output format can be customized using specific options. Note that the gender
notation cannot be changed.

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

Copyright (c) 2022-2026 Yusaku Nakajima.

This library is free software; you can redistribute it and/or modify
it under the terms of the MIT License.

# AUTHOR

NAKAJIMA Yusaku <youpong@cpan.org>
