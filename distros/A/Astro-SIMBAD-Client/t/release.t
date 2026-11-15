package main;

use strict;
use warnings;

use lib qw{ inc };

use My::Module::Test;

my $server = access();
call( set => server => $server );

foreach my $scheme ( @TEST_SCHEMES ) {

    subtest "Get release information from $server under $scheme" => sub {

	have_scheme( $scheme )
	    or plan skip_all => "$scheme not installed";

	call( set => scheme => $scheme );

	TODO: {

	    # local $TODO = 'Release information missing as of September 6 2016';

	    call( 'release' );
	    test( qr{ \A SIMBAD4 \b }smxi, 'Scalar release()' );

	    call_a( 'release' );
	    deref( 0 );
	    test( 4, 'Major version number' );

	}
    };

}

{
    my $smb = object();
    diag join ': ', $smb->__build_url(), scalar $smb->release();
}

end();


1;

# ex: set filetype=perl textwidth=72 :
