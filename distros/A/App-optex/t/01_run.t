use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;

my $t = File::Spec->rel2abs('t');
my $lib = File::Spec->rel2abs('lib');
my $bin = File::Spec->rel2abs('script/optex');


$ENV{HOME} = "$t/home";

is(optex(), 2);

$ENV{PATH} = "/bin:/usr/bin";
is(optex('true'),  0);
isnt(optex('false'), 0);

is(optex('-Mhelp', 'true'),  0);
is(optex('-MApp::optex::help', 'true'),  0);
is(optex('-Mdebug', 'true'),  0);
is(optex('-Mutil', 'true'),  0);
TODO: {
local $TODO = 'LOAD ERROR';
is(optex('-Mutil::filter', 'true'),  0);
}
is(optex('-Mutil::argv', 'true'),  0);

done_testing;

sub optex {
    system($^X, "-I$lib", $bin, @_) >> 8;
}
