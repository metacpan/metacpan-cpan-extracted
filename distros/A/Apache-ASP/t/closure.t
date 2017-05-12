use Apache::ASP::CGI;

use strict;
use vars qw($Temp);

$^W = 1;
$main::Temp = 0;
&Apache::ASP::CGI::do_self(UseStrict => 1, NoState => 1, Debug => 1);

__END__
<% 

eval { $Response->Include('closure.inc'); };
my $error = $@;
$t->eok($error, "include error");
$t->eok($error =~ /not stay shared/is ? 1 : 0, "not stay shared error");

# this part is to test that script with named subroutines do
# no get cached so the perl compilation will increment
$^W = 0;
my $ASP = $Server->{asp};
$Response->TrapInclude('closure.inc');
$t->eok($ASP->{compile_perl_count} == 3, $ASP->{compile_perl_count});
$Response->TrapInclude('closure.inc');
$t->eok($ASP->{compile_perl_count} == 4, $ASP->{compile_perl_count});

%>	

