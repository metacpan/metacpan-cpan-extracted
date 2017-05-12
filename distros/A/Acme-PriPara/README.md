[![Build Status](https://travis-ci.org/htk291/p5-Acme-PriPara.png?branch=master)](https://travis-ci.org/htk291/p5-Acme-PriPara) [![Coverage Status](https://coveralls.io/repos/htk291/p5-Acme-PriPara/badge.png?branch=master)](https://coveralls.io/r/htk291/p5-Acme-PriPara?branch=master)
# NAME

Acme::PriPara - It's new $module

# SYNOPSIS

    use Acme::PriPara;

    my ($laara, $mirei, $sophy, $sion, $dorothy, $reona) = Acme::PriPara->main_members;

    print $laara->name;            # => 真中 らぁら
    print $laara->firstname;       # => らぁら
    print $laara->lastname;        # => 真中
    print $laara->age;             # => 10
    print $laara->birthday;        # => 11/20
    print $laara->blood_type;      # => O
    print $laara->cv;              # => 茜屋日海夏
    print $laara->say;             # => かしこま！

    $laara->pripara_change;        # => $laara get into PriPara world
    print $laara->costume_brand;   # => Twinkle Ribbon
    print $laara->color;           # => ピンク

# DESCRIPTION

SEE CONCEPT AT [https://github.com/htk291/p5-Acme-PriPara/blob/master/etc/90\_concept.t](https://github.com/htk291/p5-Acme-PriPara/blob/master/etc/90_concept.t)

PriPara is a famous Japanese animation.  
Acme::PriPara provides characters information of PriPara.

# SEE ALSO

- PriPara Official Site

    [http://www.takaratomy-arts.co.jp/specials/pripara/](http://www.takaratomy-arts.co.jp/specials/pripara/)

- プリパラ (Wikipedia - ja)

    [http://ja.wikipedia.org/wiki/%E3%83%97%E3%83%AA%E3%83%91%E3%83%A9](http://ja.wikipedia.org/wiki/%E3%83%97%E3%83%AA%E3%83%91%E3%83%A9)

- PriPara (Wikipedia - en)

    [http://en.wikipedia.org/wiki/PriPara](http://en.wikipedia.org/wiki/PriPara)

# LICENSE

Copyright (C) htk291.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

htk291 <htk291@gmail.com>
