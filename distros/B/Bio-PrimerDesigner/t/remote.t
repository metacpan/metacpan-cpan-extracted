#!/usr/bin/perl

# $Id: remote.t,v 1.4 2003/08/05 22:43:22 kclark Exp $

#
# Tests specific to "Bio::PrimerDesigner::Remote."
#

use strict;
use Test::More tests => 5;

use_ok( 'Bio::PrimerDesigner::Remote' );

my $rem = Bio::PrimerDesigner::Remote->new;
isa_ok( $rem, 'Bio::PrimerDesigner::Remote' );

is( $rem->CGI_request, undef, 'Remote croaks with no args' );
like( $rem->error, qr/no url specified/i, 'Error because no URL' );

ok(
    $rem->CGI_request( 
        'dev.wormbase.org/db/seq/primer_designer.cgi',
    	{ program => 'primer3' }
	),
    'Call to remote server'
);
