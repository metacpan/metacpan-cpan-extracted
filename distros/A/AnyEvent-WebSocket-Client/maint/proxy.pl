use strict;
use warnings;
use HTTP::Proxy;

my $proxy = HTTP::Proxy->new( port => 3128 );
$proxy->start;
