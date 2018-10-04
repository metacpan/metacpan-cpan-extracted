package main;

use strict;
use warnings;

use lib qw{ inc };

use My::Module::Test;
use Data::Dumper;

local $Data::Dumper::Terse = 1;
local $Data::Dumper::Sortkeys = 1;

access;

load_module_or_skip_all qw{ XML::Parser XML::Parser::Lite };
load_module qw{ SOAP::Lite };
load_data 't/canned.data';

call set => type => 'vo';
call set => parser => 'vo=Parse_VO_Table';

echo <<'EOD';

Test the handling of VO Table data
EOD

foreach my $scheme ( qw{ http https } ) {

    subtest "Test using $scheme" => sub {

	have_scheme $scheme
	    or plan skip_all => "$scheme not installed";

	call set => scheme => $scheme;

	TODO: {
	    local $TODO = 'SOAP vo queries are deprecated';
	    local $SIG{__WARN__} = sub {};	# Ignore warnings.

	    echo <<'EOD';

The following tests use the query (SOAP) interface

EOD

	    silent hidden 'SOAP::Lite';
	    call query => id => 'Arcturus';
	    silent 0;

	    count;
	    test 1, 'query id Arcturus (vo) - count of tables';

	    deref 0, 'data';
	    count;
	    test 1, 'query id arcturus (vo) - count of rows';

	    deref 0, data => 0, 0, 'value';
	    test canned( arcturus => 'name' ), 'query id Arcturus (vo) - name';

	    deref 0, data => 0, 2, 'value';
	    test canned( arcturus => 'ra' ), 'query id Arcturus (vo) - right ascension';

	    deref 0, data => 0, 3, 'value';
	    test canned( arcturus => 'dec' ), 'query id Arcturus (vo) - declination';

	    deref 0, data => 0, 4, 'value';
	    test canned( arcturus => 'plx' ), 'query id Arcturus (vo) - parallax';

	    deref 0, data => 0, 5, 'value';
	    test canned( arcturus => 'pmra' ),
		'query id Arcturus (vo) - proper motion in right ascension';

	    deref 0, data => 0, 6, 'value';
	    test canned( arcturus => 'pmdec' ),
		'query id Arcturus (vo) - proper motion in declination';

	    deref 0, data => 0, 7, 'value';
	    test canned( arcturus => 'radial' ),
		'query id Arcturus (vo) - radial velocity';

	}

	echo <<'EOD';

The following tests use the script_file interface

EOD

	clear;
	call set => parser => 'script=Parse_VO_Table';

	call script_file => 't/arcturus.vo';

	count;
	test 1, 'script_file t/arcturus.vo - count tables';

	deref 0, 'data';
	count;
	test 1, 'script_file t/arcturus.vo - count rows';

	deref 0, data => 0, 0, 'value';
	test canned( arcturus => 'name' ), 'script_file t/arcturus.vo - name';

	deref 0, data => 0, 2, 'value';
	test canned( arcturus => 'ra' ), 'script_file t/arcturus.vo - right ascension';

	deref 0, data => 0, 3, 'value';
	test canned( arcturus => 'dec' ), 'script_file t/arcturus.vo - declination';

	deref 0, data => 0, 4, 'value';
	test canned( arcturus => 'plx' ), 'script_file t/arcturus.vo - parallax';

	deref 0, data => 0, 5, 'value';
	test canned( arcturus => 'pmra' ),
	    'script_file t/arcturus.vo - proper motion in right ascension';

	deref 0, data => 0, 6, 'value';
	test canned( arcturus => 'pmdec' ),
	    'script_file t/arcturus.vo - proper motion in declination';

	deref 0, data => 0, 7, 'value';
	test canned( arcturus => 'radial' ),
	    'script_file t/arcturus.vo - radial velocity';


	echo <<'EOD';

The following tests use the url_query interface

EOD

	clear;
	call set => url_args => 'coodisp1=d';

	call url_query => id => Ident => 'Arcturus';
	count;
	test 1, 'url_query id Arcturus (vo) - count of tables';

	deref 0, 'data';
	count;
	test 1, 'url_query id arcturus (vo) - count of rows';

	note <<'EOD';

We do not test for the MAIN_ID when using the url interface. A note from
SIMBAD support on February 6 2014 says that there is no way to influence
what SIMBAD returns in a url VO-format query.

EOD

=begin comment

    TODO: {

	local $TODO = 'Return changed Feb 3 2014. Unable to influence.';
	# As I read the documentatin I should do the following to ensure
	# the return of the common name:
	#   set url_args list.idopt=CATLIST
	#   set url_args list.idcat=NAME
	# and this in fact influences the behavior of text-format and
	# script-based VO-format querues (I used catalog LFT, picked at
	# random). But the VO-format URL query seems insensitive to
	# this. I sent a note to SIMBAD on February 5 2014, and made
	# this a TODO.
	#
	# The above-mentioned note says the most recent change in the
	# data for Arcturus was February 4 2014, which of course does
	# not rule out a change on the 3rd.

	deref 0, data => 0;
	find meta => 1, name => 'MAIN_ID';
	deref_curr 'value';
	test canned( arcturus => 'name' ), 'url_query id Arcturus (vo) - name';

    }

=end comment

=cut

	deref 0, data => 0;
	find meta => 1, name => 'RA_d';
	deref_curr 'value';
	# want 213.9153
	# As of about SIMBAD4 1.005 the default became sexagesimal
	# As of 1.069 (probably much earlier) you can set coodisp1=d to
	# display in decimal. But this seems not to work for VOTable
	# output.
	# As of 1.117 (April 9 2009) votable output went back to
	# decimal. The coodisp option still seems not to affect it,
	# though.  want_load arcturus ra_hms
	# On November 18 2013 (Monday) the 'RA' tag became 'RA_d'. Maybe
	# it's finally paying attention to 'coodisp1=d'. Version 1.215
	# was the 15th (Friday), but 'RA' was working on the 17th.
	test canned( arcturus => 'ra' ),
	    'url_query id Arcturus (vo) - right ascension'
	    or diag Dumper( returned_value() );

	deref 0, data => 0;
	find meta => 1, name => 'DEC_d';
	deref_curr 'value';
	# want +19.18241027778
	# As of about SIMBAD4 1.005 the default became sexigesimal
	# As of 1.069 (probably much earlier) you can set coodisp1=d to
	# display in decimal. But this seems not to work for VOTable
	# output.
	# As of 1.117 (April 9 2009) votable output went back to
	# decimal. The coodisp option still seems not to affect it,
	# though.  want_load arcturus dec_dms
	# On November 18 2013 (Monday) the 'DEC' tag became 'DEC_d'.
	# Maybe it's finally paying attention to 'coodisp1=d'. Version
	# 1.215 was the 15th (Friday), but 'DEC' was working on the
	# 17th.
	test canned( arcturus => 'dec' ),
	    'url_query id Arcturus (vo) - declination'
	    or diag Dumper( returned_value() );

	deref 0, data => 0;
	find meta => 1, name => 'PLX_VALUE';
	deref_curr 'value';
	test canned( arcturus => 'plx' ), 'url_query id Arcturus (vo) - parallax';

	deref 0, data => 0;
	find meta => 1, name => 'PMRA';
	deref_curr 'value';
	test canned( arcturus => 'pmra' ),
	    'url_query id Arcturus (vo) - proper motion in right ascension';

	deref 0, data => 0;
	find meta => 1, name => 'PMDEC';
	deref_curr 'value';
	test canned( arcturus => 'pmdec' ),
	    'url_query id Arcturus (vo) - proper motion in declination';

	deref 0, data => 0;
	find meta => 1, name => 'RV_VALUE';
	deref_curr 'value';
	test canned( arcturus => 'radial' ),
	    'url_query id Arcturus (vo) - radial velocity';

	call set => emulate_soap_queries => 1;
	clear;

	echo <<'EOD';

The following tests use the script interface, but emulate SOAP queries.

EOD

	call query => id => 'Arcturus';

	count;
	test 1, 'query id Arcturus (vo) - count of tables';

	deref 0, 'data';
	count;
	test 1, 'query id arcturus (vo) - count of rows';

	deref 0, data => 0, 0, 'value';
	test canned( arcturus => 'name' ), 'query id Arcturus (vo) - name';

	deref 0, data => 0, 2, 'value';
	test canned( arcturus => 'ra' ), 'query id Arcturus (vo) - right ascension';

	deref 0, data => 0, 3, 'value';
	test canned( arcturus => 'dec' ), 'query id Arcturus (vo) - declination';

	deref 0, data => 0, 4, 'value';
	test canned( arcturus => 'plx' ), 'query id Arcturus (vo) - parallax';

	deref 0, data => 0, 5, 'value';
	test canned( arcturus => 'pmra' ),
	    'query id Arcturus (vo) - proper motion in right ascension';

	deref 0, data => 0, 6, 'value';
	test canned( arcturus => 'pmdec' ),
	    'query id Arcturus (vo) - proper motion in declination';

	deref 0, data => 0, 7, 'value';
	test canned( arcturus => 'radial' ),
	    'query id Arcturus (vo) - radial velocity';

    };

}

end;


1;

# ex: set textwidth=72 :
