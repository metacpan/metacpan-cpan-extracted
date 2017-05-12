<% 
use vars qw($demo $title);
use DemoASP; 
$demo = &DemoASP::new;
my $gifdir = (-e '../asptitlelogo.gif') ? '..' : '../..';
my %args = @_;

%>
<html>
<head><title><%= $args{title} || $title || $demo->{title} %></title></head>
<body bgcolor='<%= $args{bgcolor} || $demo->{bgcolor} %>' alink="#ff5599" vlink="#993399">

<table border="0" cellpadding="3" cellspacing="0" width="100%">
<tr bgcolor="#063678">
  <td><img border="0" src="<%=$gifdir%>/asptitlelogo.gif" alt="Apache::ASP" /></td>
  <td align="right" width="300">
    <a href="http://perl.apache.org"><img src="<%=$gifdir%>/powered_by_modperl.gif" border="0" alt="Powered by ModPerl &amp; Apache" /></a> 
    <a href="http://www.apache-asp.org"><img src="<%=$gifdir%>/powered_by_apache_asp.jpg" border="0" alt="Powered by Apache::ASP" /></a> 
  </td>
</tr>
<tr bgcolor="gray" width="100%">
  <td><font size="+0" color="white"><b><%=$title || $demo->{title}%></b></font></td>
  <td align="right">
    <% 
       my $date = &Apache::ASP::Date::time2iso(); 
       $date =~ s/\s*\d\d:\d\d:\d\d$//;
     %>
    <font color="white" size="-1"><%=$date %></font>
  </td>
</tr>
</table>
<br />


