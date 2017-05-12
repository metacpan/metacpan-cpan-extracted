package CPANPLUS::Dist::Arch;

use warnings 'FATAL' => 'all';
use strict;

use CPANPLUS::Dist::Base   qw();
use Exporter               qw(import);

our $VERSION     = '1.32';
our @EXPORT      = qw();
our @EXPORT_OK   = qw(dist_pkgname dist_pkgver);
our %EXPORT_TAGS = ( 'all' => [ @EXPORT_OK ] );
our @ISA         = qw(CPANPLUS::Dist::Base);

use File::Spec::Functions  qw(catfile catdir);
use Module::CoreList       qw();
use CPANPLUS::Error        qw(error msg);
use Digest::MD5            qw();
use Pod::Select            qw();
use List::Util             qw(first);
use File::Path 2.06_05     qw(make_path);
use File::Copy             qw(copy);
use File::stat             qw(stat);
use DynaLoader             qw();
use IPC::Cmd               qw(can_run);
use version                qw();
use English                qw(-no_match_vars);
use Carp                   qw(carp croak confess);
use Cwd                    qw();

#-----------------------------------------------------------------------------
# CLASS CONSTANTS
#-----------------------------------------------------------------------------


my $MKPKGCONF_FQP = '/etc/makepkg.conf';
my $CPANURL       = 'http://search.cpan.org';
my $ROOT_USER_ID  = 0;

my $CFG_VALUE_MATCH  = '\A \s* (%s) \s* = \s* (.*?) \s* (?: \#.* )? \z';

my $NONROOT_WARNING = <<'END_MSG';
In order to install packages as a non-root user (highly recommended)
you must have a sudo-like command specified in your CPANPLUS
configuration.
END_MSG

# Patterns to use when using pacman for finding library owners.
my $PACMAN_FINDOWN     = qr/\A.*? is owned by /;
my $PACMAN_FINDOWN_ERR = qr/\Aerror:/;

# Override a package's name to conform to packaging guidelines.
# Copied entries from CPANPLUS::Dist::Pacman and alot more
# from searching for packages with perl in their name in
# [extra] and [community]
my $PKGNAME_OVERRIDES =
{ map { split /[\s=]+/ } split /\s*\n+\s*/, <<'END_OVERRIDES' };

libwww-perl    = perl-libwww
aceperl        = perl-ace
mod_perl       = mod_perl

glade-perl-two = perl-glade-two
Gnome2-GConf   = gconf-perl
Gtk2-GladeXML  = glade-perl
Glib           = glib-perl
Gnome2         = gnome-perl
Gnome2-VFS     = gnome-vfs-perl
Gnome2-Canvas  = gnomecanvas-perl
Gnome2-GConf   = gconf-perl
Gtk2           = gtk2-perl
Cairo          = cairo-perl
Pango          = pango-perl

Perl-Critic    = perl-critic
Perl-Tidy      = perl-tidy
App-Ack        = ack
TermReadKey    = perl-term-readkey

END_OVERRIDES

# This var tells us whether to use a template module or our internal code:
my $TT_MOD_NAME;
my @TT_MOD_SEARCH = qw/ Template Template::Alloy Template::Tiny /;

sub _tt_block
{
    my $inside = shift;
    return qr{ \[% -?
               \s* $inside \s*
               (?: (?: -%\] \n* ) | %\] ) }xms;
}
my $TT_IF_MATCH  = _tt_block 'IF \s* (\w*)';
my $TT_END_MATCH = _tt_block 'END';
my $TT_VAR_MATCH = _tt_block '(\w+)';

# Crude template for our PKGBUILD script
my $PKGBUILD_TEMPL = <<'END_TEMPL';
# Contributor: [% packager %]
# Generator  : CPANPLUS::Dist::Arch [% version %]

pkgname='[% pkgname %]'
pkgver='[% pkgver %]'
pkgrel='[% pkgrel %]'
pkgdesc="[% pkgdesc %]"
arch=([% arch %])
license=('PerlArtistic' 'GPL')
options=('!emptydirs')
depends=([% depends %])
makedepends=([% makedepends %])
[% IF checkdepends -%]
checkdepends=([% checkdepends %])
[% END -%]
[% IF conflicts -%]
conflicts=([% conflicts %])
[% END -%]
url='[% url %]'
source=('[% source %]')
md5sums=('[% md5sums %]')
[% IF sha512sums -%]
sha512sums=('[% sha512sums %]')
[% END -%]
_distdir="[% distdir %]"

build() {
  ( export PERL_MM_USE_DEFAULT=1 PERL5LIB=""                 \
      PERL_AUTOINSTALL=--skipdeps                            \
      PERL_MM_OPT="INSTALLDIRS=vendor DESTDIR='$pkgdir'"     \
      PERL_MB_OPT="--installdirs vendor --destdir '$pkgdir'" \
      MODULEBUILDRC=/dev/null

    cd "$srcdir/$_distdir"
[% IF is_makemaker -%]
    /usr/bin/perl Makefile.PL
    make
[% END -%]
[% IF is_modulebuild -%]
    /usr/bin/perl Build.PL
    /usr/bin/perl Build
[% END -%]
  )
}

check() {
  cd "$srcdir/$_distdir"
  ( export PERL_MM_USE_DEFAULT=1 PERL5LIB=""
[% IF is_makemaker -%]
    make test
[% END -%]
[% IF is_modulebuild -%]
    /usr/bin/perl Build test
[% END -%]
  )
}

package() {
  cd "$srcdir/$_distdir"
[% IF is_makemaker -%]
  make install
[% END -%]
[% IF is_modulebuild -%]
  /usr/bin/perl Build install
[% END -%]

  find "$pkgdir" -name .packlist -o -name perllocal.pod -delete
}

# Local Variables:
# mode: shell-script
# sh-basic-offset: 2
# End:
# vim:set ts=2 sw=2 et:
END_TEMPL

=for Weird "/usr/bin/perl Build" Syntax
 We use "/usr/bin/perl Build" above instead of the normal "./Build" in
 order to make the yaourt packager happy.  Yaourt runs the PKGBUILD
 under the /tmp directory and makepkg will fail if /tmp is a seperate
 partition mounted with noexec.  Thanks to xenoterracide on the AUR for
 mentioning the problem.
 
 We also use /usr/bin/perl to ensure running the system-wide perl
 interpreter.

=cut

#----------------------------------------------------------------------
# CLASS GLOBALS
#----------------------------------------------------------------------

our ($Is_dependency, $PKGDEST, $SRCPKGDEST, $PACKAGER, $DEBUG);

$PACKAGER = 'Anonymous';

sub _DEBUG;
*_DEBUG = ( $ENV{DIST_ARCH_DEBUG}
            ? sub { print STDERR '***DEBUG*** ', @_, "\n" }
            : sub { return } );

#---HELPER FUNCTION---
# Purpose: Expand environment variables and tildes like bash would.
#---------------------
sub _shell_expand
{
    my $dir = shift;
    $dir =~ s/ \A ~             / $ENV{HOME}      /xmse;  # tilde = homedir
    $dir =~ s/ (?<!\\) \$ (\w+) / $ENV{$1} || q{} /xmseg; # expand env vars
    $dir =~ s/ \\ [a-zA-Z]      /                 /xmsg;
    $dir =~ s/ \\ (.)           / $1              /xmsg;  # escaped special
                                                          # chars
    return $dir;
}

