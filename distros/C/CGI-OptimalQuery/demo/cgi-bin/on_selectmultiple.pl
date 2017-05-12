#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../../lib"; # include project lib
chdir "$Bin/..";

use CGI();

print CGI::header(), 
'<!DOCTYPE html>
<html>
<body>
<form method=post>

<p>
select people: <br>
<table id=selectedpeople>
<thead><tr><td>Name</td><td>Email</td><td></td></tr></thead>
<tbody id=peoplepanel></tbody>
</table>
<button type=button onclick="window.open(\'people.pl?on_select=add_person,U_ID,NAME,EMAIL~noclose\');">add</button>
</p>

<script>

function escape_html(s) {
  return s.replace(/&/g, "&amp;").replace(/>/g, "&gt;").replace(/</g, "&lt;").replace(/"/g, "&quot;");
}

var selectedPeople = {};

// regenerate the people panel table body
function updatePeoplePanel() {
  var buf = "";

  // sort by name
  var ids = [];
  for (var id in selectedPeople) ids.push(id);
  ids = ids.sort(function(a,b) {
    if (selectedPeople[a].name < selectedPeople[b].name) return -1;
    if (selectedPeople[a].name > selectedPeople[b].name) return  1;
    return 0;
  });

  // generate table
  for (var i=0,l=ids.length; i<l; ++i) {
    var person_id = ids[i];
    var person = selectedPeople[person_id];

    buf += "<tr><td><input type=hidden name=person_id value="+person_id+">"
        + escape_html(person.name)  + "</td><td>"
        + escape_html(person.email) + "</td><td>"
        + "<button type=button onclick=\'delete selectedPeople["+person_id+"]; updatePeoplePanel();\'>x</button></td></tr>";
  }
  document.getElementById("peoplepanel").innerHTML = buf;
}

// called by OptimalQuery after user selects people
function add_person(id,name,email) {
  selectedPeople[id] = { name: name, email: email };
  updatePeoplePanel();
}

// enter starting people
add_person(10,"Joe Orange", "Joe.Orange@sdd.edu");
add_person(25,"Glen Yeed", "Glen.Yeed@sdd.edu");

</script>

</body>
</html>';
