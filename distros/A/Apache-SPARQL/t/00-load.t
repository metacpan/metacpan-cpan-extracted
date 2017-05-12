BEGIN {print "1..1\n";}
END { print "not ok 1\n" unless $::loaded; };

sub ok
{
    my $no = shift ;
    my $result = shift ;
 
    print "not " unless $result ;
    print "ok $no\n" ;
}

use Apache::SPARQL;

$loaded = 1;
print "ok 1\n";
