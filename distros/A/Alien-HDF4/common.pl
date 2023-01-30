use strict;
use warnings;
use Config;
use IO::All;

my $version = '0.06';

# Look for HDF4 includes/libs
# default locations:
my @HDF_lib_locations = (
    '/usr/lib64',
    '/usr/local/netcdf/lib',
    '/usr/local/lib',
    '/usr/local/lib64',
    '/usr/lib64/hdf',
    '/opt/local/lib',
    '/usr/lib',
    '/usr/lib/hdf',
    '/opt/lib',
    '/opt/hdf4/lib',
    split(/ /, $Config{libpth}),
);
my @HDF_inc_locations = (
    '/usr/local/include',
    '/usr/local/netcdf/include',
    '/opt/local/include',
    '/usr/include',
    '/usr/include/hdf',
    '/opt/include',
    '/opt/hdf4/include',
    $Config{usrinc},
);

sub get_version { $version }

# returns ($libpath, $libs)
sub findlibs {
    foreach my $libdir ( @HDF_lib_locations ) {
        return (
            $libdir, '-lmfhdfalt -ldfalt',
        ) if -e "$libdir/libdfalt.a";
        return (
            $libdir, '-lmfhdf -ldf',
        ) if -e "$libdir/libdf.a";
        return (
            $libdir, '-lmfhdf -lhdf -lxdr',
        ) if -e "$libdir/libhdf.a";
    }
    return;
}

# Look for the szip library, which HDF >= 4.2r0 needs, but older versions don't
# returns $szlibs, or '' if not
sub findsz {
    foreach my $libdir ( @HDF_lib_locations ) {
        return ("-lsz")
            if -e "$libdir/libsz.$Config{so}";
        return ("-lsz")
            if -e "$libdir/libsz$Config{lib_ext}";
    }
    return '';
}

# Look for the include files
# return ($incpath)
sub findinc {
    foreach my $incdir ( @HDF_inc_locations ) {
        return ($incdir) if -e "$incdir/hdf.h";
    }
    return;
}

# ($defs)
sub finddefs {
    if ($Config{archname} =~ /x86_64/) {
        return "-DSWAP -DNDEBUG -DHDF -DBIG_LONGS -DIA64 " .
                    "-D_BSD_SOURCE -DLINUX -DGCC32";
    } elsif ($Config{archname} =~ /i686/) {
        return "-DNDEBUG -D_BSD_SOURCE -DLINUX -DGCC32";
    }
    return ''; # not a failure
}

sub get_build {
    my ($libpath, $libs) = findlibs();
    my ($incpath) = findinc();
    my $defs = finddefs();
    my ($szlibs) = findsz();
    {
        cflags => qq{$defs "-I$incpath"},
        libs => qq{"-L$libpath" $libs -ljpeg -lz $szlibs},
    }
}

1;
