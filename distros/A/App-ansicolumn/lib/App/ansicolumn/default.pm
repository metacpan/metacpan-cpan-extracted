package App::ansicolumn::default;

use v5.14;
use utf8;

App::ansicolumn::Border->add_style(
    star   => { center => [ "★ ", "☆ " ] },
    square => { center => [ "■ ", "□ " ] },
    );

1;

__DATA__
