#
# $Id: benchmark.pl,v 1.1 2006/10/27 04:11:25 dankogai Exp $
#
use strict;
use warnings;
use Benchmark qw/cmpthese timethese/;
use BSD::getloadavg;
cmpthese(
    timethese(
        0,
        {
            command => sub {
                my @loadavg =
                  ( qx(uptime) =~ /([\.\d]+)\s+([\.\d]+)\s+([\.\d]+)/ );
                return @loadavg;
            },
            XS => sub {
		my @loadavg = getloadavg();
                return @loadavg;
              }
        }
    )
);
