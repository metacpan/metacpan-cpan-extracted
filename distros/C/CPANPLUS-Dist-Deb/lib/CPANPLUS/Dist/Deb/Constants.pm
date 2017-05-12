package CPANPLUS::Dist::Deb::Constants;

use strict;
use CPANPLUS::Error;
use CPANPLUS::Internals::Constants;

use IPC::Cmd                    qw[can_run];
use File::Spec;
use Locale::Maketext::Simple    Class => 'CPANPLUS', Style => 'gettext';

use vars qw[$VERSION @EXPORT];

use base 'Exporter';
use Package::Constants;
$VERSION    = '0.01';
@EXPORT     =  Package::Constants->list( __PACKAGE__ );

use constant DEB_BASE_DIR       => sub { my $conf = shift or return;
                                         my $perl = shift || $^X;
                                         require CPANPLUS::Internals::Utils;
                                         return File::Spec->catdir(
                                            $conf->get_conf('base'),
                                            CPANPLUS::Internals::Utils
                                               ->_perl_version(perl => $perl),
                                            $conf->_get_build('distdir'),
                                            'debian',
                                        );
                                };      

use constant DEB_DEBIAN_DIR     => sub { File::Spec->catfile( @_,
                                            'debian' )
                                };
use constant DEB_CHANGELOG      => sub { File::Spec->catfile( @_,
                                            DEB_DEBIAN_DIR->(), 'changelog' )
                                };
use constant DEB_COMPAT         => sub { File::Spec->catfile( @_,
                                            DEB_DEBIAN_DIR->(), 'compat' )
                                };
use constant DEB_SPEC_FILE_VERSION
                                => 4;
                                
use constant DEB_CONTROL        => sub { File::Spec->catfile( @_,
                                            DEB_DEBIAN_DIR->(), 'control' )
                                };
use constant DEB_RULES          => sub { File::Spec->catfile( @_,
                                            DEB_DEBIAN_DIR->(), 'rules' )
                                };
use constant DEB_COPYRIGHT      => sub { File::Spec->catfile( @_,
                                            DEB_DEBIAN_DIR->(), 'copyright' )
                                };
use constant DEB_README         => sub { File::Spec->catfile( @_,
                                                        DEB_DEBIAN_DIR->(), 
                                                        'README.Debian' ) 
                                };


use constant DEB_README_CONTENTS
                                => qq[

Note that this debian package is automatically generated from it's CPAN
counterpart. By releasing a package to CPAN we assume the license
permits automatic repackaging, but we do not guarantee this is the case!
This package still adheres to the license as mentioned in the original
package, even if the provided copyright file for this package states a
different license.

All packages presented here, or created by CPANPLUS::Dist::Deb in
general come without warranty or even fitness of use; use at your own
risk at your own discretion.

If licenses are of major concern to you DO NOT USE THIS PACKAGE but
stick to the official debian mirrors instead!

];

                                
use constant DEB_ARCHITECTURE   => sub { my $arch =
                                         `dpkg-architecture -qDEB_BUILD_ARCH`;
                                         chomp $arch; return $arch;
                                };

use constant DEB_DH_PERL_OPTS   => sub { use Config;
                                         return join " ", $Config{sitelib},
                                                          $Config{sitearch};
                                };

use constant DEB_SITEBIN_DIR    => sub { use Config;
                                         return $Config{installsitebin};
                                };       

use constant DEB_INSTALL_SITEBIN
                                => sub { my $loc = shift or return;
                                         return $loc eq 'site' 
                                            ?   'INSTALLSCRIPT=' .
                                                DEB_SITEBIN_DIR->()
                                            : '';
                                };

use constant DEB_MAKEMAKERFLAGS => sub { my $pre = shift;
                                         my $loc = $pre ? 'site' : 'vendor'; 
                                         return "INSTALLDIRS=$loc ".
                                                DEB_INSTALL_SITEBIN->($loc);
                                };                                                

use constant DEB_BUILDFLAGS     => sub { my $pre = shift;
                                         my $loc = $pre ? 'site' : 'vendor'; 
                                         return "installdirs=$loc ";
                                };                                                


use constant DEB_DISTDIR_PREFIX => sub { my $pre = shift || '';
                                         my $dir = $pre . 'lib';
                                         return $dir;
                                };

use constant DEB_DISTDIR        => sub { my $dist = shift or return;
                                         my $pre  = shift || '';
                                         my ($l)  = 
                                          $dist->parent->package_name =~ /^(.)/;
                                         
                                         return File::Spec->catdir(
                                            qw[main pool],
                                            DEB_DISTDIR_PREFIX->($pre),
                                            lc($l),
                                            $dist->status->package_name
                                         );
                                };


