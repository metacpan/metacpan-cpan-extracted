use strict;
use warnings;
use utf8;
use Test::More;
#use Test::Requires 'Version::Next';
use t::Util;
use File::Spec;
use File::Path;
use File::pushd;

my $lib = File::Spec->rel2abs('lib');
my $bin = File::Spec->rel2abs('script/optex');

is(optex(), 2<<8);
is(optex('date'), 0);

done_testing;

sub optex {
    system($^X, "-I$lib", $bin, @_);
}
