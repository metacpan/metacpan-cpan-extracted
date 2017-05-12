<% 
  my($args, $html) = @_;
  my %args = %$args;
%>
  <% if($args{href}) { %>
  <tr><td align=center>
     <a href="<%= $args{href} %>"><% 
       if($args->{image}) { 
         %><site:img src="$args{image}" alt="$args{title}" /><% 
       } else { 
         %><%= $args{title} %><% 
       } 
     %></a>
  </td></tr>
  <% } %>
  
  <tr><td>
  <%= $html %>
  <% if($args{'from'}) { %>
   <center>
    <br>
    <i>-- <%= $args{'from'} %></i>
   </center>
  <% } %>
  <hr size=1 width=80% >
  </td></tr>