use constant DEB_BIN_BUILDPACKAGE
                                => sub {my $p = can_run('dpkg-buildpackage');
                                        unless( $p ) {
                                            error(loc(
                                                "Could not find '%1' in your ".
                                                "path --unable to generate ".
                                                "debian archives",
                                                'dpkg-buildpackage' ));
                                            return;
                                        }
                                        return $p;
                                };

                                ### leave out all .a and .so files
                                ### all properly shell escaped ;(
use constant DEB_DPKG_SOURCE_IGNORE
                                #=> '-i\(\?i:.\*.\(\?:so\|a\$\)\)';
                                => '-i.s?[oa]';

use constant DEB_PACKAGE_NAME   => sub {my $mod = shift or return;
                                        my $pre = shift || '';
                                        my $pkg = lc $mod->package_name;
                                        
                                        ### remove any weird '.|_pm' notations
                                        ### in the pkg name
                                        $pkg =~ s/(\.|_)pm//gi;
                                        
                                        my $deb = $pre . 'lib' . 
                                                    $pkg . '-perl';
                                                    
                                        $deb =~ s/[_+]/-/g; # no _ or + allowed!
                                        
                                        ### strip double leading 'lib'
                                        $deb =~ s/^(${pre}lib)lib/$1/;
                                        
                                        ### strip trailing '-perl-perl' unless
                                        ### module name actually ends 
                                        ### in 'perl'
                                        $deb =~ s/-perl-perl$/-perl/
                                            unless $mod->module =~ /perl$/i;
                                        
                                        return $deb;
                                };
                                
use constant DEB_ORIG_PACKAGE_NAME
                                => sub { my $mod = $_[0] or return;
                                         DEB_PACKAGE_NAME->( @_ ) . '_' .
                                         $mod->package_version . '.orig.' .
                                         $mod->package_extension;
                                };                                

use constant DEB_DEFAULT_PACKAGE_VERSION
                                => 1;
                                
use constant DEB_VERSION        => sub {my $mod = shift or return;
                                        my $ver = shift || 
                                                  DEB_DEFAULT_PACKAGE_VERSION;
                                        return $mod->package_version . 
                                                '-' . $ver;
                                };
use constant DEB_RULES_ARCH     => sub { return shift() ? 'any' : 'all'; };
use constant DEB_DEB_FILE_NAME  => sub {my $mod = shift() or return;
                                        my $dir = shift() or return;
                                        my $pre = shift() || '';
                                        my $xs  = shift() ? 1 : 0;
                                        my $ver = @_ ? shift() : undef;
                                        
                                        my $arch = $xs
                                            ? DEB_ARCHITECTURE->()
                                            : DEB_RULES_ARCH->();

                                        my $name = join '_',
                                            DEB_PACKAGE_NAME->($mod, $pre),
                                            DEB_VERSION->($mod, $ver),
                                            $arch .'.deb';
                                        return File::Spec->catfile(
                                                $dir, $name
                                            );
                                };

use constant DEB_METAFILE_PROGRAM       => sub { can_run('apt-ftparchive') };
use constant DEB_METAFILE_SOURCES       => 'sources';
use constant DEB_METAFILE_SOURCES_FILE  => 'Sources.gz';
use constant DEB_METAFILE_PACKAGES      => 'packages';
use constant DEB_METAFILE_PACKAGES_FILE => 'Packages.gz';
use constant DEB_DEFAULT_RELEASE        => 'unstable';                                

use constant DEB_OUTPUT_METAFILE 
                                => sub { my $type = shift or return;
                                         my $path = shift or return;
                                         my $rel  = shift ||
                                                    DEB_DEFAULT_RELEASE;

                                         ### sources.gz file                                         
                                         if( $type eq DEB_METAFILE_SOURCES ) {
                                            return File::Spec->catfile(
                                              $path, 'dists', $rel, 
                                              'main', 'source',
                                              DEB_METAFILE_SOURCES_FILE
                                            );
                                            
                                         ### packages.gz file  
                                         } elsif( $type eq 
                                                  DEB_METAFILE_PACKAGES 
                                         ) {
                                            return File::Spec->catfile(
                                              $path, 'dists', $rel, 'main',
                                              'binary-'.DEB_ARCHITECTURE->(),
                                              DEB_METAFILE_PACKAGES_FILE
                                            );
                                         
                                         ### dont know what you wanted
                                         } else {
                                            return;
                                         }
                                    };                    
         
         
                                
