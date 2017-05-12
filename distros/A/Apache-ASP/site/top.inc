<%

use File::Basename;
my $basename = basename($0);
($basename) = split(/\./, $basename);
my $section = $FILES{$basename} || die("no section for $basename");
my ($data) = grep($_->{name} eq $section, @{$ASP->{stack}});

my ($copy) = grep($_->{name} eq 'COPYRIGHT', @{$ASP->{stack}});
$copy->{body} =~ s/\n\n.*$//sg;

$data || die("can't get data for $section");
my $module = "Apache :: ASP";
my $title = "$module :: ".uc(lc $data->{name});

%>

<html>
<head>
<title><%=$title%></title>
</head>
<body bgcolor=white link=#3355cc alink=#ff5599 vlink=#993399>

<table border=0 cellpadding=5 cellspacing=0 height=95% width=100%>
<tr><td colspan=2 bgcolor=#ff4488><img src=apache_asp.gif alt="<%=$module%>"></td></tr>
<tr>

<td valign=top bgcolor=#ffcccc>
	<table border=0 cellpadding=0 cellspacing=0>
	<tr><td align=center><hr size=1></td></tr>

	<% 
	for $top (@{$ASP->{stack}}, '', { name=> EXAMPLES, file => 'eg/index'}) { 
		unless($top) {
			%><tr><td><hr size=1></td></tr><%
			next;
		}

		my $file;
		if($top->{file}) {	
			$file = $top->{file};
		} else {
			($file) = grep($top->{name} eq $FILES{$_}, keys %FILES); 
		}
		$file = "$file.html";
		next unless (-e $file);

		%>
		<tr>
		<td><a href=<%=$file%>><font face=verdana size=-1 color=#3355cc><%=$top->{name}%></font></a></td>
		</tr>
		<%
	}
	%>
	<tr>
		<td align=center>
		<hr size=1>
		<a href=http://perl.apache.org><img 
			src=modperl.gif border=0
			alt="Powered by ModPerl & Apache"
			></a>
		<hr size=1>
		</td>
	</tr>
	</table>
</td>

<td valign=top>
<%
my @stack;
my @order;
push(@stack, $data);
while(@stack) {
	my $data = shift @stack;
	unshift(@stack, @{$data->{stack}});
	push(@order, $data);	
}

print pod2html($data->{body}, $data->{name}, $data->{level});

my @links;
$data = shift @order;
if(@order > 2) {
	my $last_level = $order[0]->{level};
	for $data (@order) {
		if($last_level != $data->{level}) {
			push(@links, '');
			$last_level = $data->{level};
		}		
		push(@links, "<a href=#".$Server->URLEncode($data->{name})."><font color=#3355cc>$data->{name}</font></a>");
	}
	%>

	<hr size=1>
	<table width=100% border=0 cellpadding=5><tr><td valign=top><font face=verdana size=-1>
	<% 
	for($i=0; $i<@links; $i++) { 
		if($i == (int((@links+1) / 2))) {
			print "</font></td><td valign=top><font face=verdana size=-1>";
		}
		print $links[$i] . "<br>";	
	} 
	%>	
	</font>
	</td>
	</tr>
	</table>
	<hr size=1>
	<p>
<%
}

for $data (@order) { 
	%>
	<p>
	<a name=<%=$Server->URLEncode($data->{name})%>></a>
	<%=pod2html($data->{body}, $data->{name}, $data->{level})%>
	<%
}
%>

</td>
</tr>
<tr bgcolor=#555555>
	<td colspan=2 align=center width=80%>
	<font face=verdana color=white size=-1><%=$copy->{body}%></font>
	</td>
</tr>
</table>
</body>
</html>
