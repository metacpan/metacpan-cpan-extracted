use v5.14;
use warnings;
use utf8;

sub get_length {
    local $_ = shift;
    s/ー$//;
    s/[ァィゥェォャュョヮ]//g; # 拗音は一字として数える
    length $_;
}

1;
