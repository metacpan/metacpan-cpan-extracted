package MySubclass;

use strict;
use warnings;
use utf8;
use FindBin '$RealBin';
use lib '.';

use Moo;

extends 'MyClass';

sub bar {
    return {
        русский  => "доверяй, но проверяй",
        i中文    => "也許你的生活很有趣",
        Ελληνικά => "ἓν οἶδα ὅτι οὐδὲν οἶδα",
    };
}

1; # return true
__END__