#!perl -w

use strict;
use warnings;
use lib './lib';
use vars qw( $DEBUG );
$DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
# use Test::More qw(plan ok);
use Test::More;

plan tests => 2;

use Data::Pretty qw(dump);
local $Data::Pretty::DEBUG = $DEBUG;

my $s = \\1;
is(nl(dump($s)), <<'EOT');
\\1
EOT

my %s;
$s{C1} = \$s{C2};
$s{C2} = \$s{C1};
is(nl(dump(\%s)), <<'EOT');
do {
    my $a = { C1 => \\do{my $fix}, C2 => 'fix' };
    ${${$a->{C1}}} = $a->{C1};
    $a->{C2} = ${$a->{C1}};
    $a;
}
EOT

sub nl { shift(@_) . "\n" }
