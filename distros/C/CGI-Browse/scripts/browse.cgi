#!/usr/bin/perl 

use CGI::Browse;

# Get CGI variables
parse_form_data();

# Set variable values or defaults 
my %cgi_vars;
   $cgi_vars{index}    = $FORM_DATA{index}    ? $FORM_DATA{index}    : 0;
   $cgi_vars{window}   = $FORM_DATA{window}   ? $FORM_DATA{window}   : 20;
   $cgi_vars{sort}     = $FORM_DATA{sort}     ? $FORM_DATA{sort}     : '';
   $cgi_vars{sort_vec} = $FORM_DATA{sort_vec} ? $FORM_DATA{sort_vec} : 'asc';

# Create browse object
my $fields      = [ { name   => 'state_capital_id', label => 'ID',            hide => 1, sort => 0 },
                    { name   => 'state',            label => 'State',         hide => 0, sort => 1, link => 'link1', id => 0 },
                    { name   => 'statehood_year',   label => 'Statehood',     hide => 0, sort => 1 },
                    { name   => 'capital',          label => 'Capital',       hide => 0, sort => 1, link => 'link2', id => 0 },
                    { name   => 'capital_since',    label => 'Capital Since', hide => 0, sort => 1 },
                    { name   => 'most_populous',    label => 'Most Populous', hide => 0, sort => 1 },
                    { name   => 'city_population',  label => 'City Pop.',     hide => 0, sort => 1 },
                    { name   => 'metro_population', label => 'Metro Pop.',    hide => 1, sort => 1 },
                    { name   => 'notes',            label => 'Notes',         hide => 0, sort => 0 } ];

my $params      = { fields   => $fields,
                    sql      => "select state_capital_id, state, statehood_year, capital, capital_since, most_populous, city_population, metro_population, notes from state_capitals",
                    connect  => { db   => 'mydb', host => 'localhost', user => 'user', pass => 'pass' },
                    urls     => { root => 'http://www.ourpug.org/', browse => 'cgi-bin/eg/browse.cgi', link1 => 'cgi-bin/eg/browse_link1.cgi?id=', link2 => 'cgi-bin/eg/browse_link2.cgi?id=', delete => 'cgi-bin/eg/browse_delete.cgi?id=' },
                    #urls     => { root => 'http://www.ourpug.org/', browse => 'cgi-bin/eg/browse.cgi', link1 => 'cgi-bin/eg/browse_link1.cgi?id=', link2 => 'cgi-bin/eg/browse_link2.cgi?id=', delete => 'cgi-bin/eg/browse_delete.cgi' },
                    classes  => ['browseRowA', 'browseRowA', 'browseRowA', 'browseRowB', 'browseRowB', 'browseRowB'],
                    features => { default_html => 1, delete => 'each' },
                    #features => { default_html => 1, delete => 'multi' },
		  };
my $browse      = CGI::Browse->new( $params );

# Build HTML page
my $html  = "Content-type: text/html\n";
   $html .= "Status: 200 OK \n\n";
   $html .= "<html>\n";
   $html .= "<head>\n";
   $html .= "  <title>CGI::Browse Module Sample Script</title>\n";
   $html .= build_styles();  # Defines included styles
   $html .= "</head>\n";
   $html .= "<body>\n";
   $html .= $browse->build( \%cgi_vars );

#   $html .= build_tmpl();

   $html .= "</body>\n";
   $html .= "</html>\n";

# Print page
print $html;

exit;

sub build_styles {
	my $styles  = <<STYLES_END;

	<style type=\"text/css\">
		HTML                         { background-color:#FFFFFF; } 
		BODY                         { background-color:#FFFFFF; } 
		TD                           { font-family:arial; font-size:9pt; } 
		TD.browseHead                { background-color:#666666; color:white; padding-left:4; padding-right:4; text-align:left; } 
		TD.browseRowA                { background-color:#FFEEEE; font-size:9pt; padding-left:2; color:black; text-align:left; } 
		TD.browseRowB                { background-color:#FFDDDD; font-size:9pt; padding-left:2; color:black; text-align:left; } 
		A.browseHead:link            { color:#FFFFFF; text-decoration:underline; } 
		A.browseHead:visited         { color:#FFFFFF; text-decoration:underline; } 
		A.browseHead:hover           { color:#FFFFFF; text-decoration:underline; } 
		A.browseLink:link            { color:#660000; text-decoration:underline; } 
		A.browseLink:visited         { color:#660000; text-decoration:underline; } 
		A.browseLink:hover           { color:#660000; text-decoration:underline; } 
		A.browseDelete:link          { color:#000000; text-decoration:underline; padding-left:4; padding-right:4; } 
		A.browseDelete:visited       { color:#000000; text-decoration:underline; padding-left:4; padding-right:4; } 
		A.browseDelete:hover         { color:#000000; text-decoration:underline; padding-left:4; padding-right:4; } 
		A.browsePrevNextOn:link      { color:#000000; text-decoration:underline; font-size:9pt; } 
		A.browsePrevNextOn:visited   { color:#000000; text-decoration:underline; font-size:9pt; } 
		A.browsePrevNextOn:hover     { color:#000000; text-decoration:underline; font-size:9pt; } 
		font.browseInfo              { font-family:arial; text-align:left; line-height:110%; font-style:italic; font-size:10; } 
		font.browsePrevNextOff       { color:#999999; text-decoration:underline; font-size:9pt; } 
		font.browsePrevNextOff       { color:#999999; text-decoration:underline; font-size:9pt; } 
		font.browsePrevNextOff       { color:#999999; text-decoration:underline; font-size:9pt; } 
		.browseSmallBox              { font-family:arial; font-size:7pt; height:16; width:18; text-align:center; color:#660000; background-color:#EEEEEE; } 
		.browseSmallSelect           { font-family:arial; font-size:7pt; height:16; text-align:center; color:#660000; background-color:#EEEEEE; } 
		.browseSmallButton           { font-family:arial; font-size:7pt; height:16; text-align:center; color:#FFFFFF; background-color:#666666; } 
	</style>

STYLES_END
	return $styles;
}

sub build_tmpl {
	my $tmpl = <<END_OF_TMPL;
[% browse_script %]
<form name="browse" action="[% browse_action %]" method="POST">
<table cellspacing="0" cellpadding="0" width="100%">
  <tr>
    <td align="left" width="36%"> &nbsp; &nbsp; [% browse_sorted %]</td>
    <td align="center" width="34%">[% browse_start %]</td>
    <td align="right" width="30%">[% browse_prevnext %]</td>
  </tr>
</table>
[% browse_table %]
&nbsp; <br>
<table border="0" cellspacing="0" cellpadding="0" width="100%">
  <tr>
    <td width="50%">[% browse_show %]</td>
    <td width="50%" align="right">[% browse_goto %]</td>
  </tr>
  <tr>
    <td colspan="2">[% browse_control %]</td>
  </tr>
</table>
</form>

END_OF_TMPL
	return $tmpl;
}

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

