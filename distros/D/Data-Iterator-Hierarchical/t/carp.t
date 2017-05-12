#!perl

# Right errors for bad things

# Mmmm... perhaps I should be checking for more!

use Test::More tests => 3;
use strict;
use warnings;

use Data::Iterator::Hierarchical;

my $sth = [
    [ 1, 1, 999 ],
    [ 2, 2, 2 ],
    [ bless {}, 'Data::Iterator::Hierarchical::Test' ],
    ];

my $it = hierarchical_iterator($sth);


ok(!eval { $it->(); 1 },'dies in void context');

$@='';
ok(!eval { my $q = $it->(); 1 },'dies in scalar context');
like($@,qr/non-LIST context/,'"non-LIST context" error');
