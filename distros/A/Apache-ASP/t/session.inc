<%
eval { $Session->Lock };
$t->eok($Session->Timeout > 1, "timeout check > 1");
$t->eok($Session->{Timeout} > 1, "timeout check > 1");
$t->eok(! $@, "\$Session->Lock: $@");
$t->eok(length($Session->{SessionID}) >= 8, "session id not long enough");
my $count = 0;
for(1..3) {
	$Session->{count}++;
	$count++;
	$t->eok($count == $Session->{count}, 
		'failure to increment $Session->{count}');
}
eval { $Session->UnLock() };
$t->eok(! $@, "\$Session->UnLock: $@");

$t->eok($Session->{count} == 3, "\$Session->{count} should equal 3 after locked critical section");
%>
