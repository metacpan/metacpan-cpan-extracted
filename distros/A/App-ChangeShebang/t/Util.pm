package t::Util;
use strict;
use warnings;
use Exporter 'import';
use File::Temp ();
sub tempfile { File::Temp::tempfile( UNLINK => 1 ) }
sub tempdir  { File::Temp::tempdir(CLEANUP => 1) }

our @EXPORT = qw(tempfile tempdir spew slurp);

sub spew {
    my ($file, $content) = @_;
    open my $fh, ">:utf8", $file or die "open $file: $!\n";
    print {$fh} $content;
}
sub slurp {
    my $file = shift;
    open my $fh, "<:utf8", $file or die "open $file: $!\n";
    local $/; scalar(<$fh>);
}

1;
