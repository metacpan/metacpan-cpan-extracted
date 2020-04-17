use strict;
use warnings;
use utf8;
use FindBin '$RealBin';
use lib "$RealBin/../lib";

use Data::Dumper::AutoEncode::AsDumper;

my $data = {
    русский  => "доверяй, но проверяй",
    i中文    => "也許你的生活很有趣",
    Ελληνικά => "ἓν οἶδα ὅτι οὐδὲν οἶδα",
};

warn Dumper $data;
__END__