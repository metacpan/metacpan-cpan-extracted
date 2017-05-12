#! /usr/bin/perl -w

use strict;
Same as ex1 except that data is sent only when the mouse is moved out of the field


package main ;
my $tester =  new Tester ; 
$tester->run ; 

package Tester ; 

use base qw(CGI::Application);
use CGI::Ajax;

sub setup {
    my $self = shift;
    $self->run_modes([qw(
        start
    )]);
}

sub Show_HTML {
my  $html = <<EOT;

<html>
<head><title>CGI::Ajax Example</title>

</head>
<body>
<form>
Enter Something:&nbsp;
  <input type="text" name="val1" id="val1" size="6" onMouseOut="jsfunc( ['val1'], 'result' ); return true;"><br>
Enter Something:&nbsp;
    <hr>
    <div id="result" style="border: 1px solid black;
          width: 440px; height: 80px; overflow: auto">
    </div>

</form>
</body>
</html>

EOT

}
sub calc {
    my $input = shift;
    return "got input: $input " ;
}

sub start {
    my $self = shift;

    my $pjx = new CGI::Ajax( 'jsfunc' => \&calc );
    $pjx->JSDEBUG(2);
    
    my $text = $pjx->build_html($self,\&Show_HTML );

    return $text ;
}

