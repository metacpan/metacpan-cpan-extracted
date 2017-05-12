use strict;
use warnings;
use utf8;
use feature qw/say/;

use constant epoch => time;

use Benchmark qw/cmpthese timethese/;

use DateTime;
use DateTimeX::Moment;

sub hr { say '-' x 40 }

say 'new()';
cmpthese timethese 100000 => {
    datetime => sub { DateTime->new(year => 2016) },
    moment   => sub { DateTimeX::Moment->new(year => 2016) },
};
hr();

say 'now()';
cmpthese timethese 100000 => {
    datetime => sub { DateTime->now },
    moment   => sub { DateTimeX::Moment->now },
};
hr();

say 'from_epoch()';
cmpthese timethese 100000 => {
    datetime => sub { DateTime->from_epoch(epoch => epoch) },
    moment   => sub { DateTimeX::Moment->from_epoch(epoch => epoch) },
};
hr();

say 'calculate()';
cmpthese timethese 100000 => {
    datetime => sub { DateTime->now->add(years => 1) },
    moment   => sub { DateTimeX::Moment->now->add(years => 1) },
};
hr();

__END__
new()
Benchmark: timing 100000 iterations of datetime, moment...
  datetime:  4 wallclock secs ( 4.06 usr +  0.01 sys =  4.07 CPU) @ 24570.02/s (n=100000)
    moment:  1 wallclock secs ( 0.62 usr +  0.01 sys =  0.63 CPU) @ 158730.16/s (n=100000)
             Rate datetime   moment
datetime  24570/s       --     -85%
moment   158730/s     546%       --
----------------------------------------
now()
Benchmark: timing 100000 iterations of datetime, moment...
  datetime:  4 wallclock secs ( 4.38 usr +  0.01 sys =  4.39 CPU) @ 22779.04/s (n=100000)
    moment:  1 wallclock secs ( 0.59 usr +  0.00 sys =  0.59 CPU) @ 169491.53/s (n=100000)
             Rate datetime   moment
datetime  22779/s       --     -87%
moment   169492/s     644%       --
----------------------------------------
from_epoch()
Benchmark: timing 100000 iterations of datetime, moment...
  datetime:  4 wallclock secs ( 4.27 usr +  0.01 sys =  4.28 CPU) @ 23364.49/s (n=100000)
    moment:  1 wallclock secs ( 0.63 usr +  0.00 sys =  0.63 CPU) @ 158730.16/s (n=100000)
             Rate datetime   moment
datetime  23364/s       --     -85%
moment   158730/s     579%       --
----------------------------------------
calculate()
Benchmark: timing 100000 iterations of datetime, moment...
  datetime: 20 wallclock secs (20.30 usr +  0.04 sys = 20.34 CPU) @ 4916.42/s (n=100000)
    moment:  1 wallclock secs ( 1.07 usr +  0.00 sys =  1.07 CPU) @ 93457.94/s (n=100000)
            Rate datetime   moment
datetime  4916/s       --     -95%
moment   93458/s    1801%       --
----------------------------------------
