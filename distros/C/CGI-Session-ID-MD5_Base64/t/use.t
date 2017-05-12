#!/usr/bin/env perl -w
use strict;
use Test;
BEGIN { plan tests => 1 }

use CGI::Session::ID::MD5_Base64; ok(1);
exit;
__END__
