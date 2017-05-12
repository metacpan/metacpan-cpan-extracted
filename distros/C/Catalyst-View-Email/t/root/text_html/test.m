<%args>
$time
$email
</%args>
<html>
 <body>
  <h1>Look at my style</h1>
  <p>I was sent to <em><% $email->{to} %></em> on <% $time %></p>
 </body>
</html>

