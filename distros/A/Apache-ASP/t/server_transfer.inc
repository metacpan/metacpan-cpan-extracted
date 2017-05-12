<%
my @args = @_;
$t->eok($args[0] eq 'TEST', 'Argument TEST passed through $Server->Transfer');
$t->done;
%>
