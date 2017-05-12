<%
use TestApp::ASP::Welcome;
my $appname = 'TestApp::ASP';
my $html;
%>
<!DOCTYPE html>
<html>
<head>
<%
$html = $TestApp::ASP::Response->TrapInclude( 'templates/welcome_head.inc', { title => 'Welcome Page!' } );
$$html =~ s/([Ww])elcome/${1}elcome again/;
print $$html;
%>
</head>
<body>
<%
my $body = qq{<p>This is the welcome page for $appname</p>};
$html = $TestApp::ASP::Response->TrapInclude( 'templates/welcome_body.inc', { appname => $appname }, $body );
$$html =~ s/([Ww])elcome/${1}elcome again/g;
print $$html;
%>
</body>
</html>
