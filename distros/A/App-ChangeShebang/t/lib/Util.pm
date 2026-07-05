package Util;
use v5.24;
use warnings;
use experimental qw(lexical_subs signatures);

use Exporter 'import';
use File::Temp ();

our @EXPORT_OK = qw(tempdir spew slurp);

sub tempdir () {
    File::Temp::tempdir(CLEANUP => 1);
}

sub spew ($file, $content) {
    open my $fh, ">:utf8", $file or die "open $file: $!\n";
    print {$fh} $content;
}

sub slurp ($file) {
    open my $fh, "<:utf8", $file or die "open $file: $!\n";
    local $/; scalar(<$fh>);
}

1;
