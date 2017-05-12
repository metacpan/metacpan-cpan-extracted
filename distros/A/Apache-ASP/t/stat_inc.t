use Apache::ASP::CGI;

# only run test if Devel::Symdump is installed
eval "use Devel::Symdump;";
my $stat_inc = $@ ? 0 : 1;

&Apache::ASP::CGI::do_self(StatINC => $stat_inc);

__END__

<% use lib '.';	use T;	$t =T->new(); %>
<% 
  return unless $Server->Config('StatINC');
  $t->eok($Apache::ASP::StatINCReady, 'Apache::ASP StatINC Startup'); 
%>
<% $t->done; %>
