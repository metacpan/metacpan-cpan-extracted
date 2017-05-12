<%@Page %>
<%
  $Server->RegisterCleanup(sub {
    my @numbers = @{$_[0]};
    $ENV{CALLED_REGISTER_CLEANUP}++;
  }, ( 1...5 ));
%>
Hello

