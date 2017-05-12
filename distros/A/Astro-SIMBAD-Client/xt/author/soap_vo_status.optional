package main;

use 5.006002;

use strict;
use warnings;

use lib qw{ inc };

use Astro::SIMBAD::Client::Test;

# plan skip_all => q{Not needed, since vo-format SOAP queries work.};

access;

diag <<'EOD';


If this test succeeds, it means that SOAP 'vo'-format queries are still
broken.

EOD

load_module qw{ XML::Parser XML::Parser::Lite };

call set => type => 'vo';
call set => parser => 'vo=Parse_VO_Table';

call query => id => 'Arcturus';

count;
test_false 1, 'query id Arcturus (vo) is hosed'
    or diag <<'EOD';
The SOAP vo-format query has been fixed. You can now remove the 'TODO'
from t/vo.t, and retire this test.
EOD

end;

1;

# ex: set textwidth=72 :
