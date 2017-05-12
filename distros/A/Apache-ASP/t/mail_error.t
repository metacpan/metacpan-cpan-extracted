#!/usr/local/bin/perl

use Apache::ASP::CGI;
use strict;

$^W = 1;
&Apache::ASP::CGI::do_self(NoState => 1, UseStrict => 1);

__END__

<% 
my $out = $Response->TrapInclude('Share::CORE/MailErrors.inc');
$t->eok(length($$out) > 50, "MailErrors.inc");
$t->eok(sub { $$out =~ /Subject: Apache::ASP Errors for t\Wmail_error\.t/s }, "MailError.inc Subject");
for my $key ( qw ( GLOBAL FILE QUERY FORM ) ) {
    $t->eok( sub { $$out =~ /$key/s }, "MailErrors.inc Field $key" );
}
%>


