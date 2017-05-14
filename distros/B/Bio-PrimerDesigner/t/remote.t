#!/usr/bin/perl

# $Id: remote.t 16 2008-11-07 02:44:52Z kyclark $

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
        'mckay.cshl.edu/cgi-bin/primer_designer.cgi',
    	{ program => 'primer3' }
	),
    'Call to remote server'
);
