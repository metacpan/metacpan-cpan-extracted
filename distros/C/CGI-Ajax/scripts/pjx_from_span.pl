#!/usr/bin/perl

use strict;
use warnings;

use CGI;
use CGI::Ajax;

my $cgi= CGI->new;

my $a= CGI::Ajax->new( 
                       'test_elt_html'  => \&test_elt_html
                     );

$a->DEBUG(2);
$a->JSDEBUG(2);

print $a->build_html( $cgi, \&html_page);

sub html_page

  { 
return <<EOH;
<html> 
<head> 
<script>
function test2(){
    alert(typeof document.getElementById('newtest'));  
}
</script>

</head>

  <body>
    <div id="test_div">test with div</div>
    <p><span id="test_span">test with span</span></p>
    <p id="test_p">test with p</p>
    
    <div id='newtest' > some stuff </div>
    <hr />

    <p><input type="button" onclick="test_elt_html( [ 'test_div' ], [ 'test_result_div' ]);" value="test div"></p>
    <div id="test_result_div"></div>

    <p><input type="submit" onclick="test_elt_html( [ 'test_span' ], [ 'test_result_span' ]);" value="test span"></p>
    <div id="test_result_span"></div>

    <p><input type="submit" onclick="test2();test_elt_html( [ 'newtest' ], [ 'test_result_p' ]);" value="test p"></p>
    <div id="test_result_p"></div>

</body>
</html>
EOH
;

  }


sub test_elt_html
  { my( $elt_html)= @_;
  print STDERR "IN:" . $elt_html , "\n";
    return $elt_html;
  }

