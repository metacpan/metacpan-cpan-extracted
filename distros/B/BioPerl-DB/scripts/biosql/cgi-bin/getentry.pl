#!/usr/bin/perl

BEGIN {
    unshift(@INC,"/Users/birney/src/bioperl-live");
    unshift(@INC,"/Users/birney/src/bioperl-db");
};

use CGI;
use Bio::DB::BioDB;
use Bio::Seq::RichSeq;
use Bio::SeqIO;


my $q = new CGI;                        # create new CGI object
print $q->header;                    # create the HTTP header

my $value = $q->param('acc');

my $host   = "localhost";
my $dbname = "bioseqdb";
my $driver = "mysql";
my $dbuser = "root";
my $dbpass = undef;

my $biodbname = "bioperl";

my $seq;

eval {    

    my $db = Bio::DB::BioDB->new(-database => "biosql",
				 -host     => $host,
				 -dbname   => $dbname,
				 -driver   => $driver,
				 -user     => $dbuser,
				 -pass     => $dbpass,
				 -verbose  => 10,
				 );
    
    my $seqadaptor = $db->get_object_adaptor('Bio::SeqI');
    
    $seq = Bio::Seq::RichSeq->new( -accession_number => $value, -namespace => $biodbname , -seq_version => 0, -entry_version => 0, -version => 0);
    
    $seq = $seqadaptor->find_by_unique_key($seq);
};

if( $@ || !defined $seq) {
    print "Got fetch exception of...\n<pre>$@\n</pre>";
    exit(0);
}

print "<title>BioSQL display of ". $seq->display_id ."</title>\n";
print qq{<LINK REL="stylesheet" HREF="http://www.mozilla.org/persistent-style.css" TYPE="text/css">\n};
print "<body>\n";

print "<TABLE>\n";
print "<TR>\n";
print "<TD VALIGN=TOP WIDTH=\"40%\">\n";

&print_box_start("Name and Species");
print $seq->display_id. "<p>".$seq->species->binomial."\n";
&print_box_end();

print "</TD>\n";
print "<TD VALIGN=TOP WIDTH=\"60%\">\n";

&print_box_start("Description");

print $seq->description,"\n";

&print_box_end();

print "</TR>\n";
print "<TR VALIGN=TOP>\n";

print " <TD VALIGN=TOP WIDTH=\"40%\">\n";
&print_box_start("Sequence");

my $seq_string = $seq->seq();
print "<pre>\n";
print "&gt;".$seq->display_id."\n";
$seq_string =~ s/(.{1,40})/$1\n/g;
print $seq_string,"\n";
print " </pre>\n";

&print_box_end();

print " </TD>\n";

print " <TD VALIGN=TOP WIDTH=\"60%\">\n";
&print_box_start("Comments");
# assumme each comment takes about 4 lines
my $max_comments = int((int($seq->length / 40)) /4);



my ($swiss_comment) = $seq->annotation->get_Annotations('comment');
# swissprot has comments as one blob. Split into multiples
$swiss_text = $swiss_comment->text();
$swiss_text =~ s/\-\-\-\-\-\-\-\-\-\-\-.*$//g;

#print "Using text [$swiss_text]\n";

@text = split(/\-\!\-/,$swiss_text);
my @comments;

foreach my $text ( @text ) {
    if( $text =~ /^\s*$/ ) {
	next;
    }
    #print "Building comment from $text\n";
    $text =~ s/\s/ /g;
    my $comment = Bio::Annotation::Comment->new( -text => $text);
    push(@comments,$comment);
}


my $comment_len = scalar(@comments);

#print "Got $max_comments<p>\n";

if( $max_comments < 3 ) {
    $max_comments = 3;
}

for($i=0;$i < $max_comments && $i < $comment_len;$i++) {
    print $comments[$i]->text();
    print "<p>\n";
}

if( $i < $comment_len ) {
    print "$comment_len Comments, only $i shown [Expand comments]\n";
}

&print_box_end();


print "</TR>\n";
print "<TR VALIGN=TOP>\n";
print "<TD VALIGN=TOP WIDTH=\"40%\">\n";

&print_box_start("Links to Other databases");
print "   <TABLE>\n";
foreach $dblink ( $seq->annotation->get_Annotations('dblink') ) {
    print "<TR><TD>",$dblink->database,"</TD><TD>",$dblink->primary_id,"</TD></TR>\n";
}
print "   </TABLE>\n";
&print_box_end();

print "</TD>\n";
print "<TD VALIGN=TOP WIDTH=\"60%\">\n";

&print_box_start("References");

$max_references = int(scalar($seq->annotation->get_Annotations('dblink'))/3);
if( $max_references < 2 ) {
    $max_references = 2;
}
my @references = $seq->annotation->get_Annotations('reference');

my $reference_len = scalar(@references);

for($i=0;$i<$reference_len && $i < $max_references;$i++) {
    my $reference = $references[$i];
    print $reference->title," ",$reference->authors,"<p>\n";
}
if( $i < $reference_len ) {
    print "$reference_len References, only $i shown [Expand References]\n";
}

&print_box_end();

print "</TD>\n";

print "</TR>\n";

print "</TABLE>\n";

exit(0);



print " <td>\n";
print " Comments<p>\n";



print " </td>\n";
print "</tr>\n";



print "<tr>\n";
print " <td>\n";
print "  Links<p><ul>\n";
print "</ul></td>\n";

# assumme 3 references per link


print "</td>\n";

print " </table>\n";



sub print_box_start {
    my $title = shift;

    print qq{<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%"\n};
    print qq{<TR> <TD CLASS="bordercell">\n};
    print qq{<TABLE BORDER="0" CELLSPACING="4" CELLPADDING="4" WIDTH="100%"\n};
    
    print qq{<TR> <TD CLASS="titlecell"><B>$title</B></TD></TR>\n};
    print qq{<TR> <TD CLASS="contentcell">\n};

}

sub print_box_end {
    # close content cell
    print qq{</TR> </TD>\n};

    # close TABLES

    print qq{</TABLE></TABLE>\n};
}
