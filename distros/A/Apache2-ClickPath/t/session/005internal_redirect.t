use strict;

use Apache::Test qw(:withtestmore);
use Test::More;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';

plan tests => 2;

Apache::TestRequest::module('default');

my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || '';
t_debug("connecting to $hostport");

mkdir "t/htdocs/bin";
open F, ">t/htdocs/bin/x.pl" and print F <<"EOF";
#!/usr/bin/perl

print "Location: /TestSession__001session_generation?SESSION\n\n";
EOF
close F;
chmod 0755, "t/htdocs/bin/x.pl";

my $got=GET_BODY( "/bin/x.pl" );
ok t_cmp( $got, qr/^SESSION=.+/m,  ), "without session";

$got=~m/^SESSION=(.+)/;
my $session=$1;

$got=GET_BODY( "/-S:$session/bin/x.pl" );
ok t_cmp( $got, qr/^SESSION=\Q$session\E/m,  ), "with session";

# Local Variables: #
# mode: cperl #
# End: #
