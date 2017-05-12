#!/usr/bin/perl 

# Get CGI variables
parse_form_data();

# Build HTML page
my $html  = "Content-type: text/html\n";
   $html .= "Status: 200 OK \n\n";
   $html .= "<html>\n";
   $html .= "<head>\n";
   $html .= "  <title>CGI::Browse Delete Sample Script</title>\n";
   $html .= "</head>\n";
   $html .= "<body>\n";

foreach my $key ( keys %FORM_DATA ) {
	$html .= " $key : $FORM_DATA{$key} <br>\n";
}

   $html .= "</body>\n";
   $html .= "</html>\n";

# Print page
print $html;

exit;

sub parse_form_data {
        local (*FORM_DATA) = @_;
        local ($method, $querystring, @kvpairs, $keyvalue, $key, $value);
        $method = $ENV{'REQUEST_METHOD'};

        if ($method eq "GET") {
        $querystring = $ENV{'QUERY_STRING'};
        }
        elsif ($method eq "POST") {
        read (STDIN, $querystring, $ENV{'CONTENT_LENGTH'});
        }
        else {
        error("Unsupported method");
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

sub error {
	my ( $msg ) = @_;
	my $html  = "Content-type: text/html\n";
	   $html .= "Status: 200 OK \n\n";
	   $html .= "<html>\n";
	   $html .= "<head>\n";
	   $html .= "  <title>CGI::Browse Module Sample Script</title>\n";
	   $html .= "</head>\n";
	   $html .= "<body>\n";
	   $html .= "$msg\n";
	   $html .= "</body>\n";
	   $html .= "</html>\n";
	print $html;
}

