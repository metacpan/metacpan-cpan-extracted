#!/usr/bin/perl

use Apache::ASP::CGI;
&Apache::ASP::CGI::do_self(Global => 'global_event_end', NoState => 1);

__END__

<% $t->not_ok; %>
