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
# construct the iterator
#-----------------------------------------------------------------------
my $iterator = $history->release_iterator();

ok(defined($iterator), 'create release iterator');

#-----------------------------------------------------------------------
# Construct a string with info
#-----------------------------------------------------------------------
my $expected = <<"END_EXPECTED";
undef 1333072261 2012-03-30 5091
CPAN-Testers-Reports-Counts 1391031339 2014-01-29 10152
CPAN-Testers-Reports-Counts 1391249171 2014-02-01 10256
Text-Markdown-PerlExtensions 1389461809 2014-01-11 10951
URI-Find-Simple 1391373778 2014-02-02 3705
URI-Find-Simple 1391559594 2014-02-05 4050
again 1361653712 2013-02-23 3451
again 1380637862 2013-10-01 3862
again 1390993459 2014-01-29 4035
END_EXPECTED

my $string = '';

while (my $release = $iterator->next_release) {
    $string .= ($release->distinfo->dist || 'undef')
               .' '
               .$release->timestamp
               .' '
               .$release->date
               .' '
               .$release->size
               ."\n";
}

is($string, $expected, "rendered history details");

