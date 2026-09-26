use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Find;
use File::Spec;

my $lib_dir = File::Spec->rel2abs( File::Spec->catdir( $Bin, '..', 'lib' ) );
my @files;

find( {
    wanted => sub {
        push @files, File::Spec->rel2abs($_) if /\.pm$/;
    },
    no_chdir => 1,
}, $lib_dir );

@files = sort @files;
plan tests => scalar(@files);

my @inc = ( "-I$lib_dir" );

for my $file (@files) {
    ( my $rel = $file ) =~ s{^\Q$lib_dir\E[\\/]}{}i;
    $rel =~ tr{\\}{/};

    my $out = `"$^X" @inc -c "$file" 2>&1`;
    my $status = $? >> 8;

    ok( $status == 0 && $out =~ /syntax OK/i, "Syntax OK: $rel" )
        or diag("Compilation failed for $rel:\n$out");
}
