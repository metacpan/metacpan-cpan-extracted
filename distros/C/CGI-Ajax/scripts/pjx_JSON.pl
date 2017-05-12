#! /usr/bin/perl -w
use strict;
use CGI::Ajax;
use CGI;

my $q = new CGI;

my $Show_Form = sub {
  my $html = "";
  $html .= <<EOT;
<HTML>
<HEAD><title>CGI::Ajax JSON Example</title>
<script>
  handle_return = function(vv){
    document.getElementById('object_display').innerHTML = vv; 
    eval(vv);  // this gives you 'var jsonObj' here in javascript;
//    alert(jsonObj); 
    var div = document.getElementById('parsed');
    div.innerHTML = "</b>key : value<b><br/>";
    for(var key in jsonObj){
      div.innerHTML += key + " => " + jsonObj[key] + "<br/>";
    }
      
  }
</script>
</HEAD>
<BODY>
<H2> Get The Letter Following the One you Enter </H2>
<form>
  Enter Number:
<input type="text" id="val1" size="6" value='abc' onkeyup="json(['val1'], [handle_return]);">
<br/><br/>The JavaScript Object:<br/>
<div id="object_display" style="width:500px;height:200px;">

</div>
<br/> After Parsing (use eval) <br/>
<div id="parsed" style="width:500px;height:200px;">

</div>

</form>
</BODY>
</HTML>
EOT

  return $html;
};

my $pjx = CGI::Ajax->new('json' => 'pjx_JSON_out.pl');
$pjx->JSDEBUG(1);
$pjx->DEBUG(1);
print $pjx->build_html($q,$Show_Form); # this outputs the html for the page
