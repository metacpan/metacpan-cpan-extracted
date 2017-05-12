<table border=1 width=100%>
<% 
for (1..$_[0]) { 
	$Response->Include('row.inc', $_[0]);
} 
%>
</table>
