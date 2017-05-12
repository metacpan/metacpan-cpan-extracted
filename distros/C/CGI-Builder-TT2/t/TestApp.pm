use strict;
use warnings;

use Data::Dumper;

# The simplest App that does nothing...
package TestApp1;
use CGI::Builder qw/ CGI::Builder::TT2 /;

# Manually adding vars ...
package TestApp2;
use CGI::Builder qw/ CGI::Builder::TT2 /;

sub PH_testapp2
{
    my $s = shift;
    $s->tt_vars( world => 'Republic of Perl' );
}

# Lookups
package TestApp3::Lookups;
use vars qw/ $world /;

$world = 'Republic of Perl';

package TestApp3;
use CGI::Builder qw/ CGI::Builder::TT2 /;

package TestApp4::Lookups;
use vars qw/ @worlds /;

@worlds = qw/ A B C Earth /;

package TestApp4;
use CGI::Builder qw/ CGI::Builder::TT2 /;


package TestApp5::Lookups;

sub foo 
{
    return "A short string that's easy to test";
}

package TestApp5;
use CGI::Builder qw/ CGI::Builder::TT2 /;

package TestApp6;
use CGI::Builder qw/ CGI::Builder::TT2 /;

package TestApp7;
use CGI::Builder qw/ CGI::Builder::TT2 /;

package TestApp8;
use CGI::Builder qw/ CGI::Builder::TT2 /;

1;