READ_CONF:
{
    # Read makepkg.conf to see if there are system-wide settings
    my $mkpkgconf;
    if ( ! open $mkpkgconf, '<', $MKPKGCONF_FQP ) {
        error "Could not read $MKPKGCONF_FQP: $!";
        last READ_CONF;
    }

    my %cfg_vars = ( 'PKGDEST'    => \$PKGDEST,
                     'SRCPKGDEST' => \$SRCPKGDEST,
                     'PACKAGER'   => \$PACKAGER );

    my $cfg_field_match = sprintf $CFG_VALUE_MATCH,
        join '|', keys %cfg_vars;

    CFG_LINE:
    while (<$mkpkgconf>) {
        chomp;
        next CFG_LINE unless ( my ($name, $value) = /$cfg_field_match/xmso );

        ${ $cfg_vars{$name} } =
            ( $value =~ m/\A"(.*)"\z/
              ? _shell_expand( $1 ) # expand double quotes
              : ( $value =~ m/\A'(.*)'\z/
                  ? $1              # dont single quotes
                  : _shell_expand( $value )));
    }
    close $mkpkgconf or error "close on makepkg.conf: $!";
}

# Environment variable has second highest priority for PACKAGER.
$PACKAGER = $ENV{PACKAGER} if $ENV{PACKAGER};

#-----------------------------------------------------------------------------
# PUBLIC CPANPLUS::Dist::Base Interface
#-----------------------------------------------------------------------------


=for Interface Methods
See CPANPLUS::Dist::Base's documentation for a description of the
purpose of these functions.  All of these "interface" methods override
Base's default actions in order to create our packages.

=cut

#---INTERFACE METHOD---
# Purpose  : Checks if we have makepkg and pacman installed
# Returns  : 1 - if we have the tools needed to make a pacman package.
#            0 - if we don't think so.
#----------------------
sub format_available
{
    for my $prog ( qw/ makepkg pacman / ) {
        if ( ! can_run($prog) ) {
            error "CPANPLUS::Dist::Arch needs to run $prog, to work properly";
            return 0;
        }
    }
    return 1;
}

#---INTERFACE METHOD---
# Purpose  : Initializes our object internals to get things started
# Returns  : 1 always
#----------------------
sub init
{
    my $self = shift;

    $self->status->mk_accessors( qw{ pkgname  pkgver  pkgbase pkgdesc
                                     pkgurl   pkgsize arch    pkgrel
                                     builddir destdir metareqs

                                     pkgbuild_templ tt_init_args } );

    return 1;
}

#---INTERFACE METHOD---
# Purpose  : Prepares the files and directories we will need to build a
#            package.  Also prepares any data we expect to have later,
#            on a per-object basis.
# Return   : 1 if ok, 0 on error.
# Postcond : Sets $self->status->prepare to 1 or 0 on success or
#            failure.
#----------------------
sub prepare
{
    my $self = shift;

    my $status   = $self->status;                # Private hash
    my $module   = $self->parent;                # CPANPLUS::Module
    my $intern   = $module->parent;              # CPANPLUS::Internals
    my $conf     = $intern->configure_object;    # CPANPLUS::Configure
    my $distcpan = $module->status->dist_cpan;   # CPANPLUS::Dist::MM or
                                                 # CPANPLUS::Dist::Build

    # Call CPANPLUS::Dist::Base's prepare to resolve our pre-reqs.
    $self->SUPER::prepare( @_ ) or return 0;

    $self->_prepare_status;
    return $status->prepared;
}

