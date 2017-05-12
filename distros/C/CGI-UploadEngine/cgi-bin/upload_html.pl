##################################################
## FileName: html.pl
## Author:   Roger Hall (rahall2@ualr.edu)
##################################################

sub parse_form_data {
	(*FORM_DATA) = @_;
	local ($method, $querystring, @kvpairs, $keyvalue, $key, $value);
	$method = $ENV{'REQUEST_METHOD'};

	if ($method eq "GET") {
    	$querystring = $ENV{'QUERY_STRING'};
	} 
	elsif ($method eq "POST") {
    	read (STDIN, $querystring, $ENV{'CONTENT_LENGTH'});
	} 
	else {
    	&Error ("Unsupported method");
  	}

	@kvpairs = split(/&/, $querystring);
	
	foreach $keyvalue (@kvpairs) {
    	($key, $value) = split (/=/, $keyvalue);

	    $value =~ tr/+/ /;
	    $value =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack ("C", hex ($1))/eg;
	    if (defined($FORM_DATA{$key})) {
			$FORM_DATA{$key} = join ("\0", $FORM_DATA{$key}, $value);
	    } else {
	      	$FORM_DATA{$key} = $value;
	    }
	}
}

sub nav {
	my $html;
	$html .= "<a href='$root_url" . "cgi-bin/form_eg.cgi'>Submit data</a><br>\n";
	$html .= "&nbsp; <br>\n";
	return $html; 
}

sub header {
	my ( $arg_ref ) = @_;

	print "Content-type: text/html\n";
	print "Status: 200 OK \n\n";

	print "<html>\n";
	print "<head> \n";
	print "	<title>$title</title> \n";
	print " <script language='javascript' src='http://binf-app.host.ualr.edu/js/ext-core/ext-core-debug.js'></script>\n";
	print "</head> \n";
	print "<body>\n";
	print "<table width='100%'>\n";
	print "  <tr>\n";
	print "    <td width='20%' valign='top' class='nav'>\n";
	print nav();
	print "    </td>\n";
	print "    <td>\n";
}

sub footer {
	print "    </td>\n";
	print "  </tr>\n";
	print "<table>\n";
	print "</body>\n";
	print "</html>\n"
}

sub redirect {
  print "Content-type: text/plain", "\n";
  print "Status: 302 ", "\n";
  print "Location: $_[0] ", "\n\n";
  exit;
}

return 1;  
