use warnings;
use strict;
use Test::More tests => 2;
use CPAN::Nearest 'search';

my $file = "$ENV{HOME}/.cpan/sources/modules/02packages.details.txt.gz";
SKIP: {
    skip "no package file to search", 2 unless -f $file;
    my $module = search ($file, "Shine on you crazy diamond! " x 3);
    ok (! defined $module, "Silly file name returns undef");
#    note ($module);
    $module = search ($file, "Lingua::JX::Mojo");
    ok ($module eq 'Lingua::JA::Moji', "Got a real name");
}


# Local variables:
# mode: perl
# End:
