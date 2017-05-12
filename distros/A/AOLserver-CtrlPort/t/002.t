
use Test::More;

BEGIN {
    if($ENV{AOLSERVERCP}) {
       plan tests => 1;
    } else {
       plan skip_all => "Only with AOLSERVERCP set to host:port:u:p";
    };
}

use AOLserver::CtrlPort;

my($host, $port, $user, $passwd) = split /:/, $ENV{AOLSERVERCP};

my $c = AOLserver::CtrlPort->new(
    Host     => $host,
    Port     => $port,
    User     => $user,
    Password => $passwd,
);

my $out = $c->send_cmds("info tcl");
like($out, qr/^\d+\.\d+\n/);
#print "out=$out\n";