#---PRIVATE METHOD---
# Purpose : Finds the first package file that matches our internal data.
#           (Meaning we might have built it)  We search for .tar.gz and
#           .tar.xz files.
# Note    : .tar.xz files have higher priority than .tar.gz files.
# Params  : $pkg_type - Must be 'bin' or 'src'.
#           $destdir  - The directory to search in for packages.
# Returns : The absolute path of the found package
#-------------------
sub _find_built_pkg
{
    my ($self, $pkg_type, $destdir) = @_;
    my $status = $self->status;

    my $arch = $self->status->arch;
    if ( $arch eq q{'any'} ) {
        $arch = 'any';
    }
    else {
        chomp( $arch = `uname -m` );
    }

    my $pkgfile = catfile( $destdir,

                           ( join q{.},

                             ( join q{-},
                               $status->pkgname,
                               $status->pkgver,
                               $status->pkgrel,

                               ( $pkg_type eq q{bin} ? $arch : qw// ),
                              ),

                             ( $pkg_type eq q{bin} ? q{pkg} : q{src} ),

                             q{tar},
                            ));

    _DEBUG "Searching for file starting with $pkgfile";

    my ($found) = grep { -f $_ } map { "$pkgfile.$_" } qw/ xz gz bz2 /;

    _DEBUG ( $found ? "Found $found" : "No package file found!" );

    return $found;
}

#---INTERFACE METHOD---
# Purpose  : Creates the pacman package using the 'makepkg' command.
#----------------------
sub create
{
    my ($self, %opts) = (shift, @_);

    my $status   = $self->status;                # Private hash
    my $module   = $self->parent;                # CPANPLUS::Module
    my $intern   = $module->parent;              # CPANPLUS::Internals
    my $conf     = $intern->configure_object;    # CPANPLUS::Configure
    my $distcpan = $module->status->dist_cpan;   # CPANPLUS::Dist::MM or
                                                 # CPANPLUS::Dist::Build

    my $pkg_type = $opts{pkg} || $opts{pkgtype} || 'bin';
    $pkg_type = lc $pkg_type;

    unless ( $pkg_type =~ /^(?:bin|src)$/ ) {
        error qq{Invalid package type requested: "$pkg_type"
Package type must be 'bin' or 'src'};
        return 0;
    }

    if ( $opts{verbose} ) {
        my %fullname = ( bin => 'binary', src => 'source' );
        msg "Creating a $fullname{$pkg_type} pacman package";
    }

    if ( $pkg_type eq 'bin' ) {
        # Use CPANPLUS::Dist::Base to make packages for pre-requisites...
        # (starts the packaging process for any missing ones)
        my @ok_resolve_args = qw/ verbose target force prereq_build /;
        my %resolve_args    = ( map { ( exists $opts{$_}  ?
                                        ($_ => $opts{$_}) : () ) }
                                @ok_resolve_args );

        local $Is_dependency = 1; # only top level pkgs explicitly installed

        $distcpan->_resolve_prereqs( %resolve_args,
                                     'format'  => ref $self,
                                     'prereqs' => $module->status->prereqs );
    }

    # Prepare our file name paths for pkgfile and source tarball...
    my $srcfile_fqp = $status->pkgbase . '/' . $module->package;

    my ($destenv, $destdir) = $self->_calc_setdest( $pkg_type );
    $destdir = $opts{'destdir'} || $status->destdir || $destdir;

    # Create directories for building and delivering the new package.
    MKDIR_LOOP:
    for my $dir ( $status->pkgbase, $destdir ) {
        if ( -e $dir ) {
            die "$dir exists but is not a directory!" unless ( -d _ );
            die "$dir exists but is read-only!"       unless ( -w _ );
            next MKDIR_LOOP;
        }

        make_path( $dir, { 'verbose' => $opts{'verbose'} ? 1 : 0 });
    }
    $destdir = Cwd::abs_path( $destdir );

    # Prepare our 'makepkg' package building directory,
    # namely the PKGBUILD and source tarball files...
    if ( ! -e $srcfile_fqp ) {
        my $tarball_fqp = $module->_status->fetch;
        link $tarball_fqp, $srcfile_fqp
            or error "Failed to create link to $tarball_fqp: $OS_ERROR";
    }

    $self->create_pkgbuild( $self->status->pkgbase );

    # Package it up!
    local $ENV{ $destenv } = $destdir;

    my @cmdopts = (($EUID == 0)         => '--asroot',
                   ($pkg_type eq 'src') => '--source',
                   $opts{'nocolor'}     => '--nocolor',
                   $opts{'skiptest'}    => '--nocheck',
                   $opts{'quiet'}       => '2>&1 >/dev/null');
    my $i = 0;
    while ($i < @cmdopts) {
        if ($cmdopts[$i]) {
            splice @cmdopts, $i++, 1;
        }
        else {
            splice @cmdopts, $i, 2;
        }
    }

    my $oldcwd = Cwd::getcwd();
    chdir $status->pkgbase or die "chdir: $OS_ERROR";
    my $makepkg_cmd = join q{ }, 'makepkg', '-f', @cmdopts;
    system $makepkg_cmd;

    if ( $CHILD_ERROR ) {
        error ( $CHILD_ERROR & 127
                ? sprintf "makepkg failed with signal %d", $CHILD_ERROR & 127
                : sprintf "makepkg returned abnormal status: %d",
                          $CHILD_ERROR >> 8 );
        return 0;
    }

    chdir $oldcwd or die "chdir: $OS_ERROR";

    my $pkg_path = $self->_find_built_pkg( $pkg_type, $destdir );
    $status->dist( $pkg_path );

    return $status->created( 1 );
}

#---INTERFACE METHOD---
# Purpose  : Installs the package file (.pkg.tar.xz) using sudo and
#            pacman.
# Comments : Called automatically on pre-requisite packages
#----------------------
sub install
{
    my ($self, %opts) = (shift, @_);

    my $status = $self->status;             # Private hash
    my $module = $self->parent;             # CPANPLUS::Module
    my $intern = $module->parent;           # CPANPLUS::Internals
    my $conf   = $intern->configure_object; # CPANPLUS::Configure

    my $pkgfile_fqp = $status->dist;
    unless ( $pkgfile_fqp ) {
        error << 'END_ERROR';
Path to package file has not been set.
Someone is using CPANPLUS::Dist::Arch incorrectly.
Tell them to call create() before install().
END_ERROR
        return 0;
    }

    die "Package file $pkgfile_fqp was not found" if ( ! -f $pkgfile_fqp );

    my @pacmancmd = ( 'pacman',
                      ($opts{'force'} ? '--force' : ()),
                      '--noconfirm',
                      ($Is_dependency ? '--asdeps' : '--asexplicit'),
                      '-U', $pkgfile_fqp,
                     );

    # Make sure the user has access to install a package...
    my $sudocmd = $conf->get_program('sudo');
    if ( $EFFECTIVE_USER_ID != $ROOT_USER_ID ) {
        if ( $sudocmd ) {
            unshift @pacmancmd, $sudocmd;
#            $pacmancmd = "$sudocmd pacman -U $pkgfile_fqp";
        }
        else {
            error $NONROOT_WARNING;
            return 0;
        }
    }

    system @pacmancmd;

    if ( $CHILD_ERROR ) {
        error ( $CHILD_ERROR & 127
                ? sprintf qq{'@pacmancmd' failed with signal %d},
                  $CHILD_ERROR & 127
                : sprintf qq{'@pacmancmd' returned abnormal status: %d},
                  $CHILD_ERROR >> 8
               );
        return 0;
    }

    return $status->installed(1);
}


#-----------------------------------------------------------------------------
# EXPORTED FUNCTIONS
#-----------------------------------------------------------------------------


sub dist_pkgname
{
    croak "Must provide arguments to dist_pkgname" if ( @_ == 0 );
    my ($distname) = @_;

    # Override this package name if there is one specified...
    return $PKGNAME_OVERRIDES->{$distname}
        if $PKGNAME_OVERRIDES->{$distname};

    # Package names should be lowercase and consist of alphanumeric
    # characters only (and hyphens!)...
    $distname =  lc $distname;
    $distname =~ tr/_/-/;
    $distname =~ tr/-a-z0-9+//cd; # Delete all other chars
    $distname =~ s/-[+]/-/g;      # + next to - looks weird
    $distname =~ s/[+]-/-/g;
    $distname =~ tr/-/-/s;

    # Delete leading or trailing hyphens...
    $distname =~ s/\A-//;
    $distname =~ s/-\z//;

    die qq{Dist name '$distname' completely violates packaging standards}
        if ( length $distname == 0 );

    # Don't prefix the package with perl- if it IS perl...
    $distname = "perl-$distname" unless ( $distname eq 'perl' );

    return $distname;
}

sub dist_pkgver
{
    my ($version) = @_;

    # Remove developer versions because pacman has no special logic
    # to handle comparing them to regular versions such as perl uses.
    $version =~ s/_[^_]+\z//;

    # Package versions should be numbers and decimal points only...
    $version =~ tr/-_/../;
    $version =~ tr/0-9.//cd;

    $version =~ tr/././s;
    $version =~ s/^[.]|[.]$//g;

    return $version;
}

=for Letters In Versions
  Letters aren't allowed in versions because makepkg doesn't handle them
  in dependencies.  Example:
    * CAM::PDF requires Text::PDF 0.29
    * Text::PDF 0.29a was built/installed
    * makepkg still complains about perl-text-pdf>=0.29 is missing ... ?
  So ... no more letters in versions.

=cut


#-----------------------------------------------------------------------------
# PUBLIC METHODS
#-----------------------------------------------------------------------------


sub set_destdir
{
    croak 'Invalid arguments to set_destdir' if ( @_ != 2 );
    my ($self, $destdir) = @_;
    $self->status->destdir($destdir);
    return $destdir;
}

sub get_destdir
{
    return shift->status->destdir
}

sub get_pkgpath
{
    shift->status->dist;
}

sub get_cpandistdir
{
    my ($self) = @_;

    my $module  = $self->parent;
    my $distdir = $module->status->dist_cpan->status->distdir;
    $distdir    =~ s{^.*/}{};

    return $distdir;
}

sub get_pkgname
{
    return shift->status->pkgname;
}

sub get_pkgver
{
    return shift->status->pkgver;
}

sub get_pkgrel
{
    my ($self) = @_;
    return $self->status->pkgrel;
}

sub set_pkgrel
{
    my ($self, $new_pkgrel) = @_;
    return $self->status->pkgrel( $new_pkgrel );
}

#---HELPER FUNCTION---
# Converts a specification aref into a pkg specification (i.e. depends).
# This can be used as a PKGBUILD field's value.
sub _specstr
{
    my ($a) = @_;
    my @strs;
    for my $x (@$a) {
        push @strs, join q{}, @$x;
    }
    return join ' ', map { qq{'$_'} } @strs;
}

sub get_pkgvars
{
    croak 'Invalid arguments to get_pkgvars' if ( @_ != 1 );

    my $self   = shift;
    my $status = $self->status;

    croak 'prepare() must be called before get_pkgvars()'
        unless ($status->prepared);

    my $pkglinks = $self->_get_pkg_rels;
    my @shavars;

    my %vars = (pkgname  => $status->pkgname,
                pkgver   => $status->pkgver,
                pkgrel   => $status->pkgrel,
                arch     => $status->arch,
                pkgdesc  => $status->pkgdesc,
                url      => $self->_get_disturl,
                source   => $self->_get_srcurl,
                md5sums  => $self->_calc_tarballmd5,
                pkglinks => $pkglinks,
    );
    if (eval { require Digest::SHA }) {
        $vars{'sha512sums'} = $self->_calc_shasum(512);
    }

    $vars{$_} = _specstr($pkglinks->{$_}) for (qw/depends makedepends/);
    for (qw/checkdepends conflicts/) {
        if (@{$pkglinks->{$_}}) {
            $vars{$_} = _specstr($pkglinks->{$_});
        }
    }
    
    return %vars;
}

sub get_pkgvars_ref
{
    croak 'Invalid arguments to get_pkgvars_ref' if ( @_ != 1 );

    my $self = shift;
    return { $self->get_pkgvars };
}

sub set_tt_init_args
{
    my $self = shift;

    croak 'set_tt_init_args() must be given a hash as an argument'
        unless @_ % 2 == 0;

    return $self->status->tt_init_args( { @_ } );
}

sub set_tt_module
{
    my ($self, $modname) = @_;

    return ( $TT_MOD_NAME = 0 ) unless $modname;

    croak qq{Failed to load template module "$modname"}
        unless eval "require $modname; 1;";

    _DEBUG "Loaded template module: $modname";

    return $TT_MOD_NAME = $modname;
}

sub get_tt_module
{
    _load_tt_module() unless defined $TT_MOD_NAME;

    return $TT_MOD_NAME;
}

sub set_pkgbuild_templ
{
    my ($self, $template) = @_;

    return $self->status->pkgbuild_templ( $template );
}

sub get_pkgbuild_templ
{
    my ($self) = @_;

    return $self->status->pkgbuild_templ() || $PKGBUILD_TEMPL;
}

sub get_pkgbuild
{
    croak 'Invalid arguments to get_pkgbuild' if ( @_ < 1 );
    my ($self) = @_;

    my $status  = $self->status;
    my $module  = $self->parent;
    my $conf    = $module->parent->configure_object;

    croak 'prepare() must be called before get_pkgbuild()'
        unless $status->prepared;

    my %pkgvars = $self->get_pkgvars;

    # Quote our package desc for bash.
    $pkgvars{pkgdesc} =~ s/ ([\$\"\`]) /\\$1/gxms;

    my $templ_vars = { packager  => $PACKAGER,
                       version   => $VERSION,
                       %pkgvars,
                       distdir   => $self->get_cpandistdir(),
                      };

    my $dist_type = $module->status->installer_type;
    @{$templ_vars}{'is_makemaker', 'is_modulebuild'} =
        ( $dist_type eq 'CPANPLUS::Dist::MM'    ? (1, 0) :
          $dist_type eq 'CPANPLUS::Dist::Build' ? (0, 1) :
          die "unknown Perl module installer type: '$dist_type'" );

    my $templ_text = $status->pkgbuild_templ || $PKGBUILD_TEMPL;

    return scalar $self->_process_template( $templ_text, $templ_vars );
}

sub create_pkgbuild
{
    croak 'Invalid arguments to create_pkgbuild' if ( @_ < 2 );
    my ($self, $destdir) = @_;

    croak qq{Invalid directory passed to create_pkgbuild: "$destdir" ...
Directory does not exist or is not writeable}
        unless ( -d $destdir && -w _ );

    my $pkgbuild_text = $self->get_pkgbuild();
    my $fqpath        = catfile( $destdir, 'PKGBUILD' );

    open my $pkgbuild_file, '>', $fqpath
        or die "failed to open new PKGBUILD: $OS_ERROR";
    print $pkgbuild_file $pkgbuild_text;
    close $pkgbuild_file
        or die "failed to close new PKGBUILD: $OS_ERROR";

    return;
}


#-----------------------------------------------------------------------------
# PRIVATE INSTANCE METHODS
#-----------------------------------------------------------------------------

#---HELPER METHOD---
# Caculates where we should store our built package.
# (does not take into account our $self->status state or parameters)
#
# Returns the environment variable we should override as well as the
# value we should set it to.
sub _calc_setdest
{
    my ($self, $pkg_type) = @_;

    my $destenv = ( $pkg_type eq 'src' ? 'SRCPKGDEST' : 'PKGDEST' );
    my $destdir = ( $ENV{ $destenv }
                    || ( $pkg_type eq 'src' ? $SRCPKGDEST : $PKGDEST )
                    || $self->_fallback_destdir );

    return ( $destenv, $destdir );
}

#---HELPER METHOD---
# Returns the default base directory that our separate build and
# package cache directories append themselves to.
# Example: ~/.cpanplus/5.12.1/pacman
sub _cpanp_user_basedir
{
    my $conf = shift->parent->parent->configure_object;
    return catdir( $conf->get_conf('base'),
                   ( sprintf '%vd', $PERL_VERSION ),
                   'pacman' );
}

#---HELPER METHOD---
# Returns the default package cache directory when no other directory
# is specified by many other means. This directory is inside the
# $HOME/.cpanplus directory for each different user.
sub _fallback_destdir
{
    catdir( shift->_cpanp_user_basedir, 'pkg' );
}


#-----------------------------------------------------------------------------
# PACKAGE RELATIONSHIP FUNCTIONS
#-----------------------------------------------------------------------------

#---HELPER FUNCTION--
# Merge two version operators, if possible.
#--------------------
sub _cmpvops
{
    my ($op, $x, $y) = @_;
    return 0 if ($x eq $y); # specs are identical

    ($x, $y) = (version->new($x), version->new($y));
    if ($op =~ /^</) {
        return ($x < $y ? -1 : 1);
    } elsif ( $op =~ /^>/ ) {
        return ($x > $y ? -1 : 1);
    } else {
        # We cannot merge specs other than <, <=, >, and >=.
        return undef;
    }
}

#---HELPER FUNCTION---
# Perform very simple comparison of version specs.
# Returns undef if no merging is possible,
# 0 if the specs are equal,
# -1 if the first spec is dominant,
# or 1 if the second specs is dominant.
#
# Checks for undefined versions which indicate a dependency on a module
# which is not the main module of the distribution. Version specs which define
# a version replace other specs with identical names, operators, and no version.
#
# We use the version module so this only works with perl/CPAN/numerical versions.
#---------------------
sub _cmpspecs
{
    my ($a, $b) = @_;
    my ($x, $y, $z);

    if ($a->[0] ne $b->[0] || $a->[1] ne $b->[1]) {
        # The most common case is that names won't even match.
        return undef;
    } elsif (defined ($x = $a->[2]) && defined ($y = $b->[2])) {
        return _cmpvops($a->[1], $x, $y);
    } elsif (!defined $x && defined $y) {
        return 1;
    } elsif (defined $x && !defined $y) {
        return -1;
    } else {
        # Both specs are identical with undef versions.
        return 0;
    }
}

#---HELPER FUNCTION---
# Normalize perl/CPAN version specifications. (we use numeric version cmp)
# Each spec is an aref containing a name, operator, and value.
# Sorts them and remove redundancies such as specs with the same name
# and operator.
#---------------------
sub _normspecs
{
    my ($a) = @_;
    return if (@$a == 0);

    @$a = sort _vspecs @$a;
    my $i = 0;
    my $x;
    while ($i < $#$a) {
        my $x = _cmpspecs($a->[$i], $a->[$i+1]);
        if (!defined $x) {
            $i++;
        } elsif ($x <= 0) {
            splice @$a, $i+1, 1;
        } else {
            splice @$a, $i, 1;
        }
    }
    return;
}

#---SORTING FUNCTION---
# Provided for use by the sort builtin, for sorting version specifications.
#----------------------
sub _vspecs
{
    our ($a, $b);
    $a->[0] cmp $b->[0] or $a->[1] cmp $b->[1];
}

sub _yankspecs (&$)
{
    my ($sub, $a) = @_;
    my @b;
    my $i = 0;
    local $_;
    while ($i <= $#$a) {
        $_ = $a->[$i][0];
        if ($sub->(@{$a->[$i]})) {
            push @b, splice(@$a, $i, 1);
        } else {
            $i++;
        }
    }
    return @b;
}

sub _yanktestmods
{
    _yankspecs { /^Test|^Pod::Coverage/ } shift;
}

sub _yankmakemods
{
    _yankspecs { /^ExtUtils-/ } shift;
}

sub _yankcoremods
{
    _yankspecs {
        my $v = $Module::CoreList::version{0+$]}{$_[0]};
        return ($v && (version->new($v) >= version->new($_[2])));
    } shift;
}

#---HELPER FUNCTION---
# Decide if the module is named after the distribution.
#---------------------
sub _ismainmod
{
    my ($m, $d) = @_;
    $m =~ tr/:/-/s;
    return (lc $m) eq (lc $d);
}

#---HELPER FUNCTION---
# Converts specifications upon modules into specifications upon distributions.
#---------------------
sub _distspecs
{
    my ($be, $a) = @_;
    for my $i ( 0 .. $#$a ) {
        my $mod = $a->[$i][0];
        next if ($mod eq 'perl');

        my ($x, $y);
        if (!($x = $be->module_tree($mod)) || !($y = $x->package_name)) {
            die "failed to find a CPAN distribution containing: $mod";
        }
        if (!_ismainmod($mod, $y)) {
            undef $a->[$i][2];
        }
        $a->[$i][0] = $y;
    }
}

#---HELPER FUNCTION---
# Converts specifications upon distributions into specifications upon packages.
#---------------------
sub _pkgspecs
{
    my ($a) = @_;
    for my $i (0 .. $#$a) {
        $a->[$i][0] = dist_pkgname($a->[$i][0]);
        my $v = $a->[$i][2];
        if (!defined $v) {
            $v = 0;
        } elsif ($a->[$i][0] eq 'perl') {
            $v = _transperlver($v);
        } else {
            $v = dist_pkgver($v);
        }
        $a->[$i][2] = $v;
    }
}

#---HELPER FUNCTION---
# Converts a decimal perl version (like $]) into the dotted decimal
# form that the official ArchLinux perl package uses.
#---------------------
sub _transperlver
{
    my ($perlver) = @_;

    # Fix perl-style vstrings which have a leading "v".
    return $perlver if ($perlver =~ s/\Av//);

    return $perlver unless ($perlver =~ /\A(\d+)[.](\d{3})(\d{1,3})\z/);

    # Re-apply the missing trailing zeroes.
    my $patch = $3;
    $patch .= q{0} x (3 - length($patch));
    return sprintf '%d.%d.%d', $1, $2, $patch;
}

#---HELPER FUNCTION---
# Translate a single CPAN dependency version specification.
sub _scanvspec
{
    my ($vspec) = @_;

    ## The module author forgot to specify a version in the (one) dependency.
    return 0 if (!defined $vspec);

    ## The simplest case is a version string.
    return $vspec if ($vspec =~ /^[0-9a-zA-Z._-]+$/);

    ## Combinations of complicated version specifications are also possible.
    my @specs;
    for my $opver (split /\s*,\s*/, $vspec) {
        if ($opver !~ /^([<>]=?|[!=]=) +([0-9a-zA-Z._-]+)$/) {
            die "invalid META version spec: $vspec"
        }
        my ($op, $ver) = ($1, $2);
        push @specs, [ $op, $ver ];
    }
    if (@specs == 0) {
        return 0;
    } else {
        return \@specs;
    }
}

sub _scanvspecs
{
    my ($specs, $deps, $cons) = @_;
    while (my ($k, $v) = each %$specs) {
        my $vs = _scanvspec($v); # $vs is either a version string or an array-ref.
        unless (ref $vs) {
            push @$deps, [ $k, '>=', $vs ];
            next;
        }
        for my $x (@$vs) {
            my ($op, $ver) = @$x;
            if ($op eq '!=') {
                ## When $cons is elided, that means we are scanning conflict version specs.
                ## The '!=' spec specifies a conflict. What is a conflict of a conflict?
                unless (defined $cons) {
                    die qq{unable to process "$k != $ver" in a conficts list};
                }
                push @$cons, [ $k, '=', $ver ];
            } else {
                push @$deps, [ $k, $op, $ver ];
            }
        }
    }
    return;
}

#---HELPER FUNCTION---
sub _scanstage
{
    my ($s, $r, $c) = @_;
    _scanvspecs($s->{'requires'}, $r, $c);
    _scanvspecs($s->{'conflicts'}, $c, undef);
}

#---HELPER FUNCTION---
# Clean up deps for the sake of humans.
#---------------------
sub _pruneperldep
{
    my ($d) = @_;
    if ((grep { $_->[0] =~ /^perl/ } @$d) > 1) {
        # Remove a redundant dependency on perl itself if a perl- package is
        # depended on.
        @$d = grep { $_->[0] ne 'perl' || $_->[2] } @$d;
    }
}

#---HELPER FUNCTION---
# Remove duplicate dependencies. If a package verspec is in depends, then the identical
# verspec does not need to be in makedepends or checkdepends.
#
# Given A and B, remove any duplicates from the array B.
#---------------------
sub _prunedups
{
    my ($a, $b) = @_;
    for my $x (@$a) {
        my $i = 0;
        while ($i <= $#$b) {
            # remember that _cmpspecs may be undef
            if (eval { _cmpspecs($x, $b->[$i]) == 0 }) {
                splice @$b, $i, 1;
            } else {
                $i++;
            }
        }
    }
    return;
}

#---PRIVATE METHOD---
# Purpose  : Converts our CPAN requirements and conflicts into PKGBUILD
#            checkdepends, makedepends, depends, and conflicts
# Returns  : A hashref of package relations.
#            Top level keys are 'makedepends', 'depends', and 'conflicts'.
#            The values of these keys are arrayrefs. Every three elements
#            specify a package name, operator (e.g. <=, =, etc) and version.
#---------------------
sub _get_pkg_rels
{
    croak 'Invalid arguments to _get_pkg_rels method' if (@_ != 1);
    my ($self) = @_;

    my $module = $self->parent;
    my (@deps, @mkdeps, @chdeps, @cons);
    if (defined $self->status->metareqs) {
        my $r = $self->status->metareqs;
        _scanstage($r->{'configure'}, \@mkdeps, \@cons);
        _scanstage($r->{'build'}, \@mkdeps, \@cons);
        _scanstage($r->{'test'}, \@chdeps, \@cons);
        _scanstage($r->{'runtime'}, \@deps, \@cons);
    } else {
        my $reqs = $module->status->prereqs;
        while (my ($k, $v) = each %$reqs) {
            push @deps, [ $k, '>=', $v ];
        }
        my $d = $module->package_name;
        unless ($d =~ /^ExtUtils-/) {
            @mkdeps = _yankmakemods(\@deps);
        }
        unless ($d =~ /^Test-/) {
            @chdeps = _yanktestmods(\@deps);
        }
    }
    
    my $be = $module->parent; # $module->parent is a CPANPLUS::Backend
    for my $a (\@deps, \@mkdeps, \@chdeps, \@cons) {
        _yankcoremods($a);
        _normspecs($a);
        _distspecs($be, $a); # specs are now on dist. names
        _normspecs($a);
        _pkgspecs($a); # specs are now on package names
    }

    # Merge in the XS package deps if they exist.
    my $xsdeps = $self->_transxsdeps();
    if (@$xsdeps) {
        push @deps, @$xsdeps;
        @deps = sort _vspecs @deps;
    }

    _pruneperldep($_) for (\@deps, \@mkdeps, \@chdeps);
    if (!grep { $_->[0] =~ /^perl/ } @deps) {
        # Require perl unless we have a dependency on a module or perl itself.
        unshift @deps, [ 'perl', '>=', '0' ];
    }
    _prunedups(\@deps, $_) for (\@mkdeps, \@chdeps);
    return {
        'depends' => \@deps,
        'makedepends' => \@mkdeps,
        'checkdepends' => \@chdeps,
        'conflicts' => \@cons,
    };
}


#-----------------------------------------------------------------------------
# XS module library dependency hunting
#-----------------------------------------------------------------------------

#---INSTANCE METHOD---
# Purpose  : Attempts to find non-perl dependencies in XS modules.
# Returns  : A hashref of 'package name' => 'minimum version'.
#            (Minimum version will be the current installed version
#             of the library)
#---------------------
sub _transxsdeps
{
    my $self = shift;

    my $modstat   = $self->parent->status;
    my $inst_type = $modstat->installer_type;
    my $distcpan  = $modstat->dist_cpan;

    # Delegate to the other methods depending on the dist type...
    my $libs_ref = ( $inst_type eq 'CPANPLUS::Dist::MM'
                     ? $self->_get_mm_xs_deps($distcpan) : [] );
    # TODO: figure out how to do this with Module::Build

    # Turn the linker flags into package deps...
    return [ map {
        my ($pkg, $ver) = $self->_get_lib_pkg($_);
        [ $pkg, '>=', $ver ]
    } @$libs_ref ];
}

#---INSTANCE METHOD---
# Usage    : %pkg = $self->_get_lib_pkg($lib)
# Params   : $lib - Can be a dynamic library name, with/without lib prefix
#                   or the -l<name> flag that is passed to the linker.
#                   (anything DynaLoader::dl_findfile accepts)
# Returns  : A hash (or two element list) of:
#            'package name' => 'installed version'
#            or an empty list if the lib/package owner could not be found.
#---------------------
sub _get_lib_pkg
{
    my ($self, $libname) = @_;

    my $lib_fqp = DynaLoader::dl_findfile($libname)
        or return ();

    $lib_fqp =~ s/([\\\$"`])/\\$1/g;
    my $result = `LC_ALL=C pacman -Qo "$lib_fqp"`;
    chomp $result;
    if ( $CHILD_ERROR != 0 || !($result =~ s/$PACMAN_FINDOWN//) ) {
        if ( $CHILD_ERROR == 127 ) {
            error q{C-library dep lookup failed. Pacman is missing!?};
        }
        else {
            error qq{Could not find owner of linked library }
                . qq{"$libname", ignoring.};
        }
        return ();
    }

    my ($pkgname, $pkgver) = split / /, $result;
    $pkgver =~ s/-\d+\z//; # remove the package revision number
    return ($pkgname, $pkgver);
}

sub _unique(@)
{
    my %seen;
    return map { $seen{$_}++ ? () : $_ } @_;
}

#---INSTANCE METHOD---
# Usage    : my $deps_ref = $self->_get_mm_xs_deps($dist_obj);
# Params   : $dist_obj - A CPANPLUS::Dist::MM object
# Returns  : Arrayref of library flags (-l...) passed to the linker on build.
#---------------------
sub _get_mm_xs_deps
{
    my ($self, $dist) = @_;

    my $field_srch = '\A(?:EXTRALIBS|LDLOADLIBS|BSLOADLIBS) = (.+)\z';

    my $mkfile_fqp = $dist->status->makefile
        or die "Internal error: makefile() path is unset in our object";

    open my $mkfile, '<', $mkfile_fqp
        or die "Internal error: failed to open Makefile at $mkfile_fqp ... $!";
    my @libs = _unique map { chomp; (/$field_srch/o) } <$mkfile>;
    close $mkfile;

    return [ grep { /\A-l/ } map { split } @libs ];
}

#---HELPER FUNCTION---
sub _find_xs_files
{
    my ($dirpath) = @_;
    return -f "$dirpath/typemap" || scalar glob "$dirpath/*.xs";
}


#-----------------------------------------------------------------------------
# CPAN Distribution Scraping
#-----------------------------------------------------------------------------


#---HELPER FUNCTION---
sub _pod_pkgdesc
{
    my ($mod_obj) = @_;
    my $podselect = Pod::Select->new;
    my $modname   = $mod_obj->name;
    $podselect->select('NAME');

=for POD Search
    We use the package name because there is usually a module file
    with the exact same name as the package file.
    
    We want the main module's description, just in case the user requested
    a lesser module in the same package file.
    
    Assume the main .pm or .pod file is under lib/Module/Name/Here.pm

=cut

    my $mainmod_path = $mod_obj->package_name;
    $mainmod_path    =~ tr{-}{/}s;

    my $mainmod_file = $mainmod_path;
    $mainmod_file    =~ s{\A.*/}{};
    $mainmod_path    =~ s{/$mainmod_file}{};

    my $base_path = $mod_obj->status->extract;

    # First check under lib/ for a "properly" pathed module, with
    # nested directories. Then search desperately for a .pm file that
    # matches the module's last name component.

    my @possible_pods = ( glob "$base_path/{lib/,}{$mainmod_path/,}"
                             . "$mainmod_file.{pod,pm}" );

    PODSEARCH:
    for my $podfile_path ( @possible_pods ) {
        next PODSEARCH unless ( -e $podfile_path );

        _DEBUG "Searching the POD inside $podfile_path for pkgdesc...";

        my $name_section = q{};

        open my $podfile, '<', $podfile_path
            or next PODSEARCH;

        open my $podout, '>', \$name_section
            or die "failed open on filehandle to string: $!";
        $podselect->parse_from_filehandle( $podfile, $podout );

        close $podfile;
        close $podout or die "failed close on filehandle to string: $!";

        next PODSEARCH unless ( $name_section );

        # Remove formatting codes.
        $name_section =~ s{ [IBCLEFSXZ]  <(.*?)>  }{$1}gxms;
        $name_section =~ s{ [IBCLEFSXZ] <<(.*?)>> }{$1}gxms;

        # The short desc is on a line beginning with 'Module::Name - '
        if ( $name_section =~ / ^ \s* $modname [ -]+ ([^\n]+) /xms ) {
            _DEBUG qq{Found pkgdesc "$1" in POD};            
            return $1;
        }
    }

    return undef;
}

#---HELPER FUNCTION---
sub _readme_pkgdesc
{
    my ($mod_obj) = @_;
    my $mod_name  = $mod_obj->name;

    open my $readme, '<', catfile( $mod_obj->status->extract, 'README' )
        or return undef;

    LINE:
    while ( <$readme> ) {
        chomp;

        # limit ourselves to a NAME section
        next LINE unless ( ( /^NAME/ ... /^[A-Z]+/ ) &&
                          / ^ \s* ${mod_name} [\s\-]+ (.+) $ /oxms );
        
        _DEBUG qq{Found pkgdesc "$1" in README};
        return $1;
    }

    return undef;
}

#---PRIVATE METHOD---
# Try to find out if this distribution has any XS files.
# If it does, then the arch PKGBUILD field should be ('i686', 'x86_64').
# If it doesn't, then the arch field should be ('any').
sub _prepare_arch
{
    my ($self) = @_;

    my $dist_cpan = $self->parent->status->dist_cpan;
    my $dist_dir  = $dist_cpan->status->distdir;

    unless ( $dist_dir && -d $dist_dir ) {
        return $self->status->arch( q{'any'} );
    }

    # Only search the top distribution directory and then go
    # one directory-level deep. .xs files are usually at the top
    # or in a subdir. Don't use File::Find, that could be really slow.

    my $found_xs;
    if ( _find_xs_files( $dist_dir )) {
        $found_xs = 1;
    }
    else {
        opendir my $basedir, $dist_dir or die "opendir: $!";
        my @childdirs = grep { !/^./ && -d $_ } readdir $basedir;

        DIR_LOOP:
        for my $childdir ( @childdirs ) {
            next DIR_LOOP unless _find_xs_files( $childdir );
            $found_xs = 1;
            last DIR_LOOP;
        }

        closedir $basedir;
    }

    return $self->status->arch( $found_xs
                                ? q{'i686' 'x86_64'} : q{'any'} );
}

#---INSTANCE METHOD---
# Usage    : $pkgdesc = $self->_prepare_pkgdesc();
# Purpose  : Tries to find a module's "abstract" short description for
#            use as a package description.
# Postcond : Sets the $self->status->pkgdesc accessor to the found
#            package description.
# Returns  : The package short description.
# Comments : We search through the META.yml file, the main module's .pm file,
#            .pod file, and then the README file.
#---------------------
sub _prepare_pkgdesc
{
    croak 'Invalid arguments to _prepare_pkgdesc method' if @_ != 1;

    my ($self) = @_;
    my ($status, $module, $pkgdesc) = ($self->status, $self->parent);

    my @pkgdesc_srcs =
        (
         # 1. We checked the META.yml earlier in the _scanmeta method.

         # 2. Registered modules have their description stored in the object.
         sub { $module->description },

         # 3. Parse the source file or pod file for a NAME section.
         \&_pod_pkgdesc,

         # 4. Try to find it in in the README file.
         \&_readme_pkgdesc,

         );

    PKGDESC_LOOP:
    for my $pkgdesc_src ( @pkgdesc_srcs ) {
        $pkgdesc = $pkgdesc_src->( $module ) and last PKGDESC_LOOP;
    }

    if ( $pkgdesc ) {
        # Avoid CR chars because of CRLF line endings in sources.
        $pkgdesc =~ tr/\r//d;
    } else {
        $pkgdesc = q{};
    }
    $status->pkgdesc( $pkgdesc );
    return;
}

#----------------------------
#  META Spec File Functions
#----------------------------

sub _metapath
{
    my ($mod) = @_;
    my $metapath;
    for my $ext (qw/json yml/) {
        my $p = catfile($mod->status->extract, "META.$ext");
        if (-f $p) {
            $metapath = $p;
            last;
        }
    }
    return $metapath;
}

# Smooth over differences between incompatible META specs.
sub _metareqs
{
    my ($meta) = @_;
    my $r;
    if (defined $meta->{'meta-spec'} &&
        $meta->{'meta-spec'}{'url'} =~ /cpan[.]org/) {
        $r = $meta->{'prereqs'};
    } else {
        for (qw/configure build/) {
            $r->{$_}{'requires'} = $meta->{"${_}_requires"};
        }
        $r->{'runtime'}{'requires'} = $meta->{'requires'};
        $r->{'build'}{'conflicts'} = $meta->{'conflicts'};
        
        # When upgrading, try to detect testing requirements.
        if ($meta->{'name'} !~ /^Test-/) {
            for my $m (keys %{$r->{'build'}{'requires'}}) {
                if ($m =~ /^Test::/) {
                    $r->{'test'}{'requires'}{$m} = delete $r->{'build'}{'requires'}{$m};
                }
            }
        }
    }
    return $r;
}

sub _metadesc
{
    my ($meta) = @_;
    my $d = $meta->{'abstract'} or return undef;

    # META.yml abstract entries we should ignore.
    my @bad = ( q{~}, 'Module abstract (<= 44 characters) goes here' );
    for my $b ( @bad ) {
        return if ( $d eq $b );
    }
    return $d;
    
}

#--- PRIVATE METHOD ---
# We read the META.json or META.yml file with Parse::CPAN::META and extract
# data needed for makedepends and pkgdesc if we can.
#----------------------
sub _scanmeta
{
    my ($self) = @_;
    my ($status, $modobj) = ($self->status, $self->parent);

    # Leave metareqs undef if there is no META.yml/META.json.
    my $path = _metapath($modobj) or return;    
    my $meta = eval { Parse::CPAN::Meta::LoadFile($path) };
    return unless ($meta);

    my $reqs = _metareqs($meta);
    my $desc = _metadesc($meta);
    $status->metareqs($reqs);
    $status->pkgdesc($desc);
    return;
}

#---INSTANCE METHOD---
# Usage    : $self->_prepare_status()
# Purpose  : Prepares all the package-specific accessors in our $self->status
#            accessor object (of the class Object::Accessor).
# Postcond : Accessors assigned to: pkgname pkgver pkgbase arch destdir
# Returns  : The object's status accessor.
#---------------------
sub _prepare_status
{
    croak 'Invalid arguments to _prepare_status method' if @_ != 1;

    my $self     = shift;
    my $status   = $self->status; # Private hash
    my $module   = $self->parent; # CPANPLUS::Module
    my $conf     = $module->parent->configure_object;

    my ($pkgver, $pkgname)
        = ( dist_pkgver( $module->package_version ),
            dist_pkgname( $module->package_name));

    my $pkgbase = catdir( $self->_cpanp_user_basedir,
                          'build', "$pkgname-$pkgver" );

    foreach ( $pkgname, $pkgver, $pkgbase ) {
        die "A package variable is invalid" unless defined;
    }

    $status->pkgname( $pkgname );
    $status->pkgver ( $pkgver  );
    $status->pkgbase( $pkgbase );
    $status->pkgrel (    1     );

    $status->tt_init_args( {} );

    $self->_prepare_arch();
    $self->_scanmeta();

    # _scanmeta() might find a pkgdesc for us
    $self->_prepare_pkgdesc() unless $status->pkgdesc();

    return $status;
}

#---INSTANCE METHOD---
# Usage    : my $pkgurl = $self->_get_disturl()
# Purpose  : Creates a nice, version agnostic homepage URL for the
#            distribution.
# Returns  : URL to the distribution's web page on CPAN.
#---------------------
sub _get_disturl
{
    croak 'Invalid arguments to _get_disturl method' if @_ != 1;
    my $self = shift;
    my $dist = $self->parent->package_name;
    return "https://metacpan.org/release/$dist";
}

#---INSTANCE METHOD---
# Usage    : my $srcurl = $self->_get_srcurl()
# Purpose  : Generates the standard cpan download link for the source tarball.
# Returns  : URL to the distribution's tarball on CPAN.
#---------------------
sub _get_srcurl
{
    croak 'Invalid arguments to _get_srcurl method' if @_ != 1;
    my ($self) = @_;
    my $module = $self->parent;

    return join '/', $CPANURL, 'CPAN', $module->path, $module->package;
}

#---INSTANCE METHOD---
# Usage    : my $md5hex = $self->calc_tarballmd5()
# Purpose  : Returns the hex md5 string for the source (dist) tarball
#            of the module.
# Throws   : failed to get md5 of <filename>: ...
# Returns  : The MD5 sum of the .tar.gz file in hex string form.
#---------------------
sub _calc_tarballmd5
{
    my ($self) = @_;
    my $module = $self->parent;

    my $tarball_fqp = $module->_status->fetch;
    open my $distfile, '<', $tarball_fqp
        or die "failed to get md5 of $tarball_fqp: $OS_ERROR";
    binmode $distfile;

    my $md5 = Digest::MD5->new;
    $md5->addfile($distfile);
    close $distfile;

    return $md5->hexdigest;
}

#---INSTANCE METHOD---
# Usage    : my $shasum = $self->calc_shasum(512);
# Params   : The bitsizes to use for the SHA digest calculated.
# Throws   : failed to get sha<size>sum of <tarball>:\n...
# Returns  : Hex-string checksum of the tarball for the bit size
#            provided as a parameter.
#---------------------
sub _calc_shasum
{
    my ($self, $size) = @_;
    my $module = $self->parent;
    my $fqp    = $module->_status->fetch;
    my $sum    = eval {
        Digest::SHA->new( $size )->addfile( $fqp, q{b} )->hexdigest;
    };
    return $sum if $sum;
    die "failed to get sha${size}sum of $fqp:\n$EVAL_ERROR";
}


#---HELPER FUNCTION---
# Purpose : Split the text into everything before the tags, inside tags, and
#           after the tags.  Inner nested tags are skipped.
#---------------------
sub _extract_nested
{
    croak 'Invalid arguments to _extract_nested' unless ( @_ == 3 );

    my ($text, $begin_match, $end_match) = @_;

    my ($before_end, $middle_start, $middle_end, $after_start);
    croak qq{could not find beginning match "$begin_match"}
        unless ( $text =~ /$begin_match/ );

    $before_end   = $LAST_MATCH_START[0];
    $middle_start = $LAST_MATCH_END  [0];

    my $search_pos   = $middle_start;

    END_SEARCH:
    {
        pos $text = $search_pos;
        croak sprintf <<'END_ERR', substr $text, $search_pos, 30
could not find ending match starting at:
%s...
END_ERR
            unless ( $text =~ /$end_match/go );

        $middle_end  = $LAST_MATCH_START[0];
        $after_start = $LAST_MATCH_END[0];

        pos $text = $search_pos;
        if ( $text =~ /$begin_match/go && pos($text) < $after_start ) {
            $search_pos = $after_start;
            redo END_SEARCH;
        }
    }

    my $before = substr $text, 0, $before_end;
    my $middle = substr $text, $middle_start, $middle_end-$middle_start;
    my $after  = substr $text, $after_start;

    return ($before, $middle, $after);
}

#---HELPER FUNCTION---
# Purpose : Removes IF blocks whose variables are not true.
# Params  : $templ      - The template as a string.
#           $templ_vars - A hashref to template variables.
#---------------------
sub _prune_if_blocks
{
    my ($templ, $templ_vars) = @_;

    while (my ($varname) = $templ =~ $TT_IF_MATCH) {
        croak "Invalid template given.\n"
            . 'Must provide a variable name in an IF block' unless $varname;

        my @chunks = _extract_nested($templ, $TT_IF_MATCH, $TT_END_MATCH);
        unless ($templ_vars->{$varname}) { splice @chunks, 1, 1; }
        $templ = join q{}, @chunks;
    }

    return $templ;
}

#---HELPER FUNCTION---
# Purpose  : Load a template module and store its name for later use.
# Postcond : Stores the template name into $TT_MOD_NAME.
# Returns  : Nothing.
#---------------------
sub _load_tt_module
{
    _DEBUG "Searching for template modules...";
    TT_SEARCH:
    for my $ttmod ( @TT_MOD_SEARCH ) {
        eval "require $ttmod; 1;" or next TT_SEARCH;
        _DEBUG "Loaded template module: $ttmod";
        $TT_MOD_NAME = $ttmod;
        return;
    }

    _DEBUG "None found!";
    $TT_MOD_NAME = 0;
    return;
}

#---HELPER METHOD---
# Purpose : Create our template module object and process our template text.
# Params  : $templ      - A string of template text.
#           $templ_vars - A hashref of template variable names and their
#                         values.
# Returns : The template module's processed text.
#-------------------
sub _tt_process
{
    my ($self, $templ, $templ_vars) = @_;

    confess 'Internal Error: $TT_MOD_NAME not set' unless $TT_MOD_NAME;

    _DEBUG "Processing template using $TT_MOD_NAME";

    my ($tt_obj, $tt_output, $tt_init_args);
    $tt_init_args = $self->status->tt_init_args();
    $tt_output    = q{};
    $tt_obj       = $TT_MOD_NAME->new( $TT_MOD_NAME eq 'Template'
                                       ? $tt_init_args : %$tt_init_args );
                                # TT takes a hashref, others take the hash

    $tt_obj->process( \$templ, $templ_vars, \$tt_output );

    croak "$TT_MOD_NAME failed to process PKGBUILD template:\n"
        . $tt_obj->error if ( eval { $tt_obj->error } );

    return $tt_output;
}

#---INSTANCE METHOD---
# Usage    : $self->_process_template( $templ, $templ_vars );
# Purpose  : Process template text with a template module or our builtin
#            template code.
# Params   : templ       - A string containing the template text.
#            templ_vars  - A hashref of template variables that you can
#                          refer to in the template to insert the
#                          variable's value.
# Throws   : 'Template variable %s was not provided' is thrown if a template
#            variable is used in $templ but not provided in $templ_vars,
#            OR IF IT IS UNDEF!
# Returns  : String of the template result.
#---------------------
sub _process_template
{
    croak "Invalid arguments to _process_template" if @_ != 3;
    my ($self, $templ, $templ_vars) = @_;

    croak 'templ_var parameter must be a hashref'
        if ( ref $templ_vars ne 'HASH' );

    # Try to find a TT module if this is our first time called...
    _load_tt_module() unless defined $TT_MOD_NAME;

    # Use the TT module if we have found one earlier...
    return $self->_tt_process( $templ, $templ_vars ) if $TT_MOD_NAME;

    _DEBUG "Processing PKGBUILD template with built-in code...";

    # Fall back on our own primitive little template engine...
    $templ = _prune_if_blocks( $templ, $templ_vars );
    $templ =~ s{ $TT_VAR_MATCH }
               { (defined $templ_vars->{$1} ? $templ_vars->{$1} : "") }xmseg;

    return $templ;
}

1; # End of CPANPLUS::Dist::Arch

