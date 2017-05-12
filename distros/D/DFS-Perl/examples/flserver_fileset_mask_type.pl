#! /usr/local/bin/perl

use DCE::DFS;

my ($flserver, $status) = DCE::DFS::flserver; $status and
    print "Error creating flserver - $status\n" and exit;

$flserver->fileset_mask_type($flserver->type_rw);

print "RW filesets:\n";

while (1) {
    my ($fileset, $status) = $flserver->fileset;
    
    last if $status == $flserver->status_endoflist;
    
    $status and print "Error creating fileset - $status\n" and exit;
	    
    print "     " . $fileset->name . "\n";
}
print "\n";

$flserver->fileset_reset;
$flserver->fileset_mask_type($flserver->type_ro);

print "RO filesets:\n";

while (1) {
    my ($fileset, $status) = $flserver->fileset;
    
    last if $status == $flserver->status_endoflist;
    
    $status and print "Error creating fileset - $status\n" and exit;
	    
    print "     " . $fileset->name . "\n";
}
print "\n";

$flserver->fileset_reset;
$flserver->fileset_mask_type($flserver->type_bk);

print "BK filesets:\n";

while (1) {
    my ($fileset, $status) = $flserver->fileset;
    
    last if $status == $flserver->status_endoflist;
    
    $status and print "Error creating fileset - $status\n" and exit;
	    
    print "     " . $fileset->name . "\n";
}








