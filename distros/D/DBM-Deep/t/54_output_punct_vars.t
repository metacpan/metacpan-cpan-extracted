use strict;
use warnings FATAL => 'all';

use Test::More;
use t::common qw( new_fh );

use_ok( 'DBM::Deep' );

my ($fh, $filename) = new_fh();
ok eval {
    local $,="\t";
    my $db = DBM::Deep->new( file => $filename, fh => $fh, );
    $db->{34808} = "BVA/DIVISO";
    $db->{34887} = "PRIMARYVEN";
}, '$, causes no hiccoughs or 150MB files';


($fh, $filename) = new_fh();
ok eval {
    local $\="\n";
    my $db = DBM::Deep->new( file => $filename, fh => $fh, );
    $db->{foo} = "";
    $db->{baz} = "11111";
    $db->{foo}
        = "counterpneumonoultramicroscopicsilicovolcanoconiotically";
    $db->{baz};
}, '$\ causes no problems';

done_testing;
