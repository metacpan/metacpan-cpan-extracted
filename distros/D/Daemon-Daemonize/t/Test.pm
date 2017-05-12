package t::Test;

use strict;
use warnings;

use File::Temp qw/ tempdir /;
use Path::Class;

sub tmpdir {
    return tempdir( CLEANUP => 1 );
}

sub shibboleth {
    my $shibboleth = $$ + substr int( rand time ), 6;
    my $dollar_0 = "d-d-test-$shibboleth";
    return ( $shibboleth, $dollar_0 );
}

sub shb_setup {
    my $tmpdir = tmpdir;
    my ( $shibboleth, $dollar_0 ) = shibboleth;
    my $shb_file = file( $tmpdir, $shibboleth )->absolute;
    return ( $tmpdir, $shibboleth, $dollar_0, $shb_file );
}

1;
