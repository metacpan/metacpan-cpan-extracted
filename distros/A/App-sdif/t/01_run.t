use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;

my $lib       = File::Spec->rel2abs('lib');
my $script    = File::Spec->rel2abs('script');
my $sdif      = "$script/sdif";
my $cdif      = "$script/cdif";
my $watchdiff = "$script/watchdiff";

$ENV{PATH} .= ":$script";
$ENV{PERL5LIB} .= ":$lib";

for my $data (qw(t/DIFF.out t/DIFF-c.out t/DIFF-u.out t/DIFF-graph.out)) {
    is(sdif('-W160', $data), 0);
    is(cdif($data), 0);
}

is(sdif('--colortable'), 0);

done_testing;

sub sdif      { system($^X, "-I$lib", $sdif, @_) }
sub cdif      { system($^X, "-I$lib", $cdif, @_) }
sub watchdiff { system($^X, "-I$lib", $watchdiff, @_) }
