package MyClass;

use strict;
use warnings;
use utf8;
use FindBin '$RealBin';
use lib "$RealBin/../lib";

use Data::Dumper::AutoEncode::AsDumper;

use Moo;

sub foo {
    return {
        русский  => "доверяй, но проверяй",
        i中文    => "也許你的生活很有趣",
        Ελληνικά => "ἓν οἶδα ὅτι οὐδὲν οἶδα",
    };
}

1; # return true
__END__