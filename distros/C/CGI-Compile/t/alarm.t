#!/usr/bin/env perl;
use strict;
use warnings;

use Test::More $^O eq 'MSWin32' ? (
    skip_all => 'not supported on Win32')
: (
    tests => 1
);

use CGI::Compile;
use Capture::Tiny 'capture_stdout';

my $cgi =<<'EOL';
#!/usr/bin/perl

use strict;
use warnings;
use Time::HiRes 'ualarm';

print "Content-Type: text/plain\015\012\015\012";

$SIG{ALRM} = sub { print "ALARM\015\012" };

ualarm 50;
sleep 1;
EOL

my $sub = CGI::Compile->compile(\$cgi);

like capture_stdout { $sub->() },
     qr/ALARM/;

done_testing;
