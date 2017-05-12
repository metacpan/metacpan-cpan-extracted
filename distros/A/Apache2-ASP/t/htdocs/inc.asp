<%@ OutputCache Duration="60" VaryByParam="someparam" VaryBySession="user_id" %>
<%
  my ($s, $context, $args) = @_;
  
  my $A = 0;
  for( 1...1_000 )
  {
    $A++;
  }# end for()
%>
Included! <%= join ":", 1...10 %>

