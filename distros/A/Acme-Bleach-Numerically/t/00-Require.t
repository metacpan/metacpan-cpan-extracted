#
# $Id: 00-Require.t,v 0.1 2005/08/30 01:32:11 dankogai Exp $
#
use strict;
use Test::More tests => 3;
require_ok('Acme::Bleach::Numerically');
Acme::Bleach::Numerically->import(qw/num2str str2num bogus/);
can_ok("main", qw/num2str str2num/);
ok(! main->can("bogus") => "can not &bogus");
__END__
