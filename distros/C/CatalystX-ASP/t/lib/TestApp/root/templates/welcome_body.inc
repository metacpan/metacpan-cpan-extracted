<%
use Data::Dumper;
local $Data::Dumper::Indent = 1;
local $Data::Dumper::Useqq = 1;
local $Data::Dumper::Terse = 1;

my ( $args, $html ) = @_;
%>
<div class="container" data-toggle="tooltip" data-placement="bottom" title="Welcome welcome welcome!">
  <h1><%= sprintf( "Welcome to %s!", $args->{appname} ) %></h1>
<%= $html %>
  <p>This application was started on <%= $args->{application_start_time} %></p>
  <p>This session has seen <%= $args->{session_request_count} %> requests so far!</p>
  <h1>Dumping the Session</h1>
  <pre>
<%= Dumper( $Session ) %>
  </pre>
</div>
