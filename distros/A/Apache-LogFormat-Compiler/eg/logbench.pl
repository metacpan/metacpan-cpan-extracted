use strict;
use Benchmark qw/ :all /;
use File::Temp qw/ tempfile /;
use Storable qw/ nstore retrieve /;
use HTTP::Request::Common;


my $result = {};
for my $name (qw! extlib-1.0022/lib/perl5 lib !) {
    my ($fh, $fn) = tempfile();
    my $pid = fork;
    if ($pid) {
        close $fh;
        wait;
    }
    else {
        eval qq{use lib '$name'};
        require Plack;
        use Plack::Builder;
        
        warn $Plack::VERSION;
        my $log_app = builder {
            enable 'AccessLog', format => "combined", logger => sub {};
            sub{ [ 200, [], [ "Hello"] ] };
        };

        my $code = sub {
            $log_app->({REQUEST_METHOD=>"GET",SERVER_PROTOCOL=>"HTTP/1.0",REQUEST_URI=>"/"});
        };

        my $r = timethis(0, $code);
        nstore $r, $fn;
        exit;
    }
    $result->{$name} = retrieve $fn;
};

cmpthese $result;

__END__
1.0022 at eg/logbench.pl line 21.
timethis for 3:  3 wallclock secs ( 3.17 usr +  0.00 sys =  3.17 CPU) @ 8828.71/s (n=27987)
1.0030 at eg/logbench.pl line 21.
timethis for 3:  3 wallclock secs ( 3.28 usr +  0.00 sys =  3.28 CPU) @ 50064.02/s (n=164210)
                           Rate extlib-1.0022/lib/perl5                     lib
extlib-1.0022/lib/perl5  8829/s                      --                    -82%
lib                     50064/s                    467%                      --

