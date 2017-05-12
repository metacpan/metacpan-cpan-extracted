#!/usr/local/bin/perl

use Apache::ASP::CGI;
#use lib qw(. ..);
#use ASP;

&Apache::ASP::CGI::do_self(
#	Debug => -1
			   NoState => 1,
);

__END__

<% 
$t->eok($Apache::ASP::ShareDir, '$ShareDir variable not defined');

$t->eok($Server->MapInclude('Share::CORE/MailErrors.inc'), 
	"MapInclude() for Share::CORE/MailErrors.inc should succeed");
$t->eok(! $Server->MapInclude('CORE/MailErrors.inc'), 
	"MapInclude() for CORE/MailErrors.inc should not succeed without Share:: prefix");
$t->eok(! $Server->MapInclude('Share::CORE/NEVER EXIST'), 
	"MapInclude() for Share::CORE/NEVER EXIST should fail");
%>


