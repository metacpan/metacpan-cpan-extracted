#!/usr/local/bin/perl

use Apache::ASP::CGI;

use strict;
$SIG{__DIE__} = \&Carp::confess;

&Apache::ASP::CGI::do_self(
#	Debug => -1
);

__END__

<% 

for(1..10) { $Application->UnLock; }
$t->eok(sub { $Application->Lock }, '$Application->Lock');
$t->eok($Application->{Start}, 'Application_OnStart did not run');

my $count = 0;
$Application->{count} = 0;
for(1..3) {
	$Application->{count}++;
	$count++;
	$t->eok($count == $Application->{count}, 
		'failure to increment $Application->{count}');
}

$t->eok(sub { $Application->UnLock }, '$Application->UnLock');
#$t->eok($Application->SessionCount(), '$Application->SessionCount()');
$t->eok($Application->GetSession($Session->{SessionID}), '$Application->GetSession()');
%>


