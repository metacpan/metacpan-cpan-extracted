#! /usr/bin/perl -w

use strict;
use CGI::Ajax;
use CGI;

my $func = sub {
  my $input = shift;
  my $i=6000000;
  while($i--){ }
  return "got input: $input " . 'done';
};


sub Show_HTML {
my  $html = <<EOT;

<html>
<head><title>CGI::Ajax Example</title>

<script type=text/javascript>
// these 2 functions provide access to the javascript events. Since
// is an object anything here will apply to any div that uses a
// cgi::ajx registered function. as a convenience, we send in the id
// of the current element (el) below. but that can also be accessed
// this.target;
// if these are not defined, no problem...
pjx.prototype.pjxInitialized = function(el){
  document.getElementById(el).innerHTML = 'Loading';
  document.getElementById(el).style.backgroundColor = '#ccc';
}

pjx.prototype.pjxCompleted = function(el){
  // here we use this.target:
  // since this is a prototype function, we have access to all of hte 
  // pjx obejct properties. 
  document.getElementById(this.target).style.backgroundColor = '#fff';
}

</script>
</head>
<body>
<form>
Enter Something:&nbsp;
  <input type="text" name="val1" id="val1" size="6" onkeyup="jsfunc( ['val1'], 'result' ); return true;"><br>
Enter Something:&nbsp;
  <input type="text" name="val2" id="val2" size="6" onkeyup="jsfunc( ['val2'], 'another' ); return true;"><br>
    <hr>
    <div id="result" style="border: 1px solid black;
          width: 440px; height: 80px; overflow: auto">
    </div>

    <div id="another" style="border: 1px solid black;
          width: 440px; height: 80px; overflow: auto">
    </div>
</form>
</body>
</html>

EOT

}

my $cgi = new CGI();  # create a new CGI object
my $pjx = new CGI::Ajax( 'jsfunc' => $func );
print $pjx->build_html($cgi,\&Show_HTML);