use constant DEB_LICENSE_GPL    => '/usr/share/common-licenses/GPL';
use constant DEB_LICENSE_ARTISTIC
                                => '/usr/share/common-licenses/Artistic';

use constant DEB_URGENCY        => 'urgency=low';
use constant DEB_DEBHELPER      => 'debhelper (>= 4.0.2)';

### since this will be installed in a versioned dir, we depend on at least
### this version of perl (all older perls paths will be included automatically
### by perl, unless you explicilty undefined 'inc_version_list' as a config
### argument
use constant DEB_THIS_PERL_DEPENDS
                                => sub { use Config; 
                                         "perl (>= $Config{version})" };
use constant DEB_PERL_DEPENDS   => '${perl:Depends}, ${misc:Depends}, ' .
                                    DEB_THIS_PERL_DEPENDS->();

                                         
use constant DEB_STANDARDS_VERSION
                                => '3.6.1';

use constant DEB_STANDARD_COPYRIGHT_PERL =>
    "This library is free software; you can redistribute it and/or modify\n" .
    "it under the same terms as Perl itself (GPL or Artistic license).\n\n" .
    "On Debian systems the complete text of the GPL and Artistic\n" .
    "licenses can be found at:\n\t" .
    DEB_LICENSE_GPL . "\n\t" . DEB_LICENSE_ARTISTIC;

use constant DEB_REPLACE_PERL_CORE
                                =>"perl-modules, perl-base, perl";


use constant DEB_FIND_DOCS      => sub { my $dir = shift or return;
                                         
                                         my $dh;
                                         unless( opendir $dh, $dir ) {
                                            error(loc("Could not open dir %1",
                                                        $dir));
                                            return;
                                         }
                                       
                                         my @docs = grep /README|TODO|BUGS|
                                                            NEWS|ANNOUNCE/ix,
                                                    readdir $dh;           
                                       
                                         ### return relative path!
                                         return @docs;
                                };

use constant DEB_FIND_CHANGELOG => sub { my $dir = shift or return;
                                         
                                         my $dh;
                                         unless( opendir $dh, $dir ) {
                                            error(loc("Could not open dir %1",
                                                        $dir));
                                            return;
                                         }
                                         
                                         my ($log) = grep /^change(s|log)$/i,
                                                            readdir $dh;
                                            
                                         ### return relative path!   
                                         return $log;
                                };

use constant DEB_GET_RULES_CONTENT  =>
                                    sub {my $self    = shift;
                                         my $pre     = shift || '';
                                         my $has_xs  = shift || 0;
                                         my $verbose = shift || 0;
                                         my $dist    = $self->status->dist;
                                         my $distdir = $dist->status->distdir;
                                         my $inst    =
                                                $self->status->installer_type;

                                         my $sub = $inst eq INSTALLER_BUILD
                                            ? $has_xs
                                                ? 'DEB_RULES_BUILD_XS_CONTENT'
                                                : 'DEB_RULES_BUILD_NOXS_CONTENT'
                                            : $has_xs
                                                ? 'DEB_RULES_MM_XS_CONTENT'
                                                : 'DEB_RULES_MM_NOXS_CONTENT';

                                         msg(loc("Using rule set '%1'", $sub),
                                                $verbose);
                
                                         my $docs = join ' ', DEB_FIND_DOCS->(
                                                                    $distdir );
                                         my $log  = DEB_FIND_CHANGELOG->(
                                                                    $distdir );

                                         my $loc = $pre ? 'site' : 'vendor';
                                         ### returns a coderef to a coderef
                                         my $code = __PACKAGE__->can($sub);
                                         return $code->()->($self, $loc,
                                                            $docs, $log );
                                    };


