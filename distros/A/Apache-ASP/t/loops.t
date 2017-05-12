use Apache::ASP::CGI;
&Apache::ASP::CGI::do_self(NoState => 1);

__END__

<% use lib '.';	use T;	$t =T->new(); %>

<% 
my $count = 0;	
for(1..3) {
	$count++;
}
if($count == 3) {
	$t->ok;
} else {
	$t->not_ok("for loop didn't work");
}	

$count = 0;
while(1) {
	last if (++$count > 2);	
}
if($count == 3) {
	$t->ok;
} else {
	$t->not_ok("while loop didn't work");
}	

$t->done;
%>

