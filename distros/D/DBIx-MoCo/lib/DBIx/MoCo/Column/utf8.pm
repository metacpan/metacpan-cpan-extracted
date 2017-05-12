package DBIx::MoCo::Column::utf8;
use strict;
use warnings;

BEGIN {
    if ($] <= 5.008000) {
        require Encode;
    } else {
        require utf8;
    }
}

sub utf8 {
    my $self = shift;
    my $v = $$self;
    if ($] <= 5.008000) {
        Encode::_utf8_on($v) unless Encode::is_utf8($v);
    } else {
        utf8::decode($v) unless utf8::is_utf8($v);
    }
    return $v;
}

sub utf8_as_string {
    my $class = shift;
    my $v = shift or return;
    if ($] <= 5.008000) {
        Encode::_utf8_off($v) if Encode::is_utf8($v);
    } else {
        utf8::encode($v) if utf8::is_utf8($v);
    }
    return $v;
}

1;

