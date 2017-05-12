# $Id: Log.pm 129 2014-09-24 12:07:07Z jo $
# Cindy::Log - Logging for Cindy
#
# Copyright (c) 2008 Joachim Zobel <jz-2008@heute-morgen.de>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#


package Cindy::Log;

use strict;
use warnings;

use base qw(Exporter);

our @EXPORT= qw(DEBUG INFO WARN ERROR FATAL); 

## no critic (ProhibitStringyEval);
# Strings are evaled to avoid compile time checking
# DO NOT FORGET TO CHECK iF THESE MODULES COMPILE
# if you changed them.
BEGIN {
  # Detect mod_perl2 by checking for what we need.
  eval (q|
    use Apache2::RequestUtil;
    1;
  |)
  and eval (q|
    use Cindy::Log::Apache2;
    1;
  |)
  or eval(q|
    use Log::Log4perl qw(:easy);
    1;
  |)
  or eval(q|
    use Cindy::Log::Default;
    1;
  |);
}
## use critic

1;