use constant DEB_RULES_MM_NOXS_CONTENT  =>
                            sub {
                                my $self    = shift;
                                my $loc     = shift or return;
                                my $docs    = shift || '';
                                my $changes = shift || '';
                                my $dh_opts = DEB_DH_PERL_OPTS->();
                                
                                my $inst_docs = "\t-dh_installdocs" . 
                                                ($docs ? " $docs" : '');
                                my $inst_changes = "\t-dh_installchangelogs" .
                                                ($changes ? " $changes" : '');
  
                                ### EU::MM doesn't have an 'installsitescript'
                                ### directive.. it just tosses everything in
                                ### 'installscript' which is /usr/bin/ which
                                ### is WRONG. M::B actually does the right 
                                ### thing here....
                                my $bindir  = DEB_INSTALL_SITEBIN->($loc);
                                    
                                return q[#!/usr/bin/make -f
# Uncomment this to turn on verbose mode.
#export DH_VERBOSE=1

# If set to a true value then MakeMaker's prompt function will
# always return the default without waiting for user input.
export PERL_MM_USE_DEFAULT=1

PACKAGE=$(shell dh_listpackages)

ifndef PERL
PERL = /usr/bin/perl
endif

TMP	=$(CURDIR)/debian/tmp


build: build-stamp
build-stamp:
	dh_testdir

	touch build-stamp

clean:
	dh_testdir
	dh_testroot

	dh_clean -d
	rm -f build-stamp install-stamp

install: install-stamp
install-stamp: build-stamp
	dh_testdir
	dh_testroot
	dh_clean -d -k

	$(MAKE) install DESTDIR=$(TMP) PREFIX=/usr
	@find . -type f | grep '/perllocal.pod$$' | xargs rm -f

	dh_movefiles /usr

	touch install-stamp

binary-arch:
# We have nothing to do by default.

binary-indep: build install
	dh_testdir
	dh_testroot

] . qq[

### doc/changelog install lines
$inst_docs
$inst_changes

]. q[

	dh_perl ] . $dh_opts . q[
	dh_link
	dh_compress
	dh_fixperms
	dh_installdeb
	dh_gencontrol
	dh_md5sums
	dh_builddeb

source diff:
	@echo >&2 'source and diff are obsolete - use dpkg-source -b'; false

binary: binary-indep binary-arch
.PHONY: build clean binary-indep binary-arch binary

];
                            };

use constant DEB_RULES_MM_XS_CONTENT
                        => sub {
                                my $self    = shift;
                                my $loc     = shift or return;
                                my $docs    = shift || '';
                                my $changes = shift || '';
                                my $dh_opts = DEB_DH_PERL_OPTS->();
                                
                                my $inst_docs = "\t-dh_installdocs" . 
                                                ($docs ? " $docs" : '');
                                my $inst_changes = "\t-dh_installchangelogs" .
                                                ($changes ? " $changes" : '');

                                        
                                ### EU::MM doesn't have an 'installsitescript'
                                ### directive.. it just tosses everything in
                                ### 'installscript' which is /usr/bin/ which
                                ### is WRONG. M::B actually does the right 
                                ### thing here....
                                my $bindir  = DEB_INSTALL_SITEBIN->($loc);
                                        
                                    return q[#!/usr/bin/make -f
# Uncomment this to turn on verbose mode.
#export DH_VERBOSE=1

# If set to a true value then MakeMaker's prompt function will
# always return the default without waiting for user input.
export PERL_MM_USE_DEFAULT=1

PACKAGE=$(shell dh_listpackages)

ifndef PERL
PERL = /usr/bin/perl
endif

TMP	=$(CURDIR)/debian/tmp

build: build-stamp
build-stamp:
	dh_testdir

	touch build-stamp

clean:
	dh_testdir
	dh_testroot

	dh_clean -d
	rm -f build-stamp install-stamp

install: install-stamp
install-stamp:
	dh_testdir
	dh_testroot
	dh_clean -d -k

	$(MAKE) install DESTDIR=$(TMP) PREFIX=/usr
	-find . -type f | grep '/perllocal.pod$$' | xargs rm -f
	
	dh_movefiles /usr

	touch install-stamp

# Build architecture-independent files here.
binary-indep: build install
# We have nothing to do by default.

# Build architecture-dependent files here.
binary-arch: build install
	dh_testdir
	dh_testroot

] . qq[

### doc/changelog install lines
$inst_docs
$inst_changes

]. q[

	dh_installexamples
	dh_link
	dh_compress
	dh_fixperms
	dh_makeshlibs
	dh_installdeb
	dh_perl ] . $dh_opts . q[
	dh_shlibdeps
	dh_gencontrol
	dh_md5sums
	dh_builddeb

source diff:
	@echo >&2 'source and diff are obsolete - use dpkg-source -b'; false

binary: binary-indep binary-arch
.PHONY: build clean binary-indep binary-arch binary

];
                                };

