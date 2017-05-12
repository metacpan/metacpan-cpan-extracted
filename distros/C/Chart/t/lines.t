#!/usr/bin/perl -w

use Chart::Lines;

print "1..1\n";

$g = Chart::Lines->new;
$g->add_dataset( 'foo', 'bar', 'whee', 'ding', 'bat', );
$g->add_dataset( 3.2,   4.1,   9.8,    10,     11, );
$g->add_dataset( 8,     5.3,   3,      4,      5.1, );
$g->add_dataset( 5,     7,     2.3,    10,     12, );

%hash = (
    'title'               => 'Lines Chart',
    'legend_example_size' => 10,
    'grid_lines'          => 'true',
    'grey_background'     => 'false',
    'colors'              => {
        'text'       => [ 255, 0, 0 ],
        'grid_lines' => [ 240, 0, 0 ]
    }
);
$g->set(%hash);
$g->png("samples/lines.png");
print "ok 1\n";

#
#use Data::Dumper;
#my %hopts = $g->getopts();
##    print Dumper(\%hopts);
#
#
## OO Approach
#print "Key\tContents\n";
#foreach (keys %hopts )
#{
#    print "$_\t";
#    myDumpIt(\$hopts{$_});
#    print "\n";
#    my $i=1;
#}
#exit(0);
#
#sub myPrint
#{
#    my $val = shift;
#    if ( ref(\$val) eq 'SCALAR' )
#    {
#        print $val;
#    }
#    elsif ( ref($val) eq 'HASH' )
#    {
#
#    }
#}
#
#sub myDumpit
#{
#    my $rsomething = shift;  ## Reference
#    if ( ref $rsomething eq 'REF' )
#    {
#        myDumpIt($$rsomething);
#    }
#    if ( ref $rsomething eq 'ARRAY' )
#    {
#        print "[";
#        foreach my $val (@$rsomething)
#        {
#
#        }
#    }
#}
#
