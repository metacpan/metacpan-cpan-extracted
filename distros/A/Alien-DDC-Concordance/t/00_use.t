##-*- Mode: CPerl -*-
use strict;
use warnings;

use Test::More tests => 1;
use Alien::DDC::Concordance;

use Text::ParseWords qw/shellwords/;
my @libs = shellwords( Alien::DDC::Concordance->libs );

my $havelib = grep { /^-lDDCConcord$/ } @libs;
ok($havelib, 'idenitified needed library' );
