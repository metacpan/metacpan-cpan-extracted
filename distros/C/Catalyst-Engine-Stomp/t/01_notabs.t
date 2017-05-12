use strict;
use warnings;

use File::Spec;
use Test::More;

if ( !-e "inc/.author" ) {
    plan skip_all => 'NoTabs test only for developers.';
}
else {
    eval { require Test::NoTabs };
    if ( $@ ) {
        plan tests => 1;
        fail( 'You must install Test::NoTabs to run 01_no_tabs.t' );
        exit;
    }
}

Test::NoTabs->import;
all_perl_files_ok(qw/lib/);

