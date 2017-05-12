#!perl

use strict;
use warnings;
#use lib '../';
use AUBBC;
my $aubbc = AUBBC->new();

# Change some default settings
$aubbc->settings(
        protect_email => 4,
        html_type => 'xhtml',
        code_class => ' class="codepost"',
        code_extra => '<div style="clear: left"> </div>',
        quote_class => ' class="quote"',
        quote_extra => '<div style="clear: left"> </div>',
        highlight_class1 => ' class="highlightclass1"',
        highlight_class2 => ' class="highlightclass2"',
        highlight_class3 => ' class="highlightclass1"',
        highlight_class4 => ' class="highlightclass1"',
        highlight_class5 => ' class="highlightclass5"',
        highlight_class6 => ' class="highlightclass6"',
        highlight_class7 => ' class="highlightclass7"',
        highlight_class8 => ' class="highlightclass5"',
        highlight_class9 => ' class="highlightclass5"',
        );

# Add some tags to Build tags
  foreach my $tag (('cpan','google','wikisource','ws','wikiquote','wq','wikibooks','wb','wikipedia','wp')) {
  $aubbc->add_build_tag(
        name     => $tag,
        pattern  => 'all',
        type     => 1,
        function =>'main::other_sites',
        );
  }

  $aubbc->add_build_tag(
        name     => 'time',
        pattern  => '',
        type     => 3,
        function => 'main::other_sites',
        );

# This is so eather the print_list sub will run or the js_print
# if this file was ran on a web server
        $ENV{'QUERY_STRING'}
                ? $aubbc->js_print()
                : print_list->();

