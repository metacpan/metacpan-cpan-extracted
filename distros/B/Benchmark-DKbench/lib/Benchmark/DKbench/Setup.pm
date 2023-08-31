package Benchmark::DKbench::Setup;

use strict;
use warnings;

use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use File::Fetch;
use File::Path;
use File::ShareDir 'dist_dir';
use File::Spec::Functions;

=head1 NAME

Benchmark::DKbench::Setup - Setup utility module for DKbench Perl Benchmark

=head1 DESCRIPTION

This is a Setup module, part of the L<Benchmark::DKbench> distribution.

See POD on the main module for info.

=cut

sub cpan_packages {
    return qw(
O/OA/OALDERS/HTML-Parser-3.81.tar.gz
K/KE/KENTNL/HTML-Tree-5.07.tar.gz
N/NI/NIGELM/HTML-Formatter-2.16.tar.gz
K/KA/KAMELKEV/CSS-Inliner-4018.tar.gz
C/CJ/CJFIELDS/BioPerl-1.7.8.tar.gz
E/ET/ETHER/Moose-2.2206.tar.gz
D/DR/DROLSKY/DateTime-TimeZone-2.60.tar.gz
D/DR/DROLSKY/DateTime-1.59.tar.gz
D/DK/DKECHAG/Astro-Coord-Precession-0.03.tar.gz
D/DK/DKECHAG/Astro-Coord-Constellations-0.01.tar.gz
D/DK/DKECHAG/Image-PHash-0.3.tar.gz
D/DK/DKECHAG/Math-DCT-0.04.tar.gz
M/MI/MIK/CryptX-0.078.tar.gz
M/MI/MIK/Crypt-JWT-0.034.tar.gz
M/ML/MLEHMANN/JSON-XS-4.03.tar.gz
L/LE/LETO/Math-MatrixReal-2.13.tar.gz
T/TO/TONYC/Imager-1.019.tar.gz
);
}

sub cpan_versions {
    my @packages = cpan_packages();
    my %versions;
    foreach (@packages) {
        m#/([a-z]+)(?:-([a-z]+))?(?:-([a-z]+))?-([0-9.]+).tar.gz$#i;
        warn $_ unless $1;
        my $mod = $1;
        $mod .= "::$2" if $2;
        $mod .= "::$3" if $3;
        $versions{$mod} = $4;
    }
    return %versions;
}

sub datadir {
    return dist_dir("Benchmark-DKbench")
}

sub has_genbank {
    my $datadir = datadir();
    return -f catfile($datadir, "gbbct5.seq");
}

sub fetch_genbank {
    my $datadir = shift || datadir();
    return if -f catfile($datadir, "gbbct5.seq");
    print "Fetching gbbct5.seq of Genbank release 213...\n";
    mkpath $datadir unless -e $datadir;

    my $ff = File::Fetch->new(uri => 'http://ecuadors.net/files/gbbct5.seq.gz');
    my $where = $ff->fetch(to => $datadir) or die $ff->error;

    gunzip catfile($datadir, "gbbct5.seq.gz") => catfile($datadir, "gbbct5.seq")
        or die "gunzip failed: $GunzipError\n";
}

1;
