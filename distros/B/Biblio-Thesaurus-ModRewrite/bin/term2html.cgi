#!/usr/bin/perl

use lib '/home/smash/LOCAL/mestrado/natura/Biblio/modrewrite.r6656/lib';

use CGI qw/:standard/;

$ARGV[0] = param('t');
$ARGV[1] = '/home/smash/LOCAL/mestrado/natura/Biblio/modrewrite.r6656/examples/geografia.iso';

use Biblio::Thesaurus;
use Biblio::Thesaurus::ModRewrite;

my $code = <<"EOF";
$ARGV[0] \$r \$t => sub{{ print "  <tr align=center><td bgcolor=FF9900><a href='?t=$ARGV[0]'>$ARGV[0]</a></td><td bgcolor=FFCC00>\$r</td><td bgcolor=FFCC00><a href='?t=\$t'>\$t</a></td></tr>\\n"; }}.
\$t \$r $ARGV[0] => sub{{ print "  <tr align=center><td bgcolor=FFCC00><a href='?t=\$t'>\$t</a></td><td bgcolor=FFCC00>\$r</td><td bgcolor=FF9900><a href='?t=$ARGV[0]'>$ARGV[0]</a></td></tr>\\n"; }}.
EOF

my $obj = thesaurusLoad($ARGV[1]);
$t = Biblio::Thesaurus::ModRewrite->new($obj);

print "Content-type: text/html\n\n";
#print "<pre>$code</pre>";
print "<center><h2>Relations for term <div style=\"color: FF9900\">$ARGV[0]</div></h2><table><tr style=\"color: white\" bgcolor=000000 align=center><td>Term</td><td>Relation</td><td>Term</td></tr>\n";
$t->process($code);
print "</table></center>\n";
