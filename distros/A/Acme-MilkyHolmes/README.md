[![Build Status](https://travis-ci.org/tsucchi/p5-Acme-MilkyHolmes.svg?branch=master)](https://travis-ci.org/tsucchi/p5-Acme-MilkyHolmes) [![Coverage Status](https://img.shields.io/coveralls/tsucchi/p5-Acme-MilkyHolmes/master.svg?style=flat)](https://coveralls.io/r/tsucchi/p5-Acme-MilkyHolmes?branch=master)
# NAME

Acme::MilkyHolmes - There's more than one way to do it!(SEIKAI HA HITOTSU! JANAI!!)

# SYNOPSIS

    use strict;
    use warnings;
    use utf8;
    use Acme::MilkyHolmes;

    # fetch members of Milky Holmes(eg/say.pl)
    my ($sherlock, $nero, $elly, $cordelia) = Acme::MilkyHolmes->members();
    $sherlock->say('ってなんでですかー');
    $nero->say('僕のうまうま棒〜');
    $elly->say('恥ずかしい...');
    $cordelia->say('私の...お花畑...');

    # create character instance directly
    my $sherlock = Acme::MilkyHolmes::Character::SherlockShellingford->new();
    $sherlock->locale('en');
    $sherlock->name;               # => 'Sherlock Shellingford'
    $sherlock->firstname;          # => 'Sherlock'
    $sherlock->familyname;         # => 'Shellingford'
    $sherlock->nickname;           # => 'Sheryl'
    $sherlock->birthday;           # => 'March 31'
    $sherlock->voiced_by;          # => 'Suzuko Mimori'
    $sherlock->nickname_voiced_by; # => 'mimorin'
    $sherlock->toys;               # => 'Psychokinesis'
    $sherlock->color;              # => 'pink'

    # fetch each team members
    use Acme::MilkyHolmes qw($MilkyHolmes $MilkyHolmesFeathers $MilkyHolmesSisters);
    my ($sherlock, $nero, $elly, $cordelia) = Acme::MilkyHolmes->members_of($MilkyHolmes); # same as members()
    my ($kazumi, $alice) = Acme::MilkyHolmes->members_of($MilkyHolmesFeathers);
    my ($sherlock, $nero, $elly, $cordelia, $kazumi, $alice) = Acme::MilkyHolmes->members_of($MilkyHolmesSisters);

# DESCRIPTION

Milky Holmes is one of the most famous Japanese TV animation. Acme::MilkyHolmes provides character information of Milky Holmes.

# METHODS

## `members(%options)`

options: `$options{locale} = ja,en` default is ja

    my @members = Acme::MilkyHolmes->members(locale => en);

fetch Milky Holmes members. See SYNOPSIS.

## `members_of($member_name_const, %options)`

options: `$options{locale} = ja,en` default is ja

fetch members specified in `$member_name_const`. See SYNOPSIS and EXPORTED CONSTANTS

# EXPORTED CONSTANTS

- `$MilkyHolmes` : members of Milky Holmes (Sherlock, Nero, Elly and Cordelia).
- `$MilkyHolmesFeathers` : members of Milky Holmes Feathers (Kazumi and Alice).
- `$MilkyHolmesSisters` : members of Milky Holmes Sisters (Sherlock, Nero, Elly, Cordelia, Kazumi and Alice)

# SEE ALSO

- Milky Holmes Official Site

    [http://milky-holmes.com/](http://milky-holmes.com/)

- Project Milky Holmes (Wikipedia - ja)

    [http://ja.wikipedia.org/wiki/%E3%83%9F%E3%83%AB%E3%82%AD%E3%82%A3%E3%83%9B%E3%83%BC%E3%83%A0%E3%82%BA](http://ja.wikipedia.org/wiki/%E3%83%9F%E3%83%AB%E3%82%AD%E3%82%A3%E3%83%9B%E3%83%BC%E3%83%A0%E3%82%BA)

- Milky Holmes (Wikipedia - en)

    [http://en.wikipedia.org/wiki/Tantei\_Opera\_Milky\_Holmes](http://en.wikipedia.org/wiki/Tantei_Opera_Milky_Holmes)

# LICENSE

Copyright (C) Takuya Tsuchida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takuya Tsuchida <tsucchi@cpan.org>
