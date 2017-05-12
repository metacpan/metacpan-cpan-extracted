use ExtUtils::MakeMaker;

use strict;

my $backhand_incdir;
my $apache_incdir;
my $apache_osdir;

BEGIN {
    foreach my $arg (@ARGV) {
        if ($arg =~ /BACKHAND_SRCDIR=(.*)/) {
            $backhand_incdir = $1;
        }
        if ($arg =~ /APACHE_SRCDIR=(.*)/) {
            $apache_incdir   = $1;
        }
    }

    if (! defined $backhand_incdir) {
        die "You must specify a BACKHAND_SRCDIR - the path to your\n"
          . "mod_backhand source tree";
    }
    if (! defined $apache_incdir) {
        die "You must specify an APACHE_SRCDIR - the path to your\n"
          . "apache 1.3.X source tree";
    }

    if (! -d $backhand_incdir) {
        die 'BACKHAND_SRCDIR is not a directory';
    }
    if (! -f "${backhand_incdir}/mod_backhand.h") {
        die 'mod_backhand.h not found';
    }
    if (! -f "${backhand_incdir}/serverstat.h") {
        die 'serverstat.h not found';
    }

    if (! -d $apache_incdir) {
        die 'APACHE_SRCDIR is not a directory';
    }
    $apache_osdir = $apache_incdir . '/os/unix';
    $apache_incdir .= '/include';
    if (! -f "${apache_incdir}/httpd.h") {
        die "${apache_incdir}/httpd.h not found";
    }
    if (! -f "${apache_incdir}/http_log.h") {
        die "${apache_incdir}/http_log.h not found";
    }

    @ARGV = grep !'BACKHAND_SRCDIR', @ARGV;
    @ARGV = grep !'APACHE_SRCDIR', @ARGV;

    print <<EOF;

** NOTICE **
The byPerl shared object file (byPerl.so on most unix platforms) is not
built or installed by default.  See the file README.byPerl for details.
** NOTICE **

EOF

}

WriteMakefile(
    'NAME'	   => 'Apache::Backhand',
    'VERSION_FROM' => 'Backhand.pm',
    'OPTIMIZE'     => '-O3',
    'OBJECT'       => 'Backhand.o magic_c_int.o',
    'INC'          => "-I. -I${backhand_incdir} -I${apache_incdir} "
                    . "-I${apache_osdir}",
    'realclean'    => { 'FILES' => 'byPerl.so byPerl.o' },
);

package MY;

sub postamble { '

byPerl: byPerl.$(DLEXT)

byPerl.$(DLEXT): Makefile byPerl$(OBJ_EXT)
	$(LD) -o $@ $(LDDLFLAGS) $(OTHERLDFLAGS) byPerl$(OBJ_EXT)

'; }
