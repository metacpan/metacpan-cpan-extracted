use CGI;

my $q = new CGI;

print $q->header($q->param("ct"));

print qq|<b>ok</b>\n|;
