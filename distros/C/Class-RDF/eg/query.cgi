#!/usr/bin/perl -w

use CGI;
use Class::RDF;
use strict;

my %ns = (
    rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    rdfs => "http://www.w3.org/2000/01/rdf-schema#",
    foaf => "http://xmlns.com/foaf/0.1/",
    geo => "http://www.w3.org/2003/01/geo/wgs84_pos#"
);

#Class::RDF->set_db( "dbi:mysql:rdf", "sderle", "" );
Class::RDF->set_db("dbi:SQLite:/www/frot.org/sandigeo/register.db");
Class::RDF->define( %ns );

my $cgi = CGI->new;
my $pred = Class::RDF::Store->db_Main->selectcol_arrayref(q[
    select distinct value from node, statement
		         where node.id = statement.predicate
			 order by value asc ]);
my $dropdown = $cgi->popup_menu( -name => "predicate", -values => $pred );

print $cgi->header, <<End;
<html>
<body>
<form>
    $dropdown &nbsp;<input type=submit />
</form>
<hr />
End

if (my $arc = $cgi->param("predicate")) {
    print qq{<table>\n};
    my $iter = Class::RDF::Statement->search(predicate => Class::RDF::Node->new($arc));
    while  (my $st = $iter->next) {
	print qq{<tr>};
	print "<td>", $st->$_->value, "</td>"
	    for (qw( subject predicate object ));
	print qq{</tr>\n};
    }
    print qq{</table>\n};
}

print <<End;
</body>
</html>
End
