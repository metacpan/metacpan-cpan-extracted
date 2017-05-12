Before TrapInclude:
<%
  my $res = $Response->TrapInclude(
    $Server->MapPath("/pageparser/has-2-includes.asp")
  );
  $Response->Write( uc($res) );
%>
After TrapInclude:
