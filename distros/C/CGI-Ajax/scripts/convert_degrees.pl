#! /usr/bin/perl -w

use strict;
use CGI;

my $q = new CGI;

print $q->header();

if ( defined $q->param('submit') or defined $q->param('Centigrade') or defined $q->param('Kelvin')) {
  my $result = "";
  if ( defined $q->param('Centigrade') and $q->param('Centigrade') ne "") {
    $result = $q->param('Centigrade') + 273.15;
  } elsif ( defined $q->param('Kelvin') and $q->param('Kelvin') ne "" ) {
    $result = $q->param('Kelvin') - 273.15;
  }
  print $result;
} else {
  print &Show_Form();
  print &Show_Footer();
}

sub Show_Form {
  my $html = "";
  $html .= <<EOT;
<HTML>
  <HEAD><title>Temperature Conversion</title>
</HEAD>
<BODY>
  <form>
  Temperature =<br>
  <input type="text" name="Centigrade" size="10"> degrees C<br>
  <input type="text" name="Kelvin" size="10"> degrees K<br>
  <input type="submit" name="submit" value="Convert">
  <input type="reset"><br>
  </form>
EOT

  return $html;
}

sub Show_Footer {
  print "</body></html>\n";
  return;
}
