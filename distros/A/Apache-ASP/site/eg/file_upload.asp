#!/usr/bin/perl /usr/bin/asp-perl

<!--#include file="header.inc"-->

This example shows you how to use Apache::ASP to handle file uploads.
You need to have a recent version CGI.pm to use this facility.
Just click Browse..., select your file, hit 'file upload' and 
voila!, you will see the data in the file below.
<p>
Note that the current limit set on uploads for this demo is
<tt>	
<%
my $limit = $Server->Config('FileUploadMax') || $CGI::POST_MAX;
$limit = ($limit eq '-1') ? 'NONE' : $limit;
print "$limit";
%>
</tt>.
<% if($limit && ($limit < $Request->{TotalBytes})) { %>
  This limit was <b>exceeded</b> by a POST of <tt><%= $Request->{TotalBytes} %></tt> bytes!
<% } %>
<table border=0><tr><td valign=center>
<%
use CGI;
my $q = new CGI; 
print $q->start_multipart_form();
print $q->hidden('file_upload', 'Hidden File Upload Form Text');
print $q->filefield('uploaded_file','starting value',30,100);
print "</td><td valign=center>";
print $q->submit('Upload File');
%>
</td></tr></table>

<br>
<b>File Upload Type:</b>
<%= 
    $q->checkbox_group(-name=>'extensions',
		   -values=>['GIF','HTML','OTHER'],
		   -defaults=>['HTML']
		   ).
    $q->endform()
  %>

<% 
my $filehandle;
if($filehandle = $Request->{Form}{uploaded_file}) { 
    %>
      Upload Type Specified: <%= join(', ', $Request->Form('extensions')) %><br>
    <%
    local *FILE;
    my $upload = $Request->{FileUpload}{uploaded_file};
    print "<table>";
    my @data = (
		'$Request->{TotalBytes}', $Request->{TotalBytes},
		'Hidden Text', $Request->Form('file_upload'),
		'Uploaded File Name', $filehandle,
		# we only have the temp file because of the
		# FileUploadTemp setting
		'Temp File', $upload->{TempFile},
		'Temp File Exists', (-e $upload->{TempFile}),
		'Temp File Opened', (open(FILE, $upload->{TempFile}) ? 'yes' : "no: $!"),
		map { 
		    ($_, $Request->FileUpload('uploaded_file', $_)) 
		} sort keys %$upload 
	       );
    close FILE;

    while(@data) {
	my($key, $value) = (shift @data, shift @data);
		%>
		<tr>
			<td><b><font size=-1><%=$key%></font></b></td>
			<td><font size=-1><%=$value%></font></td>
		</tr>
		<%
    }
    print "</table>";
	%>

	<pre>
UPLOADED DATA
=============
<% 
    while(<$filehandle>) { 
	print $Server->HTMLEncode($_);	
    }
%>
	</pre>
<% } %>

<!--#include file="footer.inc"-->
