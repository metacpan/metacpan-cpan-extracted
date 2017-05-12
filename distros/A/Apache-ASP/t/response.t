use Apache::ASP::CGI;
&Apache::ASP::CGI::do_self(NoState => 1);

__END__

<% use lib '.';	use T;	$t =T->new();

# IsClientConnected Tests
$t->eok($Response->{IsClientConnected}, "\$Response->{IsClientConnected}");
$t->eok($Response->IsClientConnected, "\$Response->IsClientConnected");
$Server->{asp}{r}->connection->aborted(1);
$Response->Flush; # updates {IsClientConnected}
$t->eok(! $Response->{IsClientConnected}, "\$Response->{IsClientConnected} after aborted/Flush()");
$t->eok(! $Response->IsClientConnected, "\$Response->IsClientConnected after aborted");

# AddHeader() member setting
my $date = &Apache::ASP::Date::time2str($time);
$Response->AddHeader('expires', $date);
$t->eok($Response->{ExpiresAbsolute} eq $date, "\$Response->AddHeader('Expires', ...) did not set ExpiresAbsolute member");
$Response->AddHeader('Content-type', 'text/plain');
$t->eok($Response->{ContentType} eq 'text/plain', "\$Response->AddHeader('Content-Type', ...) did not set ContentType member");
$Response->AddHeader('Cache-Control', 'no-cache');
$t->eok($Response->{CacheControl} eq 'no-cache', "\$Response->AddHeader('Cache-Control', ...) did not set CacheControl member");

# reset
$Server->{asp}{r}->connection->aborted(0);
$Response->{IsClientConnected} = 1;
$t->eok($Response->IsClientConnected, "\$Response->IsClientConnected after reset");

$t->{t} += 3; 
$t->done;
$Response->Write("");

%>
ok
ok
<% 
	print "ok\n";
#	$Response->AppendToLog("logging ok");
#	$Response->Debug("logging ok");
%>


