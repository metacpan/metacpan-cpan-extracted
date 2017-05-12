#!/usr/bin/perl -w
# $Id: install-radius-db.PL,v 1.2 2004/12/18 04:51:17 andrew Exp $
my $source_dir = 'raddb';
my $raddb_dir = '/etc/raddb';

unless (-w $raddb_dir) {
    # Cannot write to the raddb directory
    unless (-x $raddb_dir) {
        # Perhaps it just does not exists, so it can be created?
        my @path = split('/', $raddb_dir);
        pop(@path);
        my $up = join('/', @path);
        unless (-w $up and mkdir($raddb_dir) ) {
            print STDERR "$raddb_dir directory does not exists and cannot be created\n";
            print STDERR "Default RADIUS dictionaries are not installed.\n";
            exit(0);
        } else {
            print "Created $raddb_dir\n";
        }
    } else {
        print STDERR "Cannot copy the dictionary files in $raddb_dir\n";
        print STDERR "Default RADIUS dictionaries are not installed.\n";
        exit(0);
    }
}
print "Installing the RADIUS dictionaries in $raddb_dir\n";
opendir(D, $source_dir);
while ($_ = readdir(D)) {
    next if m/^\./;
    my $dest = join('/', (split('/', $raddb_dir), $_));
    print "Copying $_ to $dest ";
    my $res = copyFile($source_dir.'/'.$_, $dest);
    print $res ? ($res > 0 ? "- done." : "- ignored.") : "- error!";
    print "\n";
}
closedir(D);

exit(0);

sub copyFile {
    my ($f1, $f2) = @_;
    unless (-f $f1) {
        return -1;
    }
    if (-e $f2) {
        return -1;
    }
    open(F1, $f1) or return;
    unless (open(F2,">$f2")) {
        close(F1); return;
    }
    while (<F1>) {
        print F2 $_;
    }
    close(F1); close(F2);
    return 1;
}
