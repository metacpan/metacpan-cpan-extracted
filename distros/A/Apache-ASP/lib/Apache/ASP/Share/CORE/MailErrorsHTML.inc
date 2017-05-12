<% 
  my %args = @_;
%>
Subject: Apache::ASP Errors for <%= $args{FILE} %>

<html><body>
  <table border=0>
   <% for my $key ( qw( GLOBAL FILE REMOTE_ADDR REMOTE_USER HTTP_HEADERS QUERY FORM ) ) { 
       next unless defined $args{$key};
     %>
    <tr>
      <td align=right><b><%= $key %>:</b></td>
      <td><%= $args{$key} %></td>
    </tr>
   <% } %>
  </table>
 <%= $args{COMPILE_ERROR} || '' %>
</body></html>

