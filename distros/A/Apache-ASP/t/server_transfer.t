use Apache::ASP::CGI;
&Apache::ASP::CGI::do_self(NoState => 1, Debug => 0, UseStrict=>1);
$SIG{__DIE__} = \&Carp::confess;

__END__

<% use lib '.';	use T;	$t =T->new(); %>
<% $Server->Transfer('server_transfer.inc', 'TEST'); %>
