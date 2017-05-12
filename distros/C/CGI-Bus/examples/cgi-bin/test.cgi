#perl -w
use CGI;
#delete $ENV{HTTP_AUTHORIZATION};
my $s='';
#my $s=eval("CGI->new();") || $@;
#my $s=do("config.pl");
print "<html>\n\n";
print "<head>\n";
print '<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">';
print '<title>Test Script</title>';
print '</head>';
print '<body>';
print $s,' ', ref($s) ? $s->param('qq')||'?' : '*', "<br>\n";
#print $s,$s->cgi,$s->user,$s->ugroups,$s->server_name(),$s->udata->paramj('upws_urlh'),$s->dbi, "<br>\n";
print eval{Win32::LoginName()}||getlogin(), "<br>\n";
print ref($s) ? $s->start_multipart_form(-method=>'post') : '<form method="post">';
print '<input type="submit" name="qq" value="qq">';
print '</form>';
foreach $var (qw(PATH_INFO PATH_TRANSLATED SCRIPT_NAME REQUEST_METHOD CONTENT_TYPE CONTENT_LENGTH HTTP_AUTHORIZATION HTTP_USER_AGENT QUERY_STRING)) {
 my $val =$ENV{$var}; # open env vars only!!!
    $val = 'NULL' if !defined($val);
}
my $count =0;
foreach my $var (sort(keys(%ENV))) {
 my $val = $ENV{$var};
    $val = 'NULL' if !defined($val);
    $val =~ s|\n|\\n|g;
    $val =~ s|"|\\"|g;
    print "${var}=\"${val}\"<br />\n";
    $count++;
}
print "--------<br />\n";
print "total: $count <br />\n";

eval "use Cwd";
print "dir=", Cwd::getcwd(),"<br />\n";
print "--------<br />\n";

print "query=", $ENV{'QUERY_STRING'} || '', "<br />\n";
#print ((<STDIN>));
if (!$s && ($ENV{CONTENT_LENGTH}||0)) {
   my $val;
   read(STDIN, $val, $ENV{CONTENT_LENGTH}||3);
   print $val;
}

print '</body>';