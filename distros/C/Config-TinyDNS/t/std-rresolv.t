#!/usr/bin/perl

use 5.010;
use Socket qw/inet_aton/;

my $IP;
BEGIN { 
    *CORE::GLOBAL::gethostbyname = sub { inet_aton($IP // "0.0.0.0") } 
}

use t::Utils qw/:ALL/;

@Filter = "rresolv";

for (qw/ + = . & @ /) {
    filt +(<<DATA) x 2,                 "rresolv leaves $_ ips alone";
${_}foo.org:1.2.3.4
DATA

    $IP = "1.2.3.4";
    filt <<DATA, <<WANT,                "hosts in $_ IP slots are resolved";
${_}foo.org:bar.com
DATA
${_}foo.org:1.2.3.4
WANT

    $IP = undef;
    filt <<DATA, <<WANT,                "nonexistent hosts for $_ are 0.0.0.0";
${_}foo.org:bar.com
DATA
${_}foo.org:0.0.0.0
WANT

}

done_testing;
