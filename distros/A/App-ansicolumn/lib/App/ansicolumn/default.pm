package App::ansicolumn::default;

use v5.14;
use warnings;
use utf8;

App::ansicolumn::Border->add_style(
    star   => { center => [ "★ ", "☆ " ] },
    square => { center => [ "■ ", "□ " ] },
    );

1;

__DATA__

option --board-color --bs=inner-box --cm=BORDER=Z$<2>,TEXT=$<shift>/$<shift>

option --white-board --board-color 000 L24
option --black-board --board-color 555 L05
option --green-board --board-color 555 (30,77,43)
option --slate-board --board-color 555 <dark_slategray>
