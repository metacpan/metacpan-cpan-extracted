use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;
use File::Spec;

my $lib = File::Spec->rel2abs('lib');
my $bin = File::Spec->rel2abs('script/optex');

is(optex(), 2);

$ENV{PATH} = "/bin:/usr/bin";
is(optex('true'),  0);
is(optex('false'), 1);

done_testing;

sub optex {
    system($^X, "-I$lib", $bin, @_) >> 8;
}
