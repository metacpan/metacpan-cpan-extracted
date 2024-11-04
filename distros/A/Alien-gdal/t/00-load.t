use strict;
use warnings;
use Test::More;
use Test::Alien;

BEGIN {
    use_ok('Alien::gdal') or BAIL_OUT('Failed to load Alien::gdal');
}

alien_ok 'Alien::gdal';

diag(
    sprintf(
        'Testing Alien::gdal %s, Perl %s, %s',
        $Alien::gdal::VERSION, $], $^X
    )
);

diag '';
diag 'Aliens:';
my %alien_versions;
foreach my $alien (qw /Alien::sqlite Alien::libtiff Alien::proj Alien::geos::af/) {
    my $have = eval "require $alien";
    next if !$have;
    diag sprintf "%s: version: %s, install type: %s", $alien, $alien->version, $alien->install_type;
    $alien_versions{$alien} = $alien->version;
}

my $have_ldd = !!`ldd --help`;
if (Alien::gdal->install_type eq 'share' && $have_ldd) {
    my $dylib = Alien::gdal->dist_dir . '/lib/libgdal.so';
    if (-e $dylib) {
        my @deps = `ldd $dylib`;
        my %collated;

        foreach my $line (@deps) {
            #  https://gdal.org/en/latest/development/building_from_source.html#conflicting-proj-libraries
            #  blunt approach but proj is the main culprit and there seem to be some legit double ups.
            next if not $line =~ 'libproj';

            $line =~ s/[\r\n]+//g;
            # diag $line;
            $line =~ s/^\s+//;
            my ($lib, $path) = split /\s+=>\s+/, $line, 2;
            # diag "$lib --- $path";
            $lib =~ s/\.so.+//;

            is $collated{$lib}, undef, "No duplicate dylib dep for $lib, also have $path.  Expect segfaults.";

            $collated{$lib} = $path;
        }
    }
}

done_testing();

