package CGI::Application::Framework::Constants;

use strict;
use warnings;

use Exporter;
use vars qw/@ISA @EXPORT_OK/;
@ISA = qw ( Exporter );
@EXPORT_OK = qw (
                 SESSION_IN_HIDDEN_FORM_FIELD
                 SESSION_IN_COOKIE
                 SESSION_IN_URL
                 SESSION_FIRST_TIME
                 SESSION_MISSING
                 );

# -----------------------------------------------------------------------------
# The constants in this file represent the configuration parameters used
# throughout all the Framework-based programs as well as all the
# string constants that are needed (for database insertion/lookup, or
# whatever else).  Some of the constants are things that I need for
# my own programmatic convenience but which are needed across several files.
# (E.g. the stuff having to do with sesssioning.)
# ----------------------------------------------------------------------------
use constant SESSION_IN_HIDDEN_FORM_FIELD => 'session ID in hidden form field';
use constant SESSION_IN_COOKIE            => 'session ID in cookie';
use constant SESSION_MISSING              => 'session ID not found';
use constant SESSION_IN_URL               => 'session ID in URL parameter';
use constant SESSION_FIRST_TIME
    => 'session ID newly generated and only available within session itself';
# ----------------------------------------------------------------------------

1;



