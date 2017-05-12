<%
my $input = $Request->{QueryString}{search} || $Request->{Form}{search};
my $copy = $input;
my %final = &search_words($copy);
my @final = keys %final;

$title = "Site Search";
%>

<!--#include file=header.inc-->
<center>
<form action=<%=basename($0)%> method=POST>
<input type=text size=30 name=search value="<%=$Server->HTMLEncode($input)%>" maxlength=50>
<input type=submit value=Search>
</form>
</center>

<% 
unless(@final) {
    %> No search performed. <%
      $Response->Include('footer.inc');
    $Response->End();
}

my($files, $matches) = &search_files(@final);

if(keys %$matches) {
  %>
       <b>Matches:</b>
       <tt>
       <%= join(", ", map { "$_: $matches->{$_}" } keys %$matches) %>
       </tt>
       <p>
  <%
} else {
    print "No matches found for your search.";    
}

print "<font size=-1>\n";
my $count = 0;
my $final_match = join('|', @final);
for my $file (reverse sort { $files->{$a} <=> $files->{$b} } keys %$files) {
    my $score = $files->{$file};
    $Response->Debug("listing ranked $file");
    my $file_data = $SDB{"FILE:$file"};
    my($title,$summary) = ($file_data->{'title'}, $file_data->{summary});
#    $Response->Debug($file_data);
    unless($title || $summary) {
	$Response->Debug("no data for $file");
	next;
    }
    unless(-e $file) {
	$Response->Debug("file $file is deleted");
	next;
    }   
    
    my $wrap_per_match = 200 / @final;
    my $head_match_size = int($wrap_per_match / 3);
    my $tail_match_size = int($wrap_per_match / 3 * 2);
    my %summary_matches;
    my $summary_match = '<b>...</b> ';
    $summary =~ s/\b(.{0,$head_match_size}\b)($final_match)\b(.{0,$tail_match_size}\b)/
    { 
	unless($summary_matches{lc($2)}++ >= 3) {
	    my($head, $mid, $tail) = ($1, $2, $3);
	    $head =~ s,\b($final_match)\b,<b>$1<\/b>,sgi;
	    $tail =~ s,\b($final_match)\b,<b>$1<\/b>,sgi;
	    $summary_match .= "$head<b>$mid<\/b>$tail <b>...<\/b> ";
	}
	'';
    }
    /esgix;
    my $rel_file = $file;
    $rel_file =~ s/^$CONF{FileRoot}\/?//;
    $title ||= $rel_file;
      %>
	   <b><%= ++$count %>.</b> 
	   <a href="<%= $CONF{SiteRoot}.'/'.$rel_file %>"><%=$title%></a>
	   <nobr><i>( Score: <%= $score %> )</i></nobr>
	   <br>
	   <%= $summary_match %> 
	   <br>
	   <p>
      <%    
	  ;
    $Response->Flush;
}
%>
</font>
<!--#include file=footer.inc-->
