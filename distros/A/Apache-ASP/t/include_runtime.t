use Apache::ASP::CGI;
&Apache::ASP::CGI::do_self('NoState' => 1);

__END__

<% use lib '.';	use T;	$t =T->new(); %>

<% 

use vars qw($ok);

$ok = 0;
my $script = "<\% \$ok++; %\>";
$Response->Include(\$script);
$t->eok($ok == 1, "Could not increment \$ok");

$script = "<\% my \$ok = 'ok'; %\><\%= \$ok %\>";
my $out = $Response->TrapInclude(\$script);
$t->eok($$out eq 'ok', "Could not print 'ok' in runtime TrapInclude()");

%>
