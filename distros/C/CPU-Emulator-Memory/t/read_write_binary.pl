#!perl

use strict;
use warnings;

use Test::More;

sub read_binary {
    my($file) = @_;
    local $/ = undef;
    
    open(my $fh, $file) || die("Couldn't read $file\n");
    binmode($fh);
    return scalar(<$fh>);
}

sub write_binary {
    my($file, $bytes) = @_;
    
    open(my $fh, '>', $file) || die("Couldn't create $file\n");
    binmode($fh);
    print $fh $bytes;
}

# test these functions
unlink 'bytes.ram';
write_binary('bytes.ram', "\x01\x0D\x0A");
is(-s 'bytes.ram', 3, "binary file has correct size ...");
$_ = read_binary('bytes.ram');
is($_, "\x01\x0D\x0A", "... and correct content");
ok(unlink('bytes.ram'), "bytes.ram deleted");

1;