use constant DEB_RULES_BUILD_NOXS_CONTENT   => sub {
    my $self    = shift;
    my $loc     = shift or return;
    my $docs    = shift || '';
    my $changes = shift || '';
    my $dh_opts = DEB_DH_PERL_OPTS->();
    
    my $inst_docs = "\t-dh_installdocs" . 
                    ($docs ? " $docs" : '');
    my $inst_changes = "\t-dh_installchangelogs" .
                    ($changes ? " $changes" : '');

                                    return q[#!/usr/bin/make -f
# Uncomment this to turn on verbose mode.
#export DH_VERBOSE=1

# If set to a true value then MakeMaker's prompt function will
# always return the default without waiting for user input.
export PERL_MM_USE_DEFAULT=1

PACKAGE=$(shell dh_listpackages)

ifndef PERL
PERL = /usr/bin/perl
endif

BUILD = ./Build
TMP	=$(CURDIR)/debian/tmp


build: build-stamp
build-stamp:
	dh_testdir

	touch build-stamp

clean:
	dh_testdir
	dh_testroot

	dh_clean -d
	rm -f build-stamp install-stamp

install: install-stamp
install-stamp: build-stamp
	dh_testdir
	dh_testroot
	dh_clean -d -k

	$(PERL) $(BUILD) install destdir=$(TMP)
	-find . -type f | grep '/perllocal.pod$$' | xargs rm -f

	# due to a bug in M::B, the .packlist file is written to
	# the wrong directory, causing file conflicts:
	# http://rt.cpan.org/Ticket/Display.html?id=18162
	# remove it for now
	-find . -type f | grep '/.packlist$$' | xargs rm -f
	
	dh_movefiles /usr

	touch install-stamp

binary-arch:
# We have nothing to do by default.

binary-indep: build install
	dh_testdir
	dh_testroot

] . qq[

### doc/changelog install lines
$inst_docs
$inst_changes

]. q[

	dh_perl ] . $dh_opts . q[
	dh_link
	dh_compress
	dh_fixperms
	dh_installdeb
	dh_gencontrol
	dh_md5sums
	dh_builddeb

source diff:
	@echo >&2 'source and diff are obsolete - use dpkg-source -b'; false

binary: binary-indep binary-arch
.PHONY: build clean binary-indep binary-arch binary

];
                            };

use constant DEB_RULES_BUILD_XS_CONTENT   => sub {
    my $self    = shift;
    my $loc     = shift or return;
    my $docs    = shift || '';
    my $changes = shift || '';
    my $dh_opts = DEB_DH_PERL_OPTS->();
    
    my $inst_docs = "\t-dh_installdocs" . 
                    ($docs ? " $docs" : '');
    my $inst_changes = "\t-dh_installchangelogs" .
                    ($changes ? " $changes" : '');

                                    return q[#!/usr/bin/make -f
# Uncomment this to turn on verbose mode.
#export DH_VERBOSE=1

# If set to a true value then MakeMaker's prompt function will
# always return the default without waiting for user input.
export PERL_MM_USE_DEFAULT=1

PACKAGE=$(shell dh_listpackages)

ifndef PERL
PERL = /usr/bin/perl
endif

TMP	=$(CURDIR)/debian/tmp

BUILD = ./Build


build: build-stamp
build-stamp:
	dh_testdir

	touch build-stamp

clean:
	dh_testdir
	dh_testroot
	
	# Delete any .o files explicitly *just* to be safe
	-find . -name \*.o -print0 | xargs -r0 rm -f


	dh_clean -d
	rm -f build-stamp install-stamp

install: install-stamp
install-stamp:
	dh_testdir
	dh_testroot
	dh_clean -d -k

	# Add here commands to install the package into debian/tmp.
	$(PERL) $(BUILD) install destdir=$(TMP)
	-find . -type f | grep '/perllocal.pod$$' | xargs rm -f

	# due to a bug in M::B, the .packlist file is written to
	# the wrong directory, causing file conflicts:
	# http://rt.cpan.org/Ticket/Display.html?id=18162
	# remove it for now
	-find . -type f | grep '/.packlist$$' | xargs rm -f

	dh_movefiles /usr

	touch install-stamp

# Build architecture-independent files here.
binary-indep: build install
# We have nothing to do by default.

# Build architecture-dependent files here.
binary-arch: build install
	dh_testdir
	dh_testroot

] . qq[

### doc/changelog install lines
$inst_docs
$inst_changes

]. q[
	dh_installexamples
	dh_link
	dh_compress
	dh_fixperms
	dh_makeshlibs
	dh_installdeb
	dh_perl ] . $dh_opts . q[
	dh_shlibdeps
	dh_gencontrol
	dh_md5sums
	dh_builddeb

source diff:
	@echo >&2 'source and diff are obsolete - use dpkg-source -b'; false

binary: binary-indep binary-arch
.PHONY: build clean binary-indep binary-arch binary

];
                                };

1;
