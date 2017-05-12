
use strict;
use ExtUtils::MakeMaker;
BEGIN {
    require 'src/SpeedyMake.pl';
    import SpeedyMake qw(%write_makefile_common);
}

print <<END;

Optional mod_speedycgi support.

Mod_speedycgi increases performance under Apache by avoiding the fork/exec
overhead associated with each request under normal SpeedyCGI.  However, it
requires a working copy of "apxs" in your path, Apache with mod_so
support, and additional Apache configuration.

END
print "Compile mod_speedycgi (default no)? ";

my @dirs = qw(src speedy_backend speedy);
my $macro = $write_makefile_common{macro};
my $apache_module = 0;
if (<STDIN> =~ /y/i) {
    die "ERROR: Command 'apxs -q CC' failed.\n"
	unless $macro->{APACHE_APXS_WORKS};
    print "Compiling for Apache version $macro->{APACHE_VERSION}\n";
    push(@dirs, $macro->{MOD_SPEEDYCGI_DIR});
    $apache_module = 1;
}

WriteMakefile(
    NAME		=> 'CGI::SpeedyCGI',
    VERSION_FROM	=> 'src/SpeedyCGI.src',
    EXE_FILES		=> [qw(speedy/speedy speedy_backend/speedy_backend)],
    CONFIGURE		=> sub { return {DIR=>\@dirs} },
    PM			=> {'src/SpeedyCGI.pm'=>'$(INST_LIBDIR)/SpeedyCGI.pm'},
    MAN1PODS		=> {},
    MAN3PODS		=> {},
    dist		=> {DIST_DEFAULT => 'mydist'},
    realclean		=> {FILES => 'README README.html lib'},
    %write_makefile_common
);

package MY;

use ExtUtils::Embed;

sub postamble {
    my $extra = SpeedyMake->optdefs_cmds('src');
    my $test_install_extra;
    if ($apache_module) {
	my $mod_dir = $macro->{MOD_SPEEDYCGI_DIR};
	$extra .=
	    "\ninstall ::\n\tcd $mod_dir && \$(MAKE) install\n";
	$test_install_extra =
	    "\t\@cd $mod_dir && \$(MAKE) test_install \$(PASTHRU)\n";
    }

'
test_install:
	@cd speedy && $(MAKE) test_install $(PASTHRU)
' .
$test_install_extra .
'

mydist: README README.html lib/CGI/SpeedyCGI.pm readable tardist

readable:
	chown -R $(USER) .
	chmod -R u+w,go-w,go+r .

README: src/SpeedyCGI.pm
	cd src && $(PERL) -e "use Pod::Text; pod2text(-80)" <SpeedyCGI.pm >../README

README.html: src/SpeedyCGI.pm
	cd src && pod2html SpeedyCGI.pm >../README.html && $(RM_F) pod2h*

lib/CGI/SpeedyCGI.pm: src/SpeedyCGI.pm
	$(MKPATH) lib/CGI
	$(CP) src/SpeedyCGI.pm lib/CGI/SpeedyCGI.pm

MAKE_INDEX = $(PERL) -w ./util/build_index $(VERSION)

rpm: package

rpms: rpm

solpkg: package

sunpkg: solpkg

bsdpkg: package

package: all README README.html
	./util/build_package $(VERSION) $(INSTALLBIN) $(INSTALLSITELIB) $(APACHE_VERSION) $(APACHE_LIBEXECDIR) $(APACHE_SYSCONFDIR) $(MOD_SPEEDYCGI_DIR)
	$(MAKE_INDEX)
	@echo "*** Package files can be found in the binaries directory"

package_index:
	$(MAKE_INDEX)

' . $extra;
}