sub print_list {
# The list
my $message = <<'HTML';
[br][b]The Very common UBBC Tags[/b][br]
[[b]Bold[[/b] = [b]Bold[/b][br]
[[strong]Strong[[/strong] = [strong]Strong[/strong][br]
[[small]Small[[/small] = [small]Small[/small][br]
[[big]Big[[/big] = [big]Big[/big][br]
[[h1]Head 1[[/h1] = [h1]Head 1[/h1][br]
through.....[br]
[[h6]Head 6[[/h6] = [h6]Head 6[/h6][br]
[[i]Italic[[/i] = [i]Italic[/i][br]
[[u]Underline[[/u] = [u]Underline[/u][br]
[[strike]Strike[[/strike] = [strike]Strike[/strike][br]
[left]]Left Align[[/left] = [left]Left Align[/left][br]
[[center]Center Align[[/center] = [center]Center Align[/center][br]
[right]]Right Align[[/right] = [right]Right Align[/right][br]
[[em]Em[/em]] = [em]Em[/em][br]
[[sup]Sup[/sup]] = [sup]Sup[/sup][br]
[[sub]Sub[/sub]] = [sub]Sub[/sub][br]
[pre]]Pre[[/pre] = [pre]Pre[/pre][br]
[img]]http://www.google.com/intl/en/images/about_logo.gif[[/img] =
[img]http://www.google.com/intl/en/images/about_logo.gif[/img][br][br]
[url=URL]]Name[[/url] = [url=http://www.google.com]http://www.google.com[/url][br]
http[utf://#58]//google.com = http://google.com[br]
[email]]Email[/email] = [email]some@email.com[/email] Recommended Not to Post your email in a public area[br]
[code]]# Some Code ......
my %hash = ( stuff => { '1' => 1, '2' => 2 }, );
print $hash{stuff}{'1'};[[/code] =
[code]# Some Code ......
my %hash = ( stuff => { '1' => 1, '2' => 2 }, );
print $hash{stuff}{'1'};[/code][br]
[c]]# Some Code ......
my %hash = ( stuff => { '1' => 1, '2' => 2 }, );
print $hash{stuff}{'1'};[/c]] =
[c]# Some Code ......
my %hash = ( stuff => { '1' => 1, '2' => 2 }, );
print $hash{stuff}{'1'};[/c][br]
[[c=My Code]# Some Code ......
my %hash = ( stuff => { '1' => 1, '2' => 2 }, );
print $hash{stuff}{'1'};[/c]] =
[c=My Code]# Some Code ......
my %hash = ( stuff => { '1' => 1, '2' => 2 }, );
print $hash{stuff}{'1'};[/c][br][br]
[quote]]Quote[/quote]] =[br]
[quote]Quote[/quote][br]
[quote=Flex]]Quote[/quote]] =[br]
[quote=Flex]Quote[/quote][br]
[blockquote]]Your Text here[[/blockquote] = [blockquote]Your Text here[/blockquote][br]
[ul]][li]].....[/li]][li]].....[/li]][li]].....[/li]][/ul]] =
[ul]
[li]a.....[/li]
[li]b.....[/li]
[li]c.....[/li]
[/ul]
[ol]][li=1]].....[/li]][li]].....[/li]][li]].....[/li]][/ol]] =
[ol]
[li=1].....[/li]
[li].....[/li]
[li].....[/li]
[/ol]
[[list][[*=1].....[[*]....[[/list] =
[list]
[*=1].....
[*]....
[/list][br]
[color=Red]]Color[/color]] = [color=Red]Color[/color][br]
[b]Unicode Support[/b][br]
[utf://#x3A3]] = [utf://#x3A3][br]
[utf://#0931]] = [utf://#0931][br]
[utf://iquest]] = [utf://iquest][br]
 [hr]] = [hr]
[b]Built Tags[/b][br]
[[google://Google] = [google://Google] Search[br]
[[wp://Wikipedia:About] or  [wikipedia://Wikipedia:About] Wikipedia[br]
[[wb://Wikibooks:About] or [wikibooks://Wikibooks:About] Wikibooks[br]
[[wq://Wikiquote:About] or [wikiquote://Wikiquote:About] Wikiquote[br]
[[ws://Wikisource:About_Wikisource] or [wikisource://Wikisource:About_Wikisource] Wikisource[br]
[[cpan://Cpan] = [cpan://Cpan] Cpan Module Search[br]
[[time] = [time]
HTML

# replace the list with any error that may happen
$message = $aubbc->aubbc_error()
 ? $aubbc->aubbc_error()
 : $aubbc->do_all_ubbc($message);

print "Content-type: text/html\n\n";
print <<HTML;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>AUBBC.pm Tag List</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
</head>
<body>
<script type="text/javascript" src="?js_print">
</script>
<style type="text/css">
.codepost {
background-color: #ffffff;
 width: 80%;
 height: auto;
 white-space: nowrap;
 overflow: scroll;
 padding-left: 2px;
 padding-bottom: 5px;
 margin: 0;
 top: 0;
 left: 0;
 float: left;
 position: static;
}
.quote {
background-color: #ebebeb;
width:80%;
border:1px solid gray;
padding: 1px;
 margin: 1px;
 top: 0;
 left: 0;
 float: left;
 position: static;
}
.highlightclass1 {
 color : #990000;
 font-weight : normal;
 font-size : 10pt;
 text-decoration : none;
 font-family : Courier New, Latha, sans-serif;
}
.highlightclass2 {
 color : #0000CC;
 font-weight : normal;
 font-size : 10pt;
 font-style: italic;
 text-decoration : none;
 font-family : Courier New, Latha, sans-serif;
}
.highlightclass5 {
 color : #0000CC;
 font-weight : normal;
 font-size : 10pt;
 text-decoration : none;
 font-family : Courier New, Latha, sans-serif;
}
.highlightclass6 {
 color : black;
 font-weight : bold;
 font-size : 10pt;
 text-decoration : none;
 font-family : Courier New, Latha, sans-serif;
}
.highlightclass7 {
 color : #009900;
 font-weight : normal;
 font-size : 10pt;
 text-decoration : none;
 font-family : Courier New, Latha, sans-serif;
}
</style>
$message
</body>
</html>
HTML
exit;
}

sub other_sites {
 my ($tag_name, $text_from_AUBBC) = @_;

# cpan modules
 $text_from_AUBBC = AUBBC::make_link("http://search.cpan.org/search?mode=module&amp;query=$text_from_AUBBC",$text_from_AUBBC,'',1)
  if $tag_name eq 'cpan';

# wikipedia Wiki
 $text_from_AUBBC = AUBBC::make_link("http://wikipedia.org/wiki/Special:Search?search=$text_from_AUBBC",$text_from_AUBBC,'',1)
  if ($tag_name eq 'wikipedia' || $tag_name eq 'wp');

# wikibooks Wiki Books
 $text_from_AUBBC = AUBBC::make_link("http://wikibooks.org/wiki/Special:Search?search=$text_from_AUBBC",$text_from_AUBBC,'',1)
  if ($tag_name eq 'wikibooks' || $tag_name eq 'wb');

# wikiquote Wiki Quote
 $text_from_AUBBC = AUBBC::make_link("http://wikiquote.org/wiki/Special:Search?search=$text_from_AUBBC",$text_from_AUBBC,'',1)
  if ($tag_name eq 'wikiquote' || $tag_name eq 'wq');

# wikisource Wiki Source
 $text_from_AUBBC = AUBBC::make_link("http://wikisource.org/wiki/Special:Search?search=$text_from_AUBBC",$text_from_AUBBC,'',1)
  if ($tag_name eq 'wikisource' || $tag_name eq 'ws');

# google search
 $text_from_AUBBC = AUBBC::make_link("http://www.google.com/search?q=$text_from_AUBBC",$text_from_AUBBC,'',1)
  if $tag_name eq 'google';

# localtime()
 $text_from_AUBBC = '<b>['.scalar(localtime).']</b>'
  if $tag_name eq 'time';
 
 return $text_from_AUBBC;
}
