<%
  $Server->RegisterCleanup(sub {
    $::cleanup_called = 1;
  });
%>ok...
