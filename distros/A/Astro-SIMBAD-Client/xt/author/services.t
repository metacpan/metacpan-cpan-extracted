package main;

use strict;
use warnings;

use lib qw{ inc };

use My::Module::Test;


access;

TODO: {
    local $TODO = 'SOAP vo queries are deprecated';
    local $SIG{__WARN__} = sub {};	# Ignore warnings.

    echo <<'EOD';

Test individual format effectors of the web services (SOAP) interface
EOD

    load_data 't/canned.data';

    call set => type => 'txt';
    call set => parser => 'txt=';


    call set => format => 'txt=%IDLIST(NAME|1)';
    call query => id => 'Arcturus';
    test canned( arcturus => 'name' ), 'query id Arcturus -- %IDLIST(NAME|1)';


    call set => format => 'txt=%OTYPE';
    call query => id => 'Arcturus';
    test canned( arcturus => 'type' ), 'query id Arcturus -- %OTYPE';


    call set => format => 'txt=%OTYPELIST';
    call query => id => 'Arcturus';
    test canned( arcturus => 'long' ), 'query id Arcturus -- %OTYPELIST';


    call set => format => 'txt=%COO(d;A)';
    call query => id => 'Arcturus';
    test canned( arcturus => 'ra' ), 'query id Arcturus -- %COO(d;A)';


    call set => format => 'txt=%COO(d;D)';
    call query => id => 'Arcturus';
    test canned( arcturus => 'dec' ), 'query id Arcturus -- %COO(d;D)';


    call set => format => 'txt=%PLX(V)';
    call query => id => 'Arcturus';
    test canned( arcturus => 'plx' ), 'query id Arcturus -- %PLX(V)';


    call set => format => 'txt=%PM(A)';
    call query => id => 'Arcturus';
    test canned( arcturus => 'pmra' ), 'query id Arcturus -- %PM(A)';


    call set => format => 'txt=%PM(D)';
    call query => id => 'Arcturus';
    test canned( arcturus => 'pmdec' ), 'query id Arcturus -- %PM(D)';


    call set => format => 'txt=%RV(V)';
    call query => id => 'Arcturus';
    test canned( arcturus => 'radial' ), 'query id Arcturus -- %RV(V)';


    call set => format => 'txt=%RV(Z)';
    call query => id => 'Arcturus';
    test canned( arcturus => 'redshift' ), 'query id Arcturus -- %RV(Z)';


    call set => format => 'txt=%SP(S)';
    call query => id => 'Arcturus';
    test canned( arcturus => 'spec' ), 'query id Arcturus -- %SP(S)';


    call set => format => 'txt=%FLUXLIST(B)[%flux(F)]';
    call query => id => 'Arcturus';
    test canned( arcturus => 'bmag' ),
	'query id Arcturus -- %FLUXLIST(B)[%flux(F)]';


    call set => format => 'txt=%FLUXLIST(V)[%flux(F)]';
    call query => id => 'Arcturus';
    test canned( arcturus => 'vmag' ),
	'query id Arcturus -- %FLUXLIST(V)[%flux(F)]';

}

end;

1;
