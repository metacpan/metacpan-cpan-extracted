package CGI::Untaint::to_countrynumber;
use warnings;
use strict;
use base 'CGI::Untaint::to_countrycode';

sub _codeset { Locale::Constants::LOCALE_CODE_NUMERIC }

1;
