package App::Mimosa::Util;
use Test::More;
use autodie qw/:all/;
use parent 'Exporter';
use File::Spec::Functions;

our @EXPORT_OK = qw/slurp clean_up_indices/;

# we need our own slurp because File::Slurp uses 3x the memory of the file that it is reading

sub slurp {
    my ($filename) = @_;
    my $content = '';
    open( my $fh, '<', $filename);
    while (<$fh>) { $content .= $_ };
    close $fh;
    return $content;
}

sub clean_up_indices {
    my ($dir, $name) = @_;
    for my $f (map { "$name.$_" } qw/nsi nhr nin nsd nsq psd psi phr psq pin/) {
        no autodie;
        # diag "unlink $dir/$f";
        unlink catfile($dir,$f);
    }
}

1;
