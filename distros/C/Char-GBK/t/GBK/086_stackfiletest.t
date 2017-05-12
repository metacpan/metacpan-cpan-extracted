# encoding: GBK
use GBK;
print "1..10\n";

my $__FILE__ = __FILE__;

open(FILE,'>file');
print FILE "\n";
close(FILE);

mkdir('directory',0777);

if (-r 'file') {
    print "ok - 1 -r 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 1 -r 'file' $^X $__FILE__\n";
}

if (-w 'file') {
    print "ok - 2 -w 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 2 -w 'file' $^X $__FILE__\n";
}

if (not -d 'file') {
    print "ok - 3 not -d 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 3 not -d 'file' $^X $__FILE__\n";
}

if (-r -w 'file') {
    print "ok - 4 -r -w 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 4 -r -w 'file' $^X $__FILE__\n";
}

if (not -r -w -d 'file') {
    print "ok - 5 -r -w -d 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 5 -r -w -d 'file' $^X $__FILE__\n";
}

if (-r 'directory') {
    print "ok - 6 -r 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 6 -r 'directory' $^X $__FILE__\n";
}

if (-w 'directory') {
    print "ok - 7 -w 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 7 -w 'directory' $^X $__FILE__\n";
}

if (-d 'directory') {
    print "ok - 8 -d 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 8 -d 'directory' $^X $__FILE__\n";
}

if (-r -w 'directory') {
    print "ok - 9 -r -w 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 9 -r -w 'directory' $^X $__FILE__\n";
}

if (-r -w -d 'directory') {
    print "ok - 10 -r -w -d 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 10 -r -w -d 'directory' $^X $__FILE__\n";
}

unlink('file');
rmdir('directory');

__END__
