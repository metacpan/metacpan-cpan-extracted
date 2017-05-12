
<!--#include file=header.inc-->

<% 
$Response->{Clean} = 0;
use File::Basename;

my $file = $Request->QueryString('file');
if($file) {
    ## print contents of file here	
    local *FILE;
    my $basefile = &File::Basename::basename($file);
    $basefile =~ s/[^a-z\.\_]//sg;
    unless(open(FILE, $basefile)) {
	print "Can't read $basefile\n";
	$Response->End();
    }
    local $/ = undef;
    my $data = <FILE>;
    close FILE;
    $data =~ s|^\#\!\/[^\n]+\n||sg;
    $data =~ s/^\s+//s;
    $data =~ s/\s+$//s;
    my $escaped = $Server->HTMLEncode($data);
    $escaped =~ s/(&lt;%=?)(.*?)(%&gt;)/
	"<b><font color=#cc0000 face=\"courier new\">$1<font color=#000099>$2<\/font>$3<\/font><\/b>";
	/egsx;
    $escaped =~ s/(&lt;\!\-\-\s*\#include\s*file\s*\=)(.*?)(\-\-&gt;)/
      "<b><font color=#009900 face=\"courier new\">$1<font color=#555555>$2<\/font>$3<\/font><\/b>";
    /egsx;
    $escaped =~ s/(&lt;\/?)([\w-]+:[\w-]+)/$1\<font color=\#008000\><b>$2<\/b>\<\/font\>/isg;
    $escaped =~ s/(&lt;\/?)([a-z]+)/$1\<font color=#007070\><b>$2<\/b>\<\/font\>/isg;
    %>

<h3>Source of file <%=$file%>:</h3>
<pre>
<%= $escaped %>
</pre>	     

    <%	
} else {
    $Response->Write("No file to be displayed");
}
%>

<!--#include file=footer.inc-->


