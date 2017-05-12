#!/usr/bin/perl

use Apache::ASP::CGI::Test;

use lib qw(t . ..);
use T;
use strict;

my $t = T->new;
my $r = Apache::ASP::CGI::Test->do_self
    (
     UseStrict => 1, 
     SessionQueryParse => 1,
     Global => 'null',
     );
my $header = $r->test_header_out;
my $body = $r->test_body_out;

my @tests = (
	     '<a href="/somelink.asp?test1=value1&amp;test2=value2&amp;session-id=',
	     "<frame src='somelink.asp?test3=value3&amp;test4=value4&amp;session-id=",
	     "<form action=/somelink.asp?test5=value5&amp;test6=value6&amp;session-id="
	     );

for my $test ( @tests ) {
    $test =~ s/(\W)/\\$1/isg;
    if($body =~ /$test/s) {
	$t->ok;
    } else {
	$t->not_ok;
    }
}

$t->done;

__END__

<a href="/somelink.asp?test1=value1&amp;test2=value2">Some Link</a>

<frame src='<%= $Server->URL("somelink.asp?test3=value3", { test4 => "value4" }) %>'>

<form action=/somelink.asp?test5=value5&test6=value6>
