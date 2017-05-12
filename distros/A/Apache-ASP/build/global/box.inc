<% 
  my($args, $html) = @_; 
  $args->{width} ||= '240';
%>

<!-- box.inc -->
<table width=<%= $args->{width } %> bgcolor=<%=$DarkRowColor%> border=1 cellpadding=3 cellspacing=0 >
 <% if($args->{title}) { %>
  <tr><td align=center><b>
    <font size=-1 color=white face=verdana,helvetica,arial>
      <nobr><%= $args->{title} %></nobr>
    </font></b>
  </td></tr>
 <% } %>

 <tr><td>
   <%= $html %>
 </td></tr>

</table>

