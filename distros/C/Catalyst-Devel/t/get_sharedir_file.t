use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;

use Catalyst::Helper;

my $i = bless {}, 'Catalyst::Helper';

like exception {
    $i->get_sharedir_file(qw/does not exist and hopefully never will or we are
        totally screwed.txt/);
}, qr/Cannot find/, 'Exception for file not found from ->get_sharedir_file';

is exception {
    ok($i->get_sharedir_file('Makefile.PL.tt'), 'has contents');
}, undef, 'Can get_sharedir_file';

done_testing;
