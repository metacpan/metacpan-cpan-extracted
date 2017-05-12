#!perl

use strict;
use warnings;
use 5.006;

use Test::More 0.88 tests => 3;
use CPAN::ReleaseHistory;

#-----------------------------------------------------------------------
# construct PAUSE::Packages
#-----------------------------------------------------------------------

my $history = CPAN::ReleaseHistory->new(path => 't/mini-release-history.txt');

ok(defined($history), "instantiate CPAN::ReleaseHistory");

#-----------------------------------------------------------------------
# construct the iterator, 'well formed' releases only
#-----------------------------------------------------------------------
my $iterator = $history->release_iterator(well_formed => 1);

ok(defined($iterator), 'create release iterator');

#-----------------------------------------------------------------------
# Construct a string with info
#-----------------------------------------------------------------------
my $expected = <<"END_EXPECTED";
CPAN-Testers-Reports-Counts 1391031339 10152
CPAN-Testers-Reports-Counts 1391249171 10256
Text-Markdown-PerlExtensions 1389461809 10951
URI-Find-Simple 1391373778 3705
URI-Find-Simple 1391559594 4050
again 1361653712 3451
again 1380637862 3862
again 1390993459 4035
END_EXPECTED

my $string = '';

while (my $release = $iterator->next_release) {
    $string .= ($release->distinfo->dist || 'undef')
               .' '
               .$release->timestamp
               .' '
               .$release->size
               ."\n";
}

is($string, $expected, "rendered history details");

