#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../../lib"; # include project lib
chdir "$Bin/..";

use CGI();

print CGI::header(), 
"<!DOCTYPE html>
<html>
<head>
<script>
function set_person(id,name,email) {
  document.forms[0].user_id.value = id;
  document.getElementById('personlabel').textContent = name + ' ' + email;
}
</script>
</head>
<body>
<form method=post>

<p>
select a person: <br>
<span id=personlabel></span>
<button type=button onclick=\"window.open('people.pl?on_select=set_person,U_ID,NAME,EMAIL');\">..</button>
<input type=hidden name=user_id>
</p>

</body>
</html>";
