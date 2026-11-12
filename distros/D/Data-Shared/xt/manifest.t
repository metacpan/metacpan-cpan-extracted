use strict;
use warnings;
use Test::More;
use FindBin;
use Cwd qw(chdir);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
eval { require ExtUtils::Manifest; 1 } or plan skip_all => 'ExtUtils::Manifest required';

chdir "$FindBin::Bin/.." or die $!;
my @missing = ExtUtils::Manifest::manicheck();
my @extra = ExtUtils::Manifest::filecheck();
is_deeply \@missing, [], 'MANIFEST lists existing files' or diag explain \@missing;
is_deeply \@extra, [], 'no files missing from MANIFEST' or diag explain \@extra;

SKIP: {
    skip 'MYMETA.json needs a configured tree', 1 unless -e 'MYMETA.json';
    eval { require JSON::PP; 1 } or skip 'JSON::PP required', 1;
    my $meta = JSON::PP->new->decode(do {
        open my $fh, '<', 'MYMETA.json' or die $!; local $/; <$fh> });
    my @shipped = sort map { (my $m = $_) =~ s{^lib/|\.pm\z}{}g; $m =~ s{/}{::}g; $m }
        grep { m{\Alib/.*\.pm\z} } keys %{ ExtUtils::Manifest::maniread() };
    is_deeply [sort keys %{ $meta->{provides} || {} }], \@shipped,
        'provides names every module the dist ships';
}
done_testing;
