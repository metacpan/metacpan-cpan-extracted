use strict;
use warnings;

use Test::More 0.98 tests => 1;
use Directory::Iterator;

subtest "plain" => sub {
    plan tests => 9;
    my $list = Directory::Iterator->new('t/scripts/02');
    while ( $list->next ) {
        my $file = $list->get;
        my $done = qx"$^X script/findeps -L t/lib $file";
        chomp $done;
        is $done, 'Acme::BadExample', "succeed to detect only 'Acme::BadExample' in $file";
    }
};

# To Do
# extends and with are prrovided by Mouse, Moose and Moo
# Plack::Builder imports modules like Plack::Middleware::* with enable

done_testing;
