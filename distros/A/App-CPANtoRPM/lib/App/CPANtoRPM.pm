package App::CPANtoRPM;
# Copyright (c) 2012-2019 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

###############################################################################

use warnings;
use strict;
use POSIX;
use IO::File;

our($VERSION);
$VERSION = "1.09";

$| = 1;

use vars qw($COM $DIR $ARCH $VERS);
use Config;
$ARCH  = $Config{'archname'};
$VERS  = $Config{'version'};

###############################################################################
# GLOBAL VARIABLES
###############################################################################

our $TMPDIR     = "/tmp/cpantorpm";

our %Macros     = (0 => {
                         '_optimize'  => '$RPM_OPT_FLAGS',
                         '_buildroot' => '$RPM_BUILD_ROOT',
                        },

                   1 => {
                         '_optimize'  => '%{optimize}',
                         '_buildroot' => '%{buildroot}',
                        }
                  );

our ($OUTPUT,@OUTPUT,%package,$MAN);
$package{'VERSION'} = $VERSION;
$package{'date'}    = POSIX::strftime("%a %b %d %Y",localtime());

###############################################################################
###############################################################################

sub _new {
   my($class) = @_;

   my $self = {
               'add_provide'  => [],
               'add_require'  => [],
               'author'       => [],
               'build'        => [],
               'build_rec'    => 0,
               'build_type'   => '',
               'clean_macros' => 0,
               'config'       => [],
               'cpan'         => 'cpanplus',
               'debug'        => 0,
               'description'  => '',
               'disttag'      => '%{?dist}',
               'env'          => {},
               'epoch'        => '',
               'extracted'    => '',
               'gpg_name'     => '',
               'gpg_passfile' => '',
               'gpg_passwd'   => '',
               'gpg_path'     => '',
               'group'        => 'Development/Libraries',
               'inst_base'    => '',
               'inst_type'    => '',
               'install'      => '',
               'macros'       => 0,
               'mainpod'      => '',
               'mandir'       => '',
               'name'         => '',
               'no_clean'     => 0,
               'no_deps'      => 0,
               'no_tests'     => 0,
               'package'      => '',
               'packager'     => '',
               'patch'        => '',
               'patch_dir'    => '',
               'prefix'       => 'perl-',
               'release'      => 1,
               'rem_provide'  => [],
               'rem_require'  => [],
               'rpmbuild'     => '',
               'runtime_rec'  => 0,
               'script'       => '',
               'script_dir'   => '',
               'sign'         => 0,
               'spec_only'    => 0,
               'summary'      => '',
               'test_rec'     => 0,
               'version'      => '',
               'yum'          => '',
              };

   $COM                = $0;
   $COM                =~ s/^.*\///;
   $DIR                = $0;
   $DIR                =~ s/\/?$COM$//;
   $DIR                = "."  if (! $DIR);
   chdir $DIR;
   $DIR                = `pwd`;
   chomp($DIR);

   bless $self, $class;

   $package{'CMD'}     = $COM;
   $package{'command'} = $0;
   $package{'args'}    = $self->_args();
   $package{'date'}    = POSIX::strftime("%a %b %d %Y",localtime());
   $package{'self'}    = $self;

   return $self;
}

sub _args {
   my($self) = @_;
   my @args = @ARGV;
   map {
      s/([<>\*\|`&\$!#\(\)\[\]\{\}:'"\ \	])/\\$1/g;
   } @args;
   return join(' ',@args);
}

# %package =
#   # Argument parsing step:             Notes
#   # ------------------------------     --------------------------------
#   CMD        => cpantorpm              This script
#   VERSION    => 1.00                   Version of this script
#   command    => STRING                 The command executed
#   args       => STRING                 The command line arguments
#                                        This must only be used in a comment
#                                        in the SPEC file.
#   date       => STRING                 Current timestamp
#   incl_tests => 0/1                    1 if we'll be adding tests to SPEC
#   incl_deps  => 0/1                    1 if we'll be included requires
#                                        in the SPEC
#
#   # Init step:
#   # ------------------------------     --------------------------------
#   TMP        => $TMPDIR                Directory where we'll store things
#
#   # Package retrieval step
#   # ------------------------------     --------------------------------
#   from       => file/dir/url/CPAN
#   fromsrc    => Foo::Bar               how it was passed in
#   DIR        => $TMPDIR/Foo-Bar-1.0
#   dir        => Foo-Bar-1.0
#   dist       => Foo-Bar
#   vers       => 1.0
#   archive    => Foo-Bar-1.0.tgz        Set for URL/File/CPAN
#   ext        => tgz                    Set for URL/File/CPAN
#   filetype   => tar.gz                 Set for URL/File/CPAN
#                                        One of: tar.gz, tar.bz2, zip
#   cpandir    => S/SB/SBECK             Set for CPAN
#
#   # Reading metadata step
#   # ------------------------------     --------------------------------
#   build      => Build.PL               The Build.PL file (if one exists)
#   make       => Makefile.PL            The Makefile.PL file (if one exists)
#   m_name     => Foo-Bar                Should be the same as 'dist'
#   m_version  => 1.0                    Should be the same as 'vers'
#   m_abstract => Summary text
#   m_description => Description
#   m_keywords => [ WORD, WORD, ... ]
#   m_author   => [ AUTHOR, AUTHOR, ... ]
#   m_provides => { FEATURE => { version => VERS,
#                                file    => FILE } ... }
#                                        FILE = lib/Foo/Bar.pm
#   m_license  => perl_5,apache          Comma separated list of licenses
#
#   # Derived from the metadata
#   # -------------------------
#   build_type => make|build
#   name       => Foo-Bar
#   version    => 1.0
#   author     => [ AUTHOR, AUTHOR, ...]
#   desc       => DESCRIPTION
#   summary    => SUMMARY
#   arch       => noarch|%{_arch}
#   arch_val   => noarch|x86_64
#   prefix     => perl-
#   rpmname    => perl-Foo-Bar
#   specname   => perl-Foo-Bar.spec
#
#   # Categorize package files
#   # -------------------------
#   files      => { pm      => { FILE => '' },
#                   pod     => { FILE => '' },   or FILE => NAME
#                   t       => { FILE => '' },
#                   xs      => { FILE => '' },
#                   scripts => { FILE => '' },
#                   build   => { FILE => '' },
#                   mainpod => [ FILE, NAME, SUMMARY, DESCRIPTION ]
#                 }
#                                        FILE is the path relative to the top
#                                        directory of the package.
#   instfiles  => { pm      => { FILE => '' },
#                   scripts => { FILE => '' },
#                   man1    => { FILE => '' },
#                   man3    => { FILE => '' },
#                 }
#                                        Similar to files but limited to the
#                                        files that are actually installed.
#   lib_inst   => 1                      if we're installing noarch .pm files
#   arch_inst  => 1                      if we're installing architecture .pm files
#   bin_inst   => 1                      if we're installing scripts
#   man1_inst  => 1
#   man3_inst  => 1
#
#   # Prereqs and provides
#   # -------------------------
#   requires   => { build   => { FEATURE => VERS },
#                   test    => { FEATURE => VERS },
#                   runtime => { FEATURE => VERS }, }
#                                        Requirements for building the
#                                        module, running tests, or runtime.
#                                        FEATURE is Foo::Bar
#   build_req  => { FEATURE => VERS }
#   runtime_req=> { FEATURE => VERS }
#                                        Same as 'requires', but FEATURE
#                                        formatted as it will be in the SPEC file.
#                                        FEATURE is perl(Foo::Bar)
#   provides   => { FEATURE => VERS }
#
#   # Gotten from the build step
#   # -------------------------
#   bin_dir    => /usr/bin               The directories we're installing too
#   lib_dir    => /usr/lib/perl5/5.14.2
#   arch_dir   => /usr/lib/perl5/5.14.2/x86_64-linux-thread-multi
#   man1_dir   => /usr/share/man/man1
#   man3_dir   => /usr/share/man/man3
#   config_cmd => perl Makefile.PL       The commands used for each step
#   build_cmd  => make
#   test_cmd   => make test
#   install_cmd=> make install
#   build_tiny => 0/1                    1 if it uses Module::Build::Tiny
#
#   # From the SPEC creation step
#   # -------------------------
#   release    => 1
#   disttag    => %{?dist}
#   epoch      =>                        The epoch number (set by --epoch)
#   group      => Development/Libraries
#   url        => http://search.cpan.org/dist/Foo-Bar/
#   license    => GPL+ or Artistic
#   source     => http://www.cpan.org/authors/id/S/SB/SBECK/Foo-Bar-1.0.tar.gz
#   packager   => PACKAGER
#   restore    => 1                      if .rpmmacros file should be restored
#   remove     => 1                      if .rpmmacros file should be removed
#   topdir     => /usr/src/redhat        Top of the RPM build tree
#   rpmarch    => x86_64                 The RPM architecture
#   post_build => [ LINE, LINE, ... ]    Lines (sh commands) added to %build
#
#   # From the build RPM step
#   # -------------------------
#   rpmfile    => /usr/src/redhat/RPMS/noarch/cpantorpm-1.00-1.noarch.rpm
#   srpmfile   => /usr/src/redhat/SRPMS/cpantorpm-1.00-1.src.rpm

sub _main {
   my($self) = @_;

   $self->_parse_args();
   $self->_init();

   $self->_get_package($$self{'package'});
   chdir($package{'DIR'});
   $self->_get_meta_pre_build();
   $self->_check_deps()     unless ($$self{'no_deps'});
   $self->_build();
   $self->_get_meta();
   $self->_make_spec();
   exit                     if ($$self{'spec_only'});

   $self->_build_rpm();
   $self->_sign_rpm()       if ($$self{'sign'});
   $self->_install_rpm()    if ($$self{'install'});
   $self->_install_yum()    if ($$self{'yum'});
}

sub _usage {
   my($self) = @_;

   print
     "usage: $COM OPTIONS PACKAGE

   General options:
      -h/--help        : Print help.
      -v/--version     : Print out the version of this program
      -D/--debug       : Verbose output
      -t/--tmpdir DIR  : A scratch directory used by this script.
                         Default: $TMPDIR
      -f/--optfile FILE: Specifies an options file

   Download options:
      -c/--cpan        : By default, downloading modules from CPAN
                         will be done using CPANPLUS and, if that
                         fails, using CPAN.  If --cpan is passed in,
                         it will use CPAN only.
      --extracted DIR  : If the archive on CPAN does not contain a
                         properly named directory, use this to
                         specify the name that it DOES have.

   Package metadata options.  A description of the package is
   read from POD files, or other files in the package, or they
   can be set with these options (in which case, the package files
   will NOT be examined for this information).

      --name NAME      : Explicitly set the name of the package overriding
                         the one obtained from the archive name or the
                         metadata.
      --summary TEXT   : The summary (1-line) description of the package.
      --description FILE
                       : The long (multiline) description of the package.
                         Normally it comes from a POD file.
      --mainpod FILE   : The description and summary can be obtained from
                         the main POD file, if it can be determined.  To
                         select the main POD file, use this option.  FILE
                         is the path to the file relative to the top
                         level of the build directory (i.e. the directory
                         with a Build.PL or Makefile.PL file in it).  It
                         would be specified as:
                            lib/Foo/Bar.pm
      --author AUTHOR  : An author for this module.  If the author(s) cannot
                         be determined from the META files, they need to
                         be specified with this option.  It can be included
                         any number of times.
      --vers VERS      : Specify the version explictly rather than using
                         the one that came from the metadata or archive.

   RPM creation options.

      -n/--no-tests    : By default, as part of building an RPM, the
      --NO-TESTS         module tests (if any) will be run.  These options
                         can be used to modify that behavior.  In the
                         first case, the SPEC file will contain lines to
                         run the tests, but they will not be run this
                         time.  With the second option, no lines will be
                         included in the SPEC file to run the tests.
      -d/--no-deps     : By default, dependencies are checked AND added
      --NO-DEPS          to the SPEC file.  If either of these options are
                         given, they will not be checked.  If the second
                         option is given, they will not be added to the
                         SPEC file.
      --prefix PREFIX  : By default, a prefix of 'perl-' will be applied
      --no-prefix        to the RPM.  To specify an alternate prefix, use
                         the --prefix option.  To specify that no prefix
                         be used, use the --no-prefix option.
      -p/--packager PACKAGER
                       : The name of the packager.  It will use the
                         default one (looking in a ~/.rpmmacros file) if
                         possible.
      --group GROUP    : Specify the RPM group.
      --rpmbuild DIR   : Specify the RPM build directory to use.
      --clean-macros   : Use a clean copy of ~/.rpmmacros to build with.
      --release STRING : These are used to set the release string that is
      --disttag STRING   added to the RPM name after the version number.
                         For example:  foo-bar-1.00-1a.rpm has a release
                         of '1' and a disttag of 'a'.  Release defaults to
                         '1' and disttag defaults to '%{?dist}'.
      --epoch EPOCH    : This is used to set an optional Epoch number in
                         the RPM.
      --add-require FEATURE
      --rem-require FEATURE
      --add-provide FEATURE
      --rem-provide FEATURE
                       : These add or remove a feature from the requires
                         or provides list of the RPM.
      -m/--macros      : Use the macro form of common SPEC constructs
                         instead of the environment variable form.
      --build-rec
      --test-rec
      --runtime-rec    : By default, modules that are recommended for
                         configure/build, test, and runtime are optional.
                         These arguments make them required.

   To actually create the module, we may need to pass special options
   to the 'perl Build.PL' or 'perl Makefile.PL' commands.  The
   following options are used to do this:

      --build-type TYPE: TYPE may be 'build' or 'make' and force the use of
                         the Build.PL and Makefile.PL files respectively.
                         If the file does not exist, an error is triggered.
                         an error will be triggered.
      --config STRING  : Pass STRING to the 'perl Build.PL' or 'perl Makefile.PL'
                         command.  This can be passed in any number of times.
      --build STRING   : Pass STRING to the './Build' or 'make' command.
                         This can be passed in any number of times.
      -i/--install-base DIR:
                         The base directory to install the module.
      -T/--install-type TYPE:
                         The type of installation.  TYPE must be one of:
                            perl (aka core), site, or vendor
                         It defaults to the version specified in the
                         module.
      --mandir STRING  : Used to specify the man directory (relative to a
                         prefix).  e.g. share/man
      --patch FILE
      --patch-dir DIR
      --script FILE
      --script-dir DIR : In some cases, a distribution cannot be packaged
                         without some modifications.  Modifications can
                         be supplied in the form of a patch or a script.

   Options to control what steps are done:

      --spec-only      : Stop after building the SPEC file.
      --no-clean       : Do not remove the build tree after the RPM
                         is built.
      -s/--sign        : Add a GPG signature.
      -I/--install     : Install the RPM on this system (by default,
                         it will install a new RPM, or upgrade an
                         existing one if the version changed).
      --install-new    : This will install the RPM if it is new, but
                         will not upgrade an existing version.
      --install-force  : This will install the RPM even if it already
                         is installed.
      -y/--yum DIR     : Copy the RPM to a local yum repository

   Misc. options:

      --gpg-path PATH  : The path to the GPG directory containing
                         the keyring.
      --gpg-name NAME  : The name of the user who's key should be
                         used to sign the package.
      --gpg-passwd PASSWORD
                       : The passphrase for the GPG key.
      --gpg-passfile FILE
                       : A file containing the passphrase for the GPG key.
      --env VAR=VAL    : Sets an environment variable before building
                         the package.  This option can be used any number
                         of times.

This takes a perl modules and creates an RPM version of it.

";
}

sub _parse_args {
   my($self) = @_;
   my @a     = @ARGV;

   # We have to get the package first or else --optfile will not work.
   if ($a[$#a] !~ /^-/) {
      $$self{'package'} = pop(@a);
   }

   while ($_ = shift(@a)) {

      $self->_usage,                           exit  if ($_ eq '-h'  ||
                                                         $_ eq '--help');
      (print "$VERSION\n"),                    exit  if ($_ eq '-v'  ||
                                                         $_ eq '--version');
      $TMPDIR = shift(@a),                     next  if ($_ eq '-t'  ||
                                                         $_ eq '--tmpdir');
      $$self{'debug'} = 1,                     next  if ($_ eq '-D'  ||
                                                         $_ eq '--debug');
      unshift(@a,$self->_opt_file(shift(@a))), next  if ($_ eq '-f'  ||
                                                         $_ eq '--optfile');
      $$self{'no_tests'} = 1,                  next  if ($_ eq '-n'  ||
                                                         $_ eq '--no-tests');
      $$self{'no_tests'} = 2,                  next  if ($_ eq '--NO-TESTS');
      $$self{'no_deps'} = 1,                   next  if ($_ eq '-d'  ||
                                                         $_ eq '--no-deps');
      $$self{'no_deps'} = 2,                   next  if ($_ eq '--NO-DEPS');
      $$self{'cpan'} = 'cpan',                 next  if ($_ eq '-c'  ||
                                                         $_ eq '--cpan');
      $$self{'description'} = shift(@a),       next  if ($_ eq '--description');
      $$self{'summary'} = shift(@a),           next  if ($_ eq '--summary');
      $$self{'mainpod'} = shift(@a),           next  if ($_ eq '--mainpod');
      push(@{ $$self{'author'} }, shift(@a)),  next  if ($_ eq '--author');
      $$self{'name'} = shift(@a),              next  if ($_ eq '--name');
      $$self{'version'} = shift(@a),           next  if ($_ eq '--vers');
      $$self{'prefix'} = shift(@a),            next  if ($_ eq '--prefix');
      $$self{'prefix'} = '',                   next  if ($_ eq '--no-prefix');
      $$self{'packager'} = shift(@a),          next  if ($_ eq '-p'  ||
                                                         $_ eq '--packager');
      $$self{'rpmbuild'} = shift(@a),          next  if ($_ eq '--rpmbuild');
      $$self{'clean_macros'} = 1,              next  if ($_ eq '--clean-macros');
      $$self{'build_type'} = shift(@a),        next  if ($_ eq '--build-type');
      $$self{'group'} = shift(@a),             next  if ($_ eq '--group');
      push(@{ $$self{'config'} }, shift(@a)),  next  if ($_ eq '--config');
      push(@{ $$self{'build'} }, shift(@a)),   next  if ($_ eq '--build');
      $$self{'release'} = shift(@a),           next  if ($_ eq '--release');
      $$self{'disttag'} = shift(@a),           next  if ($_ eq '--disttag');
      $$self{'epoch'} = shift(@a),             next  if ($_ eq '--epoch');
      $$self{'macros'} = 1,                    next  if ($_ eq '-m'  ||
                                                         $_ eq '--macros');
      $$self{'spec_only'} = 1,                 next  if ($_ eq '--spec-only');
      $$self{'inst_type'} = shift(@a),         next  if ($_ eq '-T'  ||
                                                         $_ eq '--install-type');
      $$self{'inst_base'} = shift(@a),         next  if ($_ eq '-i'  ||
                                                         $_ eq '--install-base');
      $$self{'mandir'} = shift(@a),            next  if ($_ eq '--mandir');
      $$self{'no_clean'} = 1,                  next  if ($_ eq '--no-clean');
      $$self{'sign'} = 1,                      next  if ($_ eq '-s'  ||
                                                         $_ eq '--sign');
      $$self{'gpg_path'} = shift(@a),          next  if ($_ eq '--gpg-path');
      $$self{'gpg_name'} = shift(@a),          next  if ($_ eq '--gpg-name');
      $$self{'gpg_passwd'} = shift(@a),        next  if ($_ eq '--gpg-passwd');
      $$self{'gpg_passfile'} = shift(@a),      next  if ($_ eq '--gpg-passfile');
      $$self{'install'} = 'upg',               next  if ($_ eq '-I'  ||
                                                         $_ eq '--install');
      $$self{'install'} = 'new',               next  if ($_ eq '--install-new');
      $$self{'install'} = 'force',             next  if ($_ eq '--install-force');
      $$self{'yum'} = shift(@a),               next  if ($_ eq '-y'  ||
                                                         $_ eq '--yum');
      $$self{'script'} = shift(@a),            next  if ($_ eq '--script');
      $$self{'script_dir'} = shift(@a),        next  if ($_ eq '--script-dir');
      $$self{'patch'} = shift(@a),             next  if ($_ eq '--patch');
      $$self{'patch_dir'} = shift(@a),         next  if ($_ eq '--patch-dir');
      $$self{'runtime_rec'} = 1,               next  if ($_ eq '--runtime-rec');
      $$self{'build_rec'} = 1,                 next  if ($_ eq '--build-rec');
      $$self{'test_rec'} = 1,                  next  if ($_ eq '--test-rec');
      $$self{'extracted'} = shift(@a),         next  if ($_ eq '--extracted');

      push(@{ $$self{'add_require'} }, shift(@a)),
                                               next  if ($_ eq '--add-require');
      push(@{ $$self{'add_provide'} }, shift(@a)),
                                               next  if ($_ eq '--add-provide');
      push(@{ $$self{'rem_require'} }, shift(@a)),
                                               next  if ($_ eq '--rem-require');
      push(@{ $$self{'rem_provide'} }, shift(@a)),
                                               next  if ($_ eq '--rem-provide');

      if ($_ eq '--env') {
         my $tmp = shift(@a);
         if ($tmp =~ /^(.+?)=(.+)$/) {
            $$self{'env'}{$1} = $2;
         } else {
            $self->_log_message('ERR',"Invalid --env option: $tmp");
         }
         next;
      }

      $self->_log_message('ERR',"Unknown arguments: $_ @a")  if (@a);
   }

   if (! $$self{'package'}) {
      $self->_log_message('ERR','No package given.');
   }

   if ($$self{'build_type'}  &&
       $$self{'build_type'} ne 'build'  &&
       $$self{'build_type'} ne 'make') {
      $self->_log_message('ERR',"Invalid --build-type option: $$self{build_type}");
   }

   $$self{'inst_type'} = 'perl'  if ($$self{'inst_type'} eq 'core');
   if ($$self{'inst_type'}  &&
       $$self{'inst_type'} ne 'perl'  &&
       $$self{'inst_type'} ne 'site'  &&
       $$self{'inst_type'} ne 'vendor') {
      $self->_log_message('ERR',
                          "Invalid --install-type option: $$self{inst_type}");
   }

   # To determine whether man pages go in PREFIX/man or PREFIX/share/man,
   # we'll analyze them here.

   if ($$self{'mandir'}) {
      $MAN = $$self{'mandir'};
   } else {
      my $prefix = $Config{'installprefix'};
      my $man1   = $Config{'installman1dir'};

      # Make sure man1 is DIR/man1 (allow man1p, man1xxx, etc.)
      if ($man1 !~ s,/man1[^/]*,,) {
         $self->_log_message
           ('ERR',
            "man page installation directory cannot be determined",
            "completely.  Use the --mandir option.");
      }
      # Make sure man1 is PREFIX/... where PREFIX is the installation prefix.
      if ($man1 !~ s,^$prefix/,,) {
         $self->_log_message
           ('ERR',
            "man page installation directory cannot be determined",
            "completely.  Use the --mandir option.");
      }
      $MAN = $man1;
   }

   if ($$self{'no_deps'}) {
      $$self{'no_tests'} = 1  if (! $$self{'no_tests'});
   }

   $package{'incl_tests'} = ($$self{'no_tests'} == 2 ? 0 : 1);
   $package{'incl_deps'}  = ($$self{'no_deps'} == 2 ? 0 : 1);

   foreach my $var (keys %{ $$self{'env'} }) {
      my $val = $$self{'env'}{$var};
      $ENV{$var} = $val;
   }

   if ($$self{'rpmbuild'}  &&  $$self{'rpmbuild'} !~ m,^/,) {
         $self->_log_message
           ('ERR',
            "The --rpmbuild option requires a fully specified path.");
   }
}

###############################################################################
###############################################################################
# This prints out a log message to STDOUT.
#
# $level can be:
#    NONE    - print out text unmodified
#    INFO    - print only if debugging
#    WARN    - print a warning message
#    ERR     - print an error and then exit
#    HEAD    - print a header
#
# @line is the text of the message.
#
BEGIN
{
   my $indent = 0;

   sub _log_message {
      my($self,$level,@line) = @_;

      my(@print);
      my $print = 1;

      if ($level eq 'HEAD') {

         #
         # HEAD
         #

         $indent = 0;
         push(@print,"*" x 60);
         foreach my $line (@line) {
            push(@print,"* $line");
         }
         push(@print,"*" x 60);

      } elsif ($level eq 'NONE') {

         @print = @line;

      } else {

         #
         # INFO  - only prints during debuggin
         # WARN
         # ERR   - prints then exits
         #

         $print = 0  if ($level eq 'INFO'  &&  ! $$self{'debug'});

         my $head = "$level:" . " "x(4-length($level)) . ' 'x($indent*3);
         my $line = shift(@line);
         push(@print,"$head $line");
         $head = " "x(length($head));
         foreach $line (@line) {
            push(@print,"$head $line");
         }
      }

      if ($print) {
         foreach my $line (@print) {
            print "$line\n";
         }
      }

      if ($level eq 'ERR') {
         exit 1;
      }

      return @print  if (! $print);
      return;
   }

   sub _log_indent {
      my($self,$mod) = @_;

      $indent += $mod;
   }
}

###############################################################################
# Find $exe in ENV{PATH} or one of the directories in @extra_path .
#
sub _find_exe {
   my($self,$exe,@extra_path) = @_;

   my @path = split(/:/,$ENV{PATH});
   unshift(@path,@extra_path);

   foreach my $d (@path) {
      return "$d/$exe"  if (-x "$d/$exe"  &&  ! -d "$d/$exe");
   }

   return '';
}

###############################################################################
# This will load a module (and import the given functions).  If it fails,
# an error code will be returned.
#
# This will work to check the perl version (if $mod is empty).  If $vers
# is empty, it will attempt to load the module but not check the version
# number.
#
sub _load_module {
   my($self,$mod,$vers,@funcs) = @_;
   $mod  = ''  if (! $mod);
   $vers = ''  if (! $vers);

   if (@funcs) {
      my $funcs = join(' ',@funcs);
      eval "use $mod $vers qw($funcs)";
      return 1  if ($@);

   } elsif ($mod) {
      eval "use $mod $vers ()";
      return 1  if ($@);

   } else {
      eval "use $vers";
      return 1  if ($@);
   }
   return 0;
}

############################################################################
# This function will try to accomplish a simple task using several
# different methods.  It will try each method in order until success
# is achieved, or if all of them fail, an error condition will be
# noted.
#
# This is useful for simple tasks which can be trivially checked for
# success, but for which there are multiple possible ways to perform
# it, not all of which may be available.
#
#   $success = $self->_multiple_methods($test,$method1,$method2,...);
#
# $test is a listref of:
#
#   $test   = [ CODEREF, ARGS ]
#
# where CODEREF is a reference to a subroutine to test to see if a method
# succeeded.  ARGS is an optional list of arguments to pass to the function.
#
# Each method is a listref of one of the following forms:
#
#   $method = [ 'system', EXECUTABLE, COMMAND, ARGS ]
#             Run COMMAND as a system command (with ARGS).  If EXECUTABLE
#             (which is the main command) can't be found, this method is
#             ignored.
#
#   $method = [ 'module', MODULE, IMPORT_LIST, EVAL_STRING ]
#   $method = [ 'module', MODULE, VERSION, IMPORT_LIST, EVAL_STRING ]
#             First tries to load MODULE.  If it succeeds, it imports
#             the functions in IMPORT_LIST (which is a listref).
#             Once done, it evaluates the string stored in EVAL_STRING.
#
#   $method = [ 'function', CODEREF, ARGS ]
#             Run &CODEREF (with ARGS)
#
# It returns 1 if one of the methods succeed, 0 otherwise.
#
sub _multiple_methods {
   my($self,$test,@method)   = @_;
   my($testfunc,@args) = @$test;

   $self->_log_indent(+1);
   my(@print);

   METHOD:
   foreach my $method (@method) {
      my($type,@tmp)   = @$method;
      @OUTPUT          = ();

      if ($type eq 'ignore') {
         next METHOD;

      } elsif ($type eq 'module') {
         my ($module,$vers,$import_list,$eval_string);

         if (ref($tmp[1])) {
            ($module,$import_list,$eval_string) = @tmp;
            $vers = '';
         } else {
            ($module,$vers,$import_list,$eval_string) = @tmp;
         }

         push(@print,
              $self->_log_message('INFO',"Attempting module method: $module"));

         my $err = $self->_load_module($module,$vers,@$import_list);
         if ($err) {
            $self->_log_indent(+1);
            push(@print,
                 $self->_log_message('INFO',"Failed to load module: $module"));
            $self->_log_indent(-1);
            next METHOD;
         }

         push(@OUTPUT,eval "$eval_string");

      } elsif ($type eq 'system'  ||
               $type eq 'system-null') {
         my($bin,$command,@args) = @tmp;

         my $exe = $self->_find_exe($bin);
         if (! $exe) {
            push(@print,
                 $self->_log_message('INFO',"System command not found: $command"));
            next METHOD;
         }

         my $cmd;
         if ($type eq 'system-null') {
            $cmd = '(' . join(' ',$command,@args) . ") > /dev/null";
         } else {
            $cmd = '(' . join(' ',$command,@args) . ") > '$TMPDIR/cmd.out'";
         }
         $cmd =~ s/\{$bin\}/$exe/g;

         push(@print,
              $self->_log_message('INFO',"Attempting system command: $cmd"));

         if (system($cmd) != 0) {
            $self->_log_indent(+1);
            push(@print,
                 $self->_log_message('INFO',"Failed system command: $command"));
            $self->_log_indent(-1);
            next METHOD;
         }

         if ($type eq 'system-null') {
            @OUTPUT  = ();
         } else {
            my $in = new IO::File;
            $in->open("$TMPDIR/cmd.out");
            my @out = <$in>;
            $in->close();
            chomp(@out);
            @OUTPUT  = @out;
         }

      } elsif ($type eq 'function') {
         my($coderef,@args) = @$method;

         my @out = &$coderef(@args);
         chomp(@out);
         @OUTPUT  = @out;
      }

      if (&$testfunc(@args)) {
         $self->_log_indent(-1);
         return 1;
      }
   }

   if (@print) {
      $self->_log_message('NONE',@print);
   }
   $self->_log_message('WARN','All methods for this task failed',
                       'Please make sure one of the above methods works.');

   $self->_log_indent(-1);
   return 0;
}

############################################################################
# Read in an opts file
#
sub _opt_file {
   my($self,$file) = @_;

   if (! -r $file) {
      $self->_log_message('ERR',"Options file not readable: $file");
   }

   my $succ;
   if ($file =~ /\.(yml|yaml)$/i) {

      $succ = $self->_multiple_methods
        ( [ sub { 1; } ],
          [ 'module', 'YAML::XS', [],
            "my \@tmp = YAML::XS::LoadFile('$file'); " .
            "\$OUTPUT = \$tmp[0]" ],
          [ 'module', 'YAML::Tiny', [],
            "my \@tmp = YAML::Tiny::LoadFile('$file'); " .
            "\$OUTPUT = \$tmp[0]" ],
          [ 'module', 'YAML', [],
            "my \@tmp = YAML::LoadFile('$file'); " .
            "\$OUTPUT = \$tmp[0]" ],
          [ 'module', 'YAML::Syck', [],
            "my \@tmp = YAML::Syck::LoadFile('$file'); " .
            "\$OUTPUT = \$tmp[0]" ],
        );

   } elsif ($file =~ /\.json$/i) {

      $succ = $self->_multiple_methods
        ( [ sub { 1; } ],
          [ 'module', 'JSON::XS', ['decode_json'],
            "my \$fh; " .
            "open \$fh,'<:utf8','$file'; " .
            "my \$json_text = do { local \$/; <\$fh> }; " .
            "\$OUTPUT = decode_json(\$json_text);" ],
          [ 'module', 'JSON', ['from_json'],
            "my \$fh; " .
            "open \$fh,'<:utf8','$file'; " .
            "my \$json_text = do { local \$/; <\$fh> }; " .
            "\$OUTPUT = from_json(\$json_text);" ],
          [ 'module', 'JSON::PP', ['decode_json'],
            "my \$fh; " .
            "open \$fh,'<:utf8','$file'; " .
            "my \$json_text = do { local \$/; <\$fh> }; " .
            "\$OUTPUT = decode_json(\$json_text);" ],
          [ 'module', 'JSON::DWIW', ['from_json'],
            "my \$fh; " .
            "open \$fh,'<:utf8','$file'; " .
            "my \$json_text = do { local \$/; <\$fh> }; " .
            "\$OUTPUT = from_json(\$json_text);" ],
        );

   } else {
      $self->_log_message('ERR',"Options file must be YAML or JSON: $file");
   }

   if (! $succ) {
      $self->_log_message('ERR',"Unable to read options file: $file");
   }

   return ()  if (! exists $OUTPUT->{$$self{'package'}});

   my @opts;

   foreach my $line (@{ $OUTPUT->{$$self{'package'}} }) {
      if ($line =~ /^(.+?)(?:\s+|=)(.+?)\s*$/) {
         push(@opts,$1,$2);
      } else {
         push(@opts,$line);
      }
   }

   return @opts;
}

###############################################################################
# This either renames or copies a file.
#
sub _backup_file {
   my($self,$file1,$file2,$copy) = @_;

   if ($copy) {

      if (-d $file2) {
         my @f  = split(/\//,$file1);
         my $f  = pop(@f);
         $file2 = "$file2/$f";
      }

      if (-f $file2) {
         if (! unlink $file2) {
            $self->_log_message('ERR',
                        "Unable to remove/overwrite file: $file2: $!");
         }
      }

      my $succ = $self->_multiple_methods( [ sub { -f "$file2" } ],
                                           ['module','File::Copy',['copy'],
                                            "copy('$file1','$file2')" ],
                                           ['system','cp',
                                            "{cp} '$file1' '$file2'"],
                                         );

      if (! $succ) {
         $self->_log_message('ERR',"Unable to copy file: $file1 -> $file2");
      }

   } else {
      if (! rename $file1,$file2) {
         $self->_log_message('ERR',"Unable to back up file: $file1");
      }
   }
}

###############################################################################
###############################################################################

# This will install a newly created RPM into a yum repository.  It will include
# both the RPM and SRPM.

sub _install_yum {
   my($self) = @_;
   my $yum   = $$self{'yum'};
   $self->_log_message('HEAD',"Installing in yum repository: $package{name}");

   if (! -d $yum) {
      $self->_log_message('ERR',"Yum directory does not exist: $yum");
   }

   if (! -d "$yum/RPMS"  ||
       ! -d "$yum/SRPMS") {
      $self->_log_message('ERR',
                          "Yum directory invalid (no RPMS/SRPM subdir): $yum");
   }

   # Copy in the binary RPM

   my $dir;
   if (-d "$yum/RPMS/$package{arch_val}") {
      $dir = "$yum/RPMS/$package{arch_val}";
   } else {
      $dir = "$yum/RPMS";
   }

   $self->_backup_file($package{'rpmfile'},$dir,"copy");

   # Copy in the source RPM

   $self->_backup_file($package{'srpmfile'},"$yum/SRPMS","copy");
}

###############################################################################
###############################################################################

# This will install a newly created RPM on the current system.  This will
# allow us to create other RPMs that depend on this one.

sub _install_rpm {
   my($self) = @_;

   $self->_log_message('HEAD',"Installing RPM: $package{name}");

   my @args = qw(-U);
   if      ($$self{'install'} eq 'new') {
      @args = qw(-i);
   } elsif ($$self{'install'} eq 'force') {
      @args = qw(-U --force);
   }

   my @cmd = ('rpm',@args,$package{rpmfile});

   if ($<) {
      my $sudo = $self->_find_exe('sudo');
      if (! $sudo) {
         $self->_log_message('ERR',
                             'sudo not found.  The rpm will not be installed.');
      }
      unshift (@cmd,$sudo);
   }

   my $cmd = join(' ',@cmd);
   $self->_log_message('INFO',"Attempting system command: $cmd");

   if (system(@cmd) != 0) {
      $self->_log_message('ERR','Installation failed.');
   }
}

###############################################################################
###############################################################################

# This will sign a newly created RPM.  It may use the perl expect module,
# the expect executable, or it can do it interactively.

sub _sign_rpm {
   my($self) = @_;

   $self->_log_message('HEAD',"Signing RPM: $package{name}");

   my $gpg = $self->_find_exe('gpg');
   if (! $gpg) {
      $self->_log_message('ERR',"gpg program not found in path.");
   }

   #
   # First, let's get the value of the GPG path
   #

   my $path  = '';    # The gpg option to set the path to use (if not the default)
   my $macro = '';    # The value of the rpm macro.

   $macro    = `rpm --eval '%_gpg_path'`;
   chomp($macro);
   $macro    = ''  if ($macro eq '%_gpg_path');

   if ($$self{'gpg_path'}) {

      if (! -d $$self{'gpg_path'}) {
         $self->_log_message('ERR',
                             "GPG directory does not exist: $$self{gpg_path}");
      }

      if ($macro) {

         if ($$self{'gpg_path'} ne $macro) {
            # We're overriding a value set in the rpm macro file.

            $self->_log_message('WARN',
                        '--gpg-path option overriding value in RPM macro file',
                        "   --gpg-path = $$self{gpg_path}",
                        "   \%_gpg_path = $macro");
            $path = "--homedir $$self{'gpg_path'}";

            # We have to add it to the macros file.  We'll just tack
            # it on the end since this will effectively override the
            # value there.

            my $macros = "$ENV{HOME}/.rpmmacros";
            $$self->_add_macro($macros,'%_gpg_path',$$self{'gpg_path'});
         }
      }

   } elsif ($macro) {

      if (! -d $macro) {
         $self->_log_message('ERR',
                             "GPG directory from rpmmacros does not exist: $macro");
      }

   }

   $self->_log_message('INFO',"GPG path = $path");

   #
   # Next, let's get the value of the GPG user.
   #

   my $name  = '';   # The gpg option to set the user to use.
   $macro    = '';   # The value of the rpm macro.

   $macro    = `rpm --eval '%_gpg_name'`;
   chomp($macro);
   $macro    = ''  if ($macro eq '%_gpg_name');

   if ($$self{'gpg_name'}) {

      if ($macro) {

         if ($$self{'gpg_name'} ne $macro) {
            # We're overriding a value set in the rpm macro file.

            $self->_log_message('WARN',
                        '--gpg-name option overriding value in RPM macro file',
                        "   --gpg-name = $$self{gpg_name}",
                        "   \%_gpg_name = $macro");
            $name = "'$$self{'gpg_name'}'";

            # We have to add it to the macros file.  We'll just tack
            # it on the end since this will effectively override the
            # value there.

            my $macros = "$ENV{HOME}/.rpmmacros";
            $$self->_add_macro($macros,'%_gpg_name',$$self{'gpg_name'});
         }
      }
   }

   $name = "'$macro'"  if ($macro  &&  ! $name);

   $self->_log_message('INFO',"GPG name = $name");

   #
   # Now let's make sure that we actually have exactly one key.
   #

   my @out = `$gpg $path --list-keys $name | grep '^uid'`;
   if (! @out) {
      $self->_log_message('ERR',
                          'No keys found in this GPG keyring.',
                          'Use --gpg-path to specify an alternate GPG path',
                          'or create a key in this keyring.');
   }
   if (@out != 1) {
      $self->_log_message('ERR',
                          'Multiple keys found in this keyring',
                          'Use --gpg-user to specify a single user.');
   }

   #
   # Sign it.
   #

   SIGN:
   {

      if ($$self{'gpg_passwd'}  ||  $$self{'gpg_passfile'}) {

         my $err = $self->_load_module("Expect");
         if (! $err) {
            $err = $self->_sign_perlexpect();
            if ($err) {
               $self->_log_message('ERR','PGP passphrase incorrect');
            }
            last SIGN;
         }

         my $expect = $self->_find_exe('expect');
         if ($expect) {
            $err = $self->_sign_expect($expect);
            if ($err) {
               $self->_log_message('ERR','PGP passphrase incorrect');
            }
            last SIGN;
         }
      }

      $self->_sign_interactive();
      last SIGN;
   }
}

sub _sign_expect {
   my($self,$expect) = @_;

   $self->_log_message('INFO',"Signing with non-interactive expect script");

   my $pass;
   if ($$self{'gpg_passwd'}) {
      $pass = $$self{'gpg_passwd'};
   } else {
      $pass = `cat $$self{'gpg_passfile'}`;
      chomp($pass);
   }

   my $out  = new IO::File;
   my $file = "$TMPDIR/cpantorpm-expect-sign-wrapper";
   $out->open("> $file");

   print $out <<"EOF";
#!$expect

spawn rpm --addsign $package{rpmfile} $package{srpmfile}
expect -exact "Enter pass phrase: "
send -- "$pass\\r"

expect {
  "Pass phrase check failed" { puts "Failed" }
  eof { puts "Success" }
}
EOF

   $out->close();
   chmod 0755,$file;

   open(IN,"'$file' |");
   my @out = <IN>;
   close(IN);
   unlink $file;
   if ( grep /Failed/,@out ) {
      return 1;
   }
   return 0;
}

{
   my $flag;

   sub _sign_perlexpect {
      my($self) = @_;
      $self->_log_message('INFO',"Signing with non-interactive perl Expect script");

      my $pass;
      if ($$self{'gpg_passwd'}) {
         $pass = $$self{'gpg_passwd'};
      } else {
         $pass = `cat $$self{'gpg_passfile'}`;
         chomp($pass);
      }

      my $exp = Expect->spawn('rpm','--addsign',
                              $package{rpmfile},$package{srpmfile});
      $exp->expect(undef, "Enter pass phrase:");
      $exp->send("$pass\n");

      $exp->expect(undef,
                   [ "Pass phrase check failed" => sub { $flag = 1; } ],
                   [ "eof"                      => sub { $flag = 0; } ],
                  );

      return $flag;
   }
}

sub _sign_interactive {
   my($self) = @_;
   $self->_log_message('INFO',"Signing with interactive rpm command");

   my @cmd = ('rpm','--addsign', $package{rpmfile}, $package{srpmfile});

   my $cmd = join(' ',@cmd);
   $self->_log_message('INFO',"Attempting system command: $cmd");

   system(@cmd);
}

# This adds a macro to the rpmmacro file in such a way that at the end, it
# will be restored.
#
sub _add_macro {
   my($self,$file,$macro,$val) = @_;

   if (! -f $file) {

      # If the macros file is new, we'll remove it once we're done.
      $package{'remove'} = 1;


   } elsif ($package{'remove'}  ||  $package{'restore'}) {

      # If we've already created a backup of the macros file
      # which will be restore, or if we've already determined
      # that the macros file will be removed, we don't have
      # redetermine anything.

   } else {

      # This is the first time we're adding a macro to
      # the macros file, so we want to save it so that it
      # can be restored at the end.

      $self->_backup_file($file,"$file.cpantorpm",1);
      $package{'restore'} = 1;

   }

   my $out = new IO::File;
   $out->open(">> $file")  ||
     $self->_log_message('ERR',"Unable to write to .rpmmacros file: $!");
   print $out "\n$macro $val\n";
   $out->close();
}

############################################################################
############################################################################

# This will build an RPM/SRPM.

sub _build_rpm {
   my($self) = @_;
   $self->_log_message('HEAD',"Creating RPM: $package{name}");

   #
   # Move the source into the SOURCES directory (as a .tar.gz file)
   #

   my $arch = "$package{topdir}/SOURCES/$package{dir}.tar.gz";
   my $succ = $self->_multiple_methods
     ( [ sub { -f $arch } ],
       ['system','tar',"cd $TMPDIR; {tar} czf $arch $package{dir}"],
       ['module','Archive::Tar', [],
        "my \$tar = new Archive::Tar; \$tar->setcwd($TMPDIR); \$tar->add_files($package{dir}; \$tar->write($arch,COMPRESS_GZIP;"],
     );

   #
   # Figure out how to build RPMs
   #

   my $rpmbuild = $self->_find_exe("rpmbuild");
   if (! $rpmbuild) {

      my $rpm = $self->_find_exe("rpm");
      if (! $rpm) {
         $self->_log_message('ERR','Unable to locate rpmbuild command');
      }

      my @out = `$rpm -ba 2>&1`;
      chomp(@out);
      my @tmp = grep(/unknown option/,@out);
      if (@tmp) {
         $self->_log_message('ERR',
                             'Unable to locate rpm command that supports -ba');
      }

      $rpmbuild = $rpm;
   }

   if ($$self{'no_tests'} == 1) {
      $ENV{'RPMBUILD_NOTESTS'} = 1;
   }

   my @cmd = ($rpmbuild,"-ba",
              ($$self{'no_clean'}  ? ("--noclean")
                                   : ("--clean")),
              ($$self{'no_deps'}   ? ("--nodeps")
                                   : ()),
              ($$self{'rpmbuild'}  ? ("--define","_topdir $$self{'rpmbuild'}")
                                   : ()),
              "$package{topdir}/SPECS/$package{specname}");

   my $cmd = join(' ',@cmd);
   $self->_log_message('INFO',"Attempting system command: $cmd");

   #
   # Build the RPM
   #

   if (system(@cmd) != 0) {
      $self->_log_message('ERR',"Unable to execute $rpmbuild: $!");
   }
   chdir($TMPDIR);

   my $disttag = `rpm --eval '$$self{disttag}'`;
   chomp($disttag);

   $package{'rpmfile'} = "$package{topdir}/RPMS/$package{arch_val}/$package{rpmname}-$package{version}-$package{release}$disttag.$package{arch_val}.rpm";
   $package{'srpmfile'} = "$package{topdir}/SRPMS/$package{rpmname}-$package{version}-$package{release}$disttag.src.rpm";
}

############################################################################
############################################################################

# The process of generating the spec file is taken in large part from the
# cpanspec script.

sub _make_spec {
   my($self) = @_;

   $self->_log_message('HEAD',"Writing spec file: $package{name}");

   setlocale(LC_ALL, "en_US.UTF-8");

   #
   # A few more package values.
   #

   $package{'release'} = $$self{'release'};
   $package{'disttag'} = $$self{'disttag'};
   $package{'url'}     = ($package{'from'} eq 'url' ?
                          $package{'fromsrc'} :
                          "http://search.cpan.org/dist/$package{name}/");
   $package{'epoch'}   = $$self{'epoch'}  if ($$self{'epoch'} ne '');
   $package{'group'}   = $$self{'group'};
   $package{'license'} = ($package{'m_license'} ?
                          $package{'m_license'} :
                          'GPL+ or Artistic');
   $package{'source'} =
     ($package{'from'} eq 'CPAN' ?
      "http://search.cpan.org/authors/id/$package{cpandir}/$package{archive}" :
      $package{'fromsrc'} );

   foreach my $key (keys %{ $Macros{$$self{'macros'}} }) {
      my $val = $Macros{$$self{'macros'}}{$key};
      $package{$key} = $val;
   }

   #
   # Find out if there are is a post-build script.
   #

   $self->_post_build();

   #
   # Make sure we can run rpm.
   #

   my $cmd = 'rpm --version > /dev/null';
   $self->_log_message('INFO',"Attempting system command: $cmd");

   if (system($cmd) != 0) {
      $self->_log_message('ERR','Unable to run rpm.');
   }

   #
   # Make sure that the RPM build hierarchy exists.
   #

   $self->_check_rpm_build();
   $self->_log_message('INFO',"SPEC file: $package{topdir}/SPECS/$package{specname}");

   #
   # Every package needs a packager.
   #

   if ($$self{'packager'}) {
      $package{'packager'} = $$self{'packager'};
   } else {
      my $tmp = `rpm --eval '\%packager'`;
      chomp($tmp);

      if (! $tmp  ||  $tmp eq "\%packager") {
         $self->_log_message('ERR','%packager not defined in ~/.rpmmacros.',
                           'Add it or use the --packager option.');
      }
      $package{'packager'} = $tmp;
   }

   #
   # Some values may contain email addresses which might be of the form:
   #    Name <Email>
   # and the brackets <> conflict with the SPEC file templated.
   #
   # The values where this can occur are:
   #    args     : this is already taken care of (< was turned to \<)
   #    packager : a single value
   #    author   : multiple values
   #
   # We need to escape the brackets in the unhandled cases.
   #

   foreach my $val ($package{'packager'},@{ $package{'author'} }) {
      $val =~ s/</\\</g;
      $val =~ s/>/\\>/g;
   }

   #
   # Start spec file creation...
   #

   my $out = new IO::File;
   $out->open("> $package{topdir}/SPECS/$package{specname}")  ||
     $self->_log_message('ERR',
                         "Unable to create spec file: $package{specname}: $!");

   #
   # The SPEC file is a stored in the __DATA__ section of this script.
   #

   my @tmp = <DATA>;
   chomp(@tmp);
   my @lines;

   # @stack contains listrefs:
   #    [ KEEP, END_STRING, TOGGLE_STRING ]
   # KEEP is 1 if we're using these lines.
   # When a line is found with END_STRING, the structure ends.
   # When a line is foud with TOGGLE_STRING, KEEP is toggled.

   my(@stack) = ();

   LINE:
   while (@tmp) {
      my $line = shift(@tmp);

      last  if ($line eq '<eof>');

      # If we're currently in an <if> <else> <endif> conditional, look
      # for <else> and <endif>.

      if (@stack) {
         my($keep,$end,$toggle) = @{ $stack[$#stack] };

         if      ($line =~ /$end/) {
            pop(@stack);
            next LINE;
         } elsif ($line =~ /$toggle/) {
            $stack[$#stack][0] = 1 - $keep;
            next LINE;
         }

         next LINE  if (! $keep);
      }

      # Set up a new:
      #   <if:VAR>
      # structure.

      if ($line =~ /<if:([^>]+)>/) {
         my $var  = $1;
         my $keep = (exists $package{$var}  &&  $package{$var} ? 1 : 0);
         push @stack,[$keep,"<endif:$var>","<else:$var>"];
         next LINE;
      }

      if ($line =~ /(<list:([^>]+)>)/) {
         my($tag,$var) = ($1,$2);
         my @l;
         foreach my $ele (@{ $package{$var} }) {
            my $l = $line;
            $l    =~ s/$tag/$ele/g;
            push(@l,$l);
         }
         unshift(@tmp,@l);
         next LINE;
      }

      if ($line =~ /(<hash:(?:(true|false):)?([^>]+)>)/) {
         my($tag,$flag,$var) = ($1,$2,$3);
         $flag          = ''  if (! $flag);

         my @l;
         foreach my $key (sort keys %{ $package{$var} }) {
            my $val = $package{$var}{$key};
            next  if ( ($flag eq 'true'   &&  ! $val)  ||
                       ($flag eq 'false'  &&  $val) );
            my $tmp = $line;
            $tmp =~ s/$tag/$key/g;
            $tmp =~ s/<val>/$val/g;
            push(@l,$tmp);
         }
         unshift(@tmp,@l);
         next LINE;
      }

      while ($line =~ /<skip:([^>]+)>/) {
         my $var = $1;

         if (exists $package{$var}) {
            $line =~ s/<skip:$var>/$package{$var}/g;
         } else {
            next LINE;
         }
      }

      while ($line =~ /(?<!\\)(<(?:(quiet):)?([^>]+)>)/) {
         my ($tag,$flag,$var) = ($1,$2,$3);
         $flag = ''  if (! $flag);

         if (exists $package{$var}) {
            $line =~ s/$tag/$package{$var}/g;
         } else {
            $line =~ s/$tag//g;
            $self->_log_message('WARN',"Package variable not defined: $var",
                               "   Line: $line")
              if ($flag ne 'quiet');
         }
         # The description/summary may contain POD markup (B<text>) that
         # we don't want to interpret as macros.

         if ($var eq 'desc'  ||  $var eq 'summary') {
            $line =~ s/(?:[IBCFS])<(.*?)>/$1/sg;
            $line =~ s/(?:[XZ])<(.*?)>//sg;
            last;
         }
      }

      $line =~ s/\\</</g;
      $line =~ s/\\>/>/g;
      push(@lines,$line);
   }

   foreach my $line (@lines) {
      print $out "$line\n";
   }

   $out->close();
}

sub _post_build {
   my($self) = @_;
   return  if (! $$self{'script_dir'});

   my $script;

   if (-f "$$self{script_dir}/$package{fromsrc}.build-sh") {
      $script = "$$self{script_dir}/$package{fromsrc}.build-sh";

   } else {
      return;
   }

   # Run the script.

   $self->_log_message('INFO',"Post %build script: $script");

   my @cmd = `cat $script`;
   chomp(@cmd);
   $package{'post_build'} = [ @cmd ];
}

sub _check_rpm_build {
   my($self) = @_;

   $self->_log_message('INFO',"Checking RPM build dir");

   #
   # Check to see if there is a conflict between %_topdir in .rpmmacros
   # file and $$self{rpmbuild} .  We won't use 'rpm --eval' because it's only
   # a conflict if the value in MY rpm macro file differs.
   #

   my $macros = "$ENV{HOME}/.rpmmacros";

   if ($$self{'clean_macros'}) {
      if (-f $macros) {
         $self->_backup_file($macros,"$macros.cpantorpm",0);
         $package{'restore'} = 1;
      }
   }

   my $macroval;
   if (-f $macros) {
      my $in = new IO::File;
      $in->open($macros)  ||
        $self->_log_message('ERR',"Unable to open .rpmmacros file: $!");
      my @in = <$in>;
      $in->close();

      # Multiple %_topdir lines are allowed... last one is used
      my @tmp = grep /^\s*\%_topdir\s+/,@in;
      if (@tmp) {
         my $tmp = pop(@tmp);
         $tmp =~ /^\s*\%_topdir\s+(.*)\s*$/;
         $macroval = $1;

         # If the macro is found and it differs from the one we specified
         # on the command line, we're going to error out.

         if ($$self{'rpmbuild'}  &&  $macroval ne $$self{'rpmbuild'}) {
            $self->_log_message('ERR',
                                'RPM build tree conflict',
                                "   ~/.rpmmacros : $macroval",
                                "   --rpmbuild   : $$self{rpmbuild}",
                                'Use the --clean-macros option to proceed.');
         }
      }
   }

   #
   # If the RPM build dir was specified on the command line (--rpmbuild), but
   # was not found in the macrofile, we'll back up the file and add the
   # %_topdir macro.
   #

   if ($$self{'rpmbuild'}  &&  ! $macroval) {
      $self->_add_macro($macros,'%_topdir',$$self{'rpmbuild'});
   }

   #
   # Now make sure that the RPM build tree exists, and is writable.
   #

   my $topdir;
   if ($$self{'rpmbuild'}) {
      $topdir = $$self{'rpmbuild'};
   } else {
      $topdir = `rpm --eval '%_topdir'`;
      chomp($topdir);
   }
   my $arch   = `rpm --eval '%_arch'`;
   chomp($arch);

   $package{'topdir'}  = $topdir;
   $package{'rpmarch'} = $arch;

   $self->_log_message('INFO',"RPM build dir:  $topdir");
   $self->_log_message('INFO',"RPM build arch: $arch");

   if (! -d $topdir) {
      $self->_log_message('INFO',"Creating directory: $topdir");
      $self->_make_dir($topdir);
   }
   if (! -w $topdir) {
      $self->_log_message('ERR',
                          "Unable to write to directory: $topdir",
                          'Make sure permissions are correct.');
   }

   foreach my $subdir (qw( BUILD
                           SOURCES
                           SPECS
                           SRPMS
                           RPMS
                           RPMS/noarch
                        ),
                       "RPMS/$arch") {
      if (! -d "$topdir/$subdir") {
         $self->_log_message('INFO',"Creating directory: $subdir");
         $self->_make_dir("$topdir/$subdir");
      }
   }
}

# After the program completes, if we added any macros, revert to the original
# version.

END:
{
   my $macros = "$ENV{HOME}/.rpmmacros";
   my $self   = $package{'self'};
   if      ($package{'restore'}) {
      rename "$macros.cpantorpm",$macros  ||
        $self->_log_message('WARN',"Unable to restore .rpmmacros file: $!");
   } elsif ($package{'remove'}) {
      unlink $macros  ||
        $self->_log_message('WARN',
                            "Unable to remove temporary .rpmmacros file: $!");
   }
}

############################################################################
############################################################################

# After building the package, missing META files will have been
# created, so we will now go back and repeat the process of analyzing
# them rather than trying to get that information from the Build.PL or
# Makefile.PL files.

sub _get_meta {
   my($self) = @_;

   $self->_log_message('HEAD',
                       "Reading package metadata (post-build): $package{dir}");

   my %files = $self->_get_filelist($package{"DIR"});
   $self->_categorize_files("post_build",$package{"DIR"},%files);

   # Get rid of any requirements previously deduced since they may not
   # have come from a META file.

   foreach my $type (keys %{ $package{'requires'} }) {
      delete $package{"${type}_req"};
   }
   delete $package{'requires'};

   foreach my $f (qw(meta.json mymeta.json meta.yml mymeta.yml)) {
      my $type = ($f =~ /json/ ? 'json' : 'meta');
      $self->_get_meta_meta($type,$files{$f})    if (exists $files{$f});
   }

   $package{'arch'}     = (exists $package{'files'}{'xs'} ? '%{_arch}' : 'noarch');
   my $tmp              = `rpm --eval '$package{arch}'`;
   chomp($tmp);
   $package{'arch_val'} = $tmp;

   #
   # If we passed in --name, we'll use that.  Otherwise, we'll get it from
   # the package name (which MUST match the META name).
   #

   if ($$self{'name'}) {
      $package{'name'} = $$self{'name'};
   } else {
      if ($package{'m_name'}  &&
          $package{'m_name'} ne $package{'dist'}) {
         $self->_log_message
           ('ERR',
            "The name obtained from metadata is different: $package{dir}",
            "The name of the package obtained from the archive file",
            "and the one obtained from the metadata are not the same.",
            "   Archive:  $package{dist}",
            "   Metadata: $package{m_name}",
            "They must be the same, OR you must manually set the name",
            "with the --name option.");
      }

      $package{'name'} = $package{'dist'};
   }

   #
   # If we passed in --vers, we'll use that.  Otherwise, we'll get it from
   # the package version (which MUST match the META version).
   #

   if ($$self{'version'}) {
      $package{'version'} = $$self{'version'};
   } else {
      if ($package{'m_version'}  &&
          $package{'m_version'} ne $package{'vers'}) {
         $self->_log_message
           ('ERR',
            "The version obtained from metadata is different: $package{dir}",
            "The version of the package obtained from the archive file",
            "and the one obtained from the metadata are not the same.",
            "   Archive:  $package{vers}",
            "   Metadata: $package{m_version}",
            "They must be the same, OR you must manually set the version",
            "with the --version option.");
      }

      $package{'version'} = $package{'vers'};
   }

   #
   # Make sure we've got authors.
   #

   if (@{ $$self{'author'} }) {
      $package{'author'} = [@{ $$self{'author'} }];
   } else {
      if (! $package{'m_author'}) {
         $self->_log_message
           ('WARN',
            "Unable to determine author(s): $package{dir}",
            "This can be specified them using the --author option.");
         $package{'author'} = ['No author information listed in META file.'];
      } elsif (! ref($package{'m_author'})) {
         $package{'author'} = [ $package{'m_author'} ];
      } else {
         $package{'author'} = [ @{ $package{'m_author'} } ];
      }
   }

   #
   # Make sure we've got a module description.  If we included a --description
   # option, use it.  Otherwise, we'll see if it was included in the META
   # files or the main POD file.
   #

   if ($$self{'description'}) {

      if (-r $$self{'description'}) {
         my $in = new IO::File;
         $in->open($$self{'description'});
         $package{'desc'} = join('',<$in>);
      } else {
         $self->_log_message
           ('ERR',
            "--description option invalid: $$self{description}",
            "--description must contain the path to a readable file",
            "containing the package description.");
      }

   } elsif ($package{'m_description'}) {
      $package{'desc'} = $package{'m_description'};

   } elsif ($package{'files'}{'mainpod'}  &&
            $package{'files'}{'mainpod'}[3]) {
      $package{'desc'} = $package{'files'}{'mainpod'}[3];

   } else {
      $package{'desc'} = 'A perl module';
   }


   #
   # Same thing with the summary.
   #

   if ($$self{'summary'}) {
      $package{'summary'} = $$self{'summary'};

   } elsif ($package{'m_abstract'}) {
      $package{'summary'} = $package{'m_abstract'};

   } elsif ($package{'files'}{'mainpod'}  &&
            $package{'files'}{'mainpod'}[2]) {
      $package{'summary'} = $package{'files'}{'mainpod'}[2];

   } else {
      $package{'summary'} = 'A perl module';
   }

   #
   # Handle the prefix and get various file names.
   #

   $package{'prefix'}   = $$self{'prefix'};
   my $pkgname          = $$self{'prefix'} . $package{'name'};
   $package{'rpmname'}  = $pkgname;
   $package{'specname'} = "$pkgname.spec";

   #
   # Check the requires/provides for this package.
   #

   $self->_provides();
   $self->_requires('instfiles');

   #
   # Now clean up the directory.
   #

   system("cd $package{DIR}; $package{clean_cmd}");
}

# Get a list of all of the files in the package.  We'll ignore directories.
# It will return a hash:
#    { LC_FILE => { FILE => 1 } }
# where LC_FILE is a file (all lowercased) and FILE is the same file (or files)
# in the case they actually exist.  All FILE and LC_FILE are the paths
# relative to the top directory in the package.
#
#    {
#      manifest  => { MANIFEST => 1 }
#      t/readme  => { t/README => 1,
#                     t/Readme => 1 }
#    }
#
sub _get_filelist {
   my($self,$dir) = @_;

   $self->_log_message('INFO',"Listing package files");

   my $succ = $self->_multiple_methods
     ( [ sub { 1; } ],
       [ 'module','File::Find',['find'],
         qq< find(sub { push(\@OUTPUT,\$File::Find::name) if (-f) },"$dir"); >
       ],
       [ 'system','find',
         "{find} '$dir' -type f" ]
     );

   my %files;
   foreach my $file (@OUTPUT) {
      $file =~ s,^$dir/,,;
      next  if (! $file);

      $files{lc($file)}{$file} = 1;
   }

   return %files;
}

# This looks at the filelist determines which are pod files, which are
# .pm files, which are test files, etc.
#
sub _categorize_files {
   my($self,$op,$dir,%files) = @_;

   $self->_log_message('INFO',"Categorizing $op package files");

   # First pass based on some simple tests.

   my $in = new IO::File;

   foreach my $file (keys %files) {
      foreach my $f (keys %{ $files{$file} }) {

         if ($op eq 'build') {

            # Files in the blib directory:
            #
            # Ignored:
            #   */*.exists
            #
            # PM files:
            #   **/*.pm
            #
            # Bin files
            #   bin/*
            #   script/*
            #
            # man1 files:
            #   man1/*
            #   bindoc/*
            #
            # man3 files:
            #   man3/*
            #   libdoc/*

            if      ($f =~ /\.exists$/) {
               next;

            } elsif ($f =~ m,^lib/\Q$ARCH\E/.*\.pm$,  ||
                     $f =~ m,^arch/auto/.*\.pm$,) {
               $package{'instfiles'}{'pm'}{$f}      = 1;
               $package{'arch_inst'}                = 1;

            } elsif ($f =~ m,.*\.pm$,) {
               $package{'instfiles'}{'pm'}{$f}      = 1;
               $package{'lib_inst'}                 = 1;

            } elsif ($f =~ m,^lib/\Q$ARCH\E/.*\.so$,  ||
                     $f =~ m,^arch/auto/.*\.so$,) {
               $package{'instfiles'}{'lib'}{$f}     = 1;
               $package{'arch_inst'}                = 1;

            } elsif ($f =~ m,^(script|bin)/,) {
               $package{'instfiles'}{'scripts'}{$f} = 1;
               $package{'bin_inst'}                 = 1;

            } elsif ($f =~ m,^man1/,  ||
                     $f =~ m,^bindoc/,) {
               $package{'instfiles'}{'man1'}{$f}    = 1;
               $package{'man1_inst'}                = 1;

            } elsif ($f =~ m,^man3/,  ||
                     $f =~ m,^libdoc/,) {
               $package{'instfiles'}{'man3'}{$f}    = 1;
               $package{'man3_inst'}                = 1;
            }

         } else {

            # Package files:
            #
            # Test files:
            #   t/*.t
            #   t/*.pl
            #   t/*.pm
            #
            # Build files:
            #   Makefile.PL
            #   Build.PL
            #   inc/*.pm
            #
            # POD files:
            #   *.pod
            #
            # PM files:
            #   *.pm
            #
            # XS files:
            #   *.c
            #   *.xs
            #
            # Scripts:
            #   *.pl
            #   Anything that starts with '#!'

            if ($f =~ m,^t/.*\.(t|pl|pm)$,) {
               $package{'files'}{'t'}{$f} = '';

            } elsif ($f =~ m,^t/,) {
               next;

            } elsif ($f =~ m,^blib/,  ||
                     $f =~ /pm_to_blib/) {
               next;

            } elsif ($f =~ m,^inc/.*\.pm$,  ||
                     lc($f) eq 'makefile.pl'  ||
                     lc($f) eq 'build.pl') {
               $package{'files'}{'build'}{$f} = '';

            } elsif ($f =~ m,^inc/,) {
               next;

            } elsif ($f =~ m,\.pod$,) {
               $package{'files'}{'pod'}{$f} = '';

            } elsif ($f =~ m,\.pm$,) {
               $package{'files'}{'pm'}{$f} = '';

            } elsif ($f =~ m,\.(c|xs)$,) {
               $package{'files'}{'xs'}{$f} = '';

            } elsif ($f =~ m,\.pl$,) {
               $package{'files'}{'scripts'}{$f} = '';

            } else {
               $in->open("$dir/$f");
               my $line = <$in>;
               if ($line  &&  $line =~ /^\#\!/) {
                  $package{'files'}{'scripts'}{$f} = '';
               }
            }
         }
      }
   }

   # If we are doing an arch install, then turn off the noarch lib_inst
   if ($package{'arch_inst'}) {
      $package{'lib_inst'}=0;
   }

   #
   # We need to decide (if possible) which is the 'main' pod file.
   #
   # This only has to be done once (at the post_build step).
   #

   return  if ($op ne 'post_build');

   # Scripts and .pm files may also be pod.

   $package{'files'}{'pm'}      = {}  if (! exists $package{'files'}{'pm'});
   $package{'files'}{'scripts'} = {}  if (! exists $package{'files'}{'scripts'});
   $package{'files'}{'pod'}     = {};

   foreach my $f (keys %{ $package{'files'}{'pm'} },
                  keys %{ $package{'files'}{'scripts'} }) {

      $in->open("$dir/$f");
      my @in = <$in>;
      if (grep /^(=pod|=head1)/,@in) {
         $package{'files'}{'pod'}{$f} = 1;
      }
   }

   $self->_log_message('INFO',"Determining the main POD file");

   my($mainpod,$name,$summary,$description);

   POD:
   while (1) {
      my @pod = keys %{ $package{'files'}{'pod'} };

      #
      # If it was specified using the --mainpod option.
      #

      if ($$self{'mainpod'}) {
         if (! -f "$dir/$$self{mainpod}") {
            $self->_log_message
              ('WARN',
               "No data obtained from POD file; $$self{mainpod}",
               "POD file specified with --mainpod does not exist.",
               "Automatic detection of main POD file will be attempted.");

         } else {
            if (! exists $package{'files'}{'pod'}{$$self{'mainpod'}}) {
               $self->_log_message
                 ('WARN',
                  "No data obtained from POD file; $$self{mainpod}",
                  "File specified with --mainpod does not appear to be a POD file.",
                  "It will be tried in spite of this.");
            }
            ($name,$summary,$description) = $self->_get_meta_pod($$self{'mainpod'});

            if (! $name) {
               $self->_log_message
                 ('WARN',
                  "No data obtained from POD file; $$self{mainpod}",
                  "Unable to read POD data from file specified with --mainpod",
                  "Automatic detection of main POD file will be attempted.");
            } else {
               $mainpod = $$self{'mainpod'};
               last POD;
            }
         }
      }


      #
      # If there's only one pod file, then it's the main one.
      #

      if (@pod == 1) {
         ($name,$summary,$description) = $self->_get_meta_pod($pod[0]);

         if (! $name) {
            $self->_log_message
              ('WARN',
               "No data obtained from POD file; $pod[0]",
               "There is only one POD file, but it does not appear to be valid.",
               "Automatic detection of main POD file failed.");
         } else {
            $mainpod = $pod[0];
         }
         last POD;
      }

      #
      # If we're working with a package named Foo-Bar and there
      # is exactly one pod file named Bar.pod (or Bar.pm), use
      # it if it is valid.
      #

      my @dist = split(/\-/,$package{'dist'});
      my $last = $dist[$#dist];
      my @tmp  = grep /(^|\/)$last\.(pm|pod)$/,@pod;
      if (@tmp == 1) {

         ($name,$summary,$description) = $self->_get_meta_pod($tmp[0]);

         if (! $name) {
            $self->_log_message
              ('WARN',
               "No data obtained from POD file; $tmp[0]",
               "There is only one correctly named POD file, but it does not",
               "appear to be valid.",
               "Automatic detection of main POD file will be attempted.");
         } else {
            $mainpod = $tmp[0];
            last POD;
         }
      }

      #
      # Next, look at all POD files.  If a pod file has a NAME that is
      # the same as the the package name (with :: changed to dashes),
      # this is the main one.  i.e. in a package named Foo-Bar, the
      # first POD file who's NAME is Foo::Bar will be used.
      #

      my $mod_exp = $package{'dist'};
      $mod_exp    =~ s/\-/::/g;

      foreach my $pod (sort keys %{ $package{'files'}{'pod'} }) {
         my($n,$s,$d) = $self->_get_meta_pod($pod);
         $n = ''   if (! $n);

         if ($n eq $mod_exp) {
            ($name,$summary,$description) = ($n,$s,$d);
            $mainpod = $pod;
            last POD;
         }

         $package{'files'}{'pod'}{$pod} = $n;
      }

      #
      # One final attempt will be to see if there is one POD file that
      # is 'shallowest'.  In other words, if the POD files in the distribution
      # are named:
      #   Foo
      #   Foo::Bar
      #   Foo::Bar2
      # we'll take 'Foo' one since it is the least number of levels.  This
      # will only occur if there is exactly 1 POD file at that level.
      #

      my ($n,$f);
      $n = 100;
      foreach my $pod (sort keys %{ $package{'files'}{'pod'} }) {
         my $name = $package{'files'}{'pod'};
         next  if (! $name);

         my @tmp = split(/::/,$name);
         if (@tmp == $n) {
            $f = '';
         } elsif (@tmp < $n) {
            $n = @tmp;
            $f = $pod;
         }
      }

      if ($f) {
         ($name,$summary,$description) = $self->_get_meta_pod($f);
         $mainpod = $f;
         last POD;
      }

      #
      # We weren't able to determine the main POD file.
      #

      $self->_log_message
        ('WARN',"Automatic detection of main POD file failed.");
      last POD;
   }

   if ($mainpod) {
      $package{'files'}{'mainpod'} = [ $mainpod,$name,$summary,$description ];
   }
}

# This will extract the information froma single META file.

sub _get_meta_meta {
   my($self,$type,$filehash) = @_;
   my $meta;

   my @tmp = keys %$filehash;
   if (@tmp != 1) {
      my $tmp = $tmp[0];
      $self->_log_message
        ('WARN',
         "Multiple '$tmp' files exist (with different cases).",
         "This is not supported, so they will be ignored.");
      return;
   }
   my $file = "$package{DIR}/$tmp[0]";
   $OUTPUT = '';

   $self->_log_message('INFO',"Reading META file: $tmp[0]");

   my $succ;
   if ($type eq 'json') {

      $succ = $self->_multiple_methods
        ( [ sub { 1; } ],
          [ 'module', 'Parse::CPAN::Meta', '1.41', [],
            "\$OUTPUT = Parse::CPAN::Meta->load_file('$file')" ],
          [ 'module', 'JSON', ['from_json'],
            "my \$fh; " .
            "open \$fh,'<:utf8','$file'; " .
            "my \$json_text = do { local \$/; <\$fh> }; " .
            "\$OUTPUT = from_json(\$json_text);" ],
          [ 'module', 'JSON::XS', ['decode_json'],
            "my \$fh; " .
            "open \$fh,'<:utf8','$file'; " .
            "my \$json_text = do { local \$/; <\$fh> }; " .
            "\$OUTPUT = decode_json(\$json_text);" ],
          [ 'module', 'JSON::PP', ['decode_json'],
            "my \$fh; " .
            "open \$fh,'<:utf8','$file'; " .
            "my \$json_text = do { local \$/; <\$fh> }; " .
            "\$OUTPUT = decode_json(\$json_text);" ],
          [ 'module', 'JSON::DWIW', ['from_json'],
            "my \$fh; " .
            "open \$fh,'<:utf8','$file'; " .
            "my \$json_text = do { local \$/; <\$fh> }; " .
            "\$OUTPUT = from_json(\$json_text);" ],
        );

   } else {

      $succ = $self->_multiple_methods
        ( [ sub { 1; } ],
          # [ 'module', 'Parse::CPAN::Meta', [],
          #   "\$OUTPUT = Parse::CPAN::Meta::LoadFile('$file')" ],
          # [ 'module', 'CPAN::Meta::YAML', [],
          #   "my \$fh; " .
          #   "open \$fh,'<:utf8','$file'; " .
          #   "my \$yaml_text = do { local \$/; <\$fh> }; " .
          #   "my \$tmp = CPAN::Meta::YAML->read_string(\$yaml_text);" .
          #   "\$OUTPUT = \$tmp->[0]" ],
          [ 'module', 'YAML', [],
            "my \@tmp = YAML::LoadFile('$file'); " .
            "\$OUTPUT = \$tmp[0]" ],
          [ 'module', 'YAML::Syck', [],
            "my \@tmp = YAML::Syck::LoadFile('$file'); " .
            "\$OUTPUT = \$tmp[0]" ],
          [ 'module', 'YAML::XS', [],
            "my \@tmp = YAML::XS::LoadFile('$file'); " .
            "\$OUTPUT = \$tmp[0]" ],
          [ 'module', 'YAML::Tiny', [],
            "my \@tmp = YAML::Tiny::LoadFile('$file'); " .
            "\$OUTPUT = \$tmp[0]" ],
        );
   }

   if (! $succ) {
      $self->_log_message('WARN',"Unable to read META file: $tmp[0]");
      return;
   }
   if (! $OUTPUT) {
      $self->_log_message('ERR',"META file empty or corrupt: $tmp[0]");
      return;
   }

   # Now get the meta information:

   foreach my $f (qw(name version keywords abstract description author provides)) {
      $self->_get_meta_field($f,"m_$f");
   }

   # License information is stored in multiple places:
   #   license     => VALUE
   #   license     => [ VALUE, VALUE, ... ]
   #   resources   => license => [ VALUE, VALUE, ... ]
   #   license_uri => VALUE

   if (! $package{'m_license'}) {

      my $lic = '';

      if ($OUTPUT->{'license'}) {
         my @lic;

         if (ref($OUTPUT->{'license'})) {
            @lic = @{ $OUTPUT->{'license'} };
         } else {
            @lic = ($OUTPUT->{'license'});
         }

         foreach my $l (@lic) {
            if ($l =~ /^perl$/i  ||
                $l =~ /^perl_5$/i) {
                $l="GPL+ or Artistic";
             } elsif ($l =~ /^apache$/i) {
                $l="Apache Software License";
             } elsif ($l =~ /^artistic$/i) {
                $l="Artistic";
             } elsif ($l =~ /^artistic_?2$/i) {
                $l="Artistic 2.0";
             } elsif ($l =~ /^bsd$/i) {
                $l="BSD";
             } elsif ($l =~ /^gpl$/i) {
                $l="GPL+";
             } elsif ($l =~ /^lgpl$/i) {
                $l="LGPLv2+";
             } elsif ($l =~ /^mit$/i) {
                $l="MIT";
             } elsif ($l =~ /^mozilla$/i) {
                $l="MPL";
             } elsif ($l =~ /^open_source$/i) {
                $l="OSI-Approved";                  # rpmlint will complain
             } elsif ($l =~ /^unrestricted$/i) {
                $l="Distributable";
             } elsif ($l =~ /^restrictive$/i) {
                $l="Non-distributable";
                $self->_log_message
                  ('WARN',
                   'License is "restrictive".',
                   'This package should not be redistributed.');
             } else {
                $l="Unknown license: $l";
                $self->_log_message
                  ('WARN',
                   "Unknown license: $l",
                   'Check to make sure this package is distributable.');
             }
         }

         $lic = join(', ',@lic);

      } elsif ($OUTPUT->{'resources'}  &&
               $OUTPUT->{'resources'}->{'license'}) {
         $lic = join(' ',@{ $OUTPUT->{'resources'}->{'license'} });

      } elsif ($OUTPUT->{'license_uri'}) {
         $lic = $OUTPUT->{'license_uri'};
      }


      $package{'m_license'} = $lic  if ($lic);
   }

   # Requires can come from an old-style META.yml file:
   #   requires           => FEATURE => VERSION
   #   build_requires     => FEATURE => VERSION
   #   configure_requires => FEATURE => VERSION
   # or a new style META.json file:
   #   prereqs =>
   #      LEVEL =>                 LEVEL = configure, build, test, runtime
   #         KEY =>                KEY   = requires, recommends
   #            FEATURE => VERSION
   #
   # If we find prereqs in multiple files, we'll merge them
   # (but we'll use the VERSION from the first file they're
   # found in so we'll assume that we're examining the most
   # accurate file first).

   my %requires;
   if ($OUTPUT->{'prereqs'}) {
      my %lev = ( 'configure'  => [ 'build' ],
                  'build'      => [ 'build' ],
                  'test'       => [ 'test' ],
                  'runtime'    => [ 'build', 'runtime' ],
                );

      foreach my $lev (keys %lev) {
         foreach my $t (@{ $lev{$lev} }) {
            my @key = ('requires');
            push(@key,'recommends')
              if ( ($t eq 'build'    &&  $$self{'build_rec'})  ||
                   ($t eq 'test'     &&  $$self{'test_rec'})   ||
                   ($t eq 'runtime'  &&  $$self{'runtime_rec'}) );

            foreach my $key (@key) {

               if ($OUTPUT->{'prereqs'}->{$lev}  &&
                   $OUTPUT->{'prereqs'}->{$lev}->{$key}) {

                  foreach my $f (keys %{ $OUTPUT->{'prereqs'}->{$lev}->{$key} }) {
                     my $v = $OUTPUT->{'prereqs'}->{$lev}->{$key}->{$f};
                     $requires{$t}{$f} = $v;
                  }
               }
            }
         }
      }

   } else {

      # Requires

      my %lev = ( 'configure_requires'  => [ 'build' ],
                  'build_rquires'       => [ 'build' ],
                  'requires'            => [ 'build', 'runtime' ],
                );

      foreach my $lev (keys %lev) {
         if ($OUTPUT->{$lev}) {
            foreach my $f (keys %{ $OUTPUT->{$lev} }) {
               my $v = $OUTPUT->{$lev}->{$f};
               foreach my $t (@{ $lev{$lev} }) {
                  $requires{$t}{$f} = $v;
               }
            }
         }
      }

      # Recommends

      %lev = ( 'recommends'          => [ 'build', 'runtime' ],
             );

      foreach my $lev (keys %lev) {
         if ($OUTPUT->{$lev}) {
            foreach my $f (keys %{ $OUTPUT->{$lev} }) {
               my $v = $OUTPUT->{$lev}->{$f};
               foreach my $t (@{ $lev{$lev} }) {

                  if ( ($t eq 'build'    &&  $$self{'build_rec'})  ||
                       ($t eq 'test'     &&  $$self{'test_rec'})   ||
                       ($t eq 'runtime'  &&  $$self{'runtime_rec'}) ) {
                     $requires{$t}{$f} = $v;
                  }
               }
            }
         }
      }

   }

   if (%requires) {
      foreach my $t (keys %requires) {
         foreach my $f (keys %{ $requires{$t} }) {
            my $v = $requires{$t}{$f};

            $package{'requires'}{$t}{$f} = $v  if (! $package{'requires'}{$t}{$f});
         }
      }

   } else {
      $package{'requires'} = \%requires;
   }
}

sub _get_meta_field {
   my($self,$meta_field,$pack_field) = @_;

   return  if ($package{$pack_field}  ||
               ! exists $OUTPUT->{$meta_field});
   $package{$pack_field} = $OUTPUT->{$meta_field};

   # Strings containing newlines in the META.* files cause problems,
   # so change them to spaces.
   $package{$pack_field} =~ tr{\n}{ }  if (! ref($OUTPUT->{$meta_field}));
}

# This will get the NAME, SUMMARY, and DESCRIPTION sections of a POD
# file.  It will return () if it is not a valid POD file.
#
# This will use the following perl modules:
#   Pod::Parser
#   Pod::Simple::TextContent
#
sub _get_meta_pod {
   my($self,$file) = @_;
   my($name,$summary,$description);

   POD:
   while (1) {

      #
      # Try Pod::Parser
      #

      $self->_log_message('INFO',"Analyzing pod file with Pod::Parser: $file");
      my $err = $self->_load_module("Pod::Select");
      if (! $err) {

         # NAME - SUMMARY

         Pod::Select::podselect( { -output     => "$TMPDIR/pod_select",
                                   -selections => ["NAME"]
                                 }, "$package{DIR}/$file");

         my $fh = new IO::File;
         $fh->open("$TMPDIR/pod_select");
         my @in = <$fh>;
         $fh->close();
         chomp(@in);

         if (@in) {
            shift(@in);
            while (@in  &&  ! $in[0]) {
               shift(@in);
            }
            if (@in  &&  $in[0] =~ /^(\S+)\s+\-\s+(.*)$/) {
               ($name,$summary) = ($1,$2);
            }
         }

         # DESCRIPTION
         Pod::Select::podselect( { -output     => "$TMPDIR/pod_select",
                                   -selections => ["DESCRIPTION"]
                                 }, "$package{DIR}/$file");

         $fh->open("$TMPDIR/pod_select");
         @in = <$fh>;
         chomp(@in);
         $fh->close();

         # Although not great, we're going to keep only the first paragraph.
         # The description stuff gets too long otherwise.
         if (@in) {
            shift(@in);
            while (@in  &&  ! $in[0]) {
               shift(@in);
            }
            my(@tmp);
            while (@in  &&  $in[0]) {
               push(@tmp,shift(@in));
            }
            $description = join("\n",@tmp);
         }

         last POD;
      }

      #
      # Try Pod::Simple::TextContent
      #

      $self->_log_message
        ('INFO',"Analyzing pod file with Pod::Simple::TextContent: $file");
      $err = $self->_load_module("Pod::Simple::TextContent");
      if (! $err) {

         my $output;
         my $parser = Pod::Simple::TextContent->new();
         $parser->no_whining(1);
         $parser->output_string(\$output);

         my $fh = new IO::File;
         $fh->open("$package{DIR}/$file");
         $parser->parse_file($fh);

         my @in = split(/\n/,$output);

         while (@in  &&  $in[0] !~ /^(NAME|DESCRIPTION)$/) {
            shift(@in);
         }

         if (@in  &&  $in[0] =~ /NAME/) {
            shift(@in);
            while (@in  &&  ! $in[0]) {
               shift(@in);
            }
            if (@in  &&  $in[0] =~ /^(\S+)\s+\-\s+(.*)$/) {
               ($name,$summary) = ($1,$2);
            }
         }

         while (@in  &&  $in[0] !~ /^(DESCRIPTION)$/) {
            shift(@in);
         }

         # Although not great, we're going to keep only the first paragraph.
         # The description stuff gets too long otherwise.
         if (@in) {
            shift(@in);
            while (@in  &&  ! $in[0]) {
               shift(@in);
            }
            my(@tmp);
            while (@in  &&  $in[0]) {
               push(@tmp,shift(@in));
            }
            $description = join("\n",@tmp);
         }

         last POD;
      }

      $self->_log_message('WARN',"Analyzing pod file failed: $file");
      last POD;
   }

   # Do a simple format into 75-character lines.

   $description = ''  if (! $description);
   my $max = 75;
   my @tmp = split(/\n/,$description);
   my $tmp = join(' ',@tmp);
   $tmp    =~ s/\s+/ /g;
   @tmp    = ();
   while ($tmp) {
      if (length($tmp) <= $max) {
         push(@tmp,$tmp);
         last;
      }

      my $i = rindex($tmp,' ',$max);
      if ($i == -1) {
         $i = index($tmp,' ');
         if ($i == -1) {
            push(@tmp,$tmp);
            $tmp = '';
         } else {
            push(@tmp,substr($tmp,0,$i,''));
            substr($tmp,0,1,'');
         }
      } else {
         push(@tmp,substr($tmp,0,$i,''));
         substr($tmp,0,1,'');
      }
   }
   $description = join("\n",@tmp);

   return ($name,$summary,$description);
}

############################################################################
############################################################################

# Figure out what this package provides.
#
# If one of the META files has an 'provides' section, we'll use it.
# Otherwise, we have to look at all of the .pm files to see what
# packages are provided.
#
sub _provides {
   my($self) = @_;

   PROVIDES_METHOD:
   {
      if (exists $package{'m_provides'}) {

         #
         # If the META file defines the provides, it'll be of the form:
         #    FEATURE => { version => VERS,
         #                 file    => FILE,      lib/Foo/Bar.pm
         #               }
         #
         # We'll use this list.
         #

         foreach my $mod (keys %{ $package{'m_provides'}}) {
            my $m = "perl($mod)";
            my $v = $package{'m_provides'}{'version'}  ||  $package{'version'};
            $v    =~ s/^v//;
            $package{'provides'}{$m} = $v;
         }
         last PROVIDES_METHOD;
      }

      #
      # I'd like to rely on the standard RPM tools for getting the
      # list of provides and dependencies.  Unfortunately, I've found
      # in at least one case (openSuSE 12.1) that the tools are broken.
      # Since that is actually one of the platforms that I want to
      # build RPMs for, we're going to have to do two things:
      #   1) first, we'll try the RPM tools, but if they don't work,
      #      we'll read the files manually
      #   2) we'll explicitly put in the provides and requires into the
      #      SPEC file, even though this is officially discouraged
      #
      # If the standard tools don't work, use the included cpantorpm-depreq
      # script.
      #
      # perldeps is the last resort since it doesn't give versions.
      #

      my $cd     = "cd $package{DIR}/blib";
      my @files  = sort keys %{ $package{'instfiles'}{'pm'} };
      my @prov;

      if (@files) {
         my $bin    = $self->_find_exe('rpmdeps','/usr/lib/rpm');
         @prov      = `$cd; $bin --provides @files`  if ($bin);

         $bin       = $self->_find_exe('find-provides','/usr/lib/rpm');
         @prov      = `$cd; echo @files | $bin`      if (! @prov  &&  $bin);

         $bin       = $self->_find_exe('find-provides.perl','/usr/lib/rpm');
         @prov      = `$cd; echo @files | $bin`      if (! @prov  &&  $bin);

         $bin       = $self->_find_exe('perl.prov','/usr/lib/rpm');
         @prov      = `$cd; $bin @files`             if (! @prov  &&  $bin);

         $bin       = $self->_find_exe('cpantorpm-depreq',$DIR);
         @prov      = `$cd; $bin -p @files`          if (! @prov  &&  $bin);

         $bin       = $self->_find_exe('perldeps.pl','/usr/lib/rpm');
         @prov      = `$cd; $bin --provides @files`  if (! @prov  &&  $bin);
      }

      if (@prov) {
         chomp(@prov);
         foreach my $prov (@prov) {
            if ($prov =~ /^\s*(.*?)\s*=\s*(.*?)\s*$/) {
               my($mod,$ver) = ($1,$2);
               $package{'provides'}{$mod} = $ver;
            } else {
               $prov =~ s/\s*$//;
               $prov =~ s/^\s*//;
               $package{'provides'}{$prov} = $package{'version'};
            }
         }
      }
   }

   #
   # If we're removing provides.
   #

   foreach my $feat (@{ $$self{'rem_provide'} }) {
      delete $package{'provides'}{$feat};
   }

   #
   # Handle any added provides.
   #

   foreach my $feat (@{ $$self{'add_provide'} }) {
      my($mod,$ver);
      if ($feat =~ /^(.+)=(.+)$/) {
         ($mod,$ver) = ($1,$2);
      } else {
         ($mod,$ver) = ($feat,$package{'version'});
      }

      $package{'provides'}{$mod} = $ver;
   }
}

# This formats the figures out what the package requires to build, test, or
# run.
#
# $type is 'files' or 'instfiles' and tells which list of files to
# examine for requirements.
#
sub _requires {
   my($self,$type) = @_;

   if (! $package{'requires'}) {

      #
      # No META file was available to provide information on requirements,
      # so we're going to do it by hand.
      #
      # See the note in the provides subroutine above.  We won't depend
      # on the standards rpm tools... but we'll use them if they work.
      #

      # Since test files are not installed, we'll always use the 'files' type
      $self->__requires(['test'],   keys %{ $package{'files'}{'t'} });
      $self->__requires(['build'],  keys %{ $package{'files'}{'build'} });

      my $prefix = ($type eq 'instfiles' ? "./blib" : ".");
      $self->__requires(['build','runtime'], map { "$prefix/$_" }
                        (keys %{ $package{$type}{'pm'} },
                         keys %{ $package{$type}{'script'} }));
   }

   #
   # Now format the requirements for use in the SPEC file.
   #

   if ($package{'requires'}) {

      foreach my $type (keys %{ $package{'requires'} }) {
         foreach my $feature (keys %{ $package{'requires'}{$type} }) {
            my $v = $package{'requires'}{$type}{$feature};

            if ($feature ne 'perl') {
               $feature = "perl($feature)";
            }

            $package{"${type}_req"}{$feature} = $v;
         }
      }
   }

   #
   # If we're removing requirements.
   #

   foreach my $feat (@{ $$self{'rem_require'} }) {
      foreach my $lev (qw(build runtime test)) {
         delete $package{"${lev}_req"}{$feat};
      }
   }

   #
   # Handle any added requirements.
   #

   foreach my $feat (@{ $$self{'add_require'} }) {
      my($mod,$ver);
      if ($feat =~ /^(.+)>?=(.+)$/) {
         ($mod,$ver) = ($1,$2);
      } else {
         ($mod,$ver) = ($feat,0);
      }

      foreach my $lev (qw(build runtime)) {
         $package{"${lev}_req"}{$mod} = $ver;
      }
   }
}

# This reads @files and figures out what their requirements are.  It sets
# this information for each level in the @$level.
#
sub __requires {
   my($self,$level,@files) = @_;
   return  if (! @files);

   my %tmp = map { $_,1 } @files;
   @files  = sort(keys %tmp);

   my @req;

   my $bin    = $self->_find_exe('rpmdeps','/usr/lib/rpm');
   @req       = `$bin --requires @files`                    if ($bin);

   $bin       = $self->_find_exe('find-requires','/usr/lib/rpm');
   @req       = `echo @files | $bin`                        if (! @req  &&  $bin);

   $bin       = $self->_find_exe('find-requires.perl','/usr/lib/rpm');
   @req       = `echo @files | $bin`                        if (! @req  &&  $bin);

   $bin       = $self->_find_exe('cpantorpm-depreq',$DIR);
   @req       = `$bin -r @files`                            if (! @req  &&  $bin);

   $bin       = $self->_find_exe('perldeps.pl','/usr/lib/rpm');
   @req       = `$bin --requires @files`                    if (! @req  &&  $bin);

   if (@req) {
      chomp(@req);
      foreach my $req (@req) {

         # Should return a list of:
         #    perl               [ OP VERSION ]
         #    perl(Class::Mod)   [ OP VERSION ]

         next  if ($req !~ /^perl/);

         if ($req =~ /^\s*(.*?)\s*>=\s*(.*?)\s*$/) {
            my($mod,$ver) = ($1,$2);

            if ($mod ne 'perl') {
               if ($mod =~ /^perl\((.*)\)$/) {
                  $mod = $1;
               } else {
                  $self->_log_message
                    ('ERR',"Dependency malformed: $mod");
               }
            }

            # For some reason, rpmdeps sometimes gives a version number
            # for perl as #:xxx.  Fix this

            $ver =~ s/^\d+://  if ($mod eq 'perl');

            foreach my $lev (@$level) {
               $package{'requires'}{$lev}{$mod} = $ver;
            }
         } else {
            $req =~ s/\s*$//;
            $req =~ s/^\s*//;

            if ($req =~ /^perl\((.*)\)$/) {
               $req = $1;
            } else {
               $self->_log_message
                 ('ERR',"Dependency malformed: $req");
            }

            foreach my $lev (@$level) {
               $package{'requires'}{$lev}{$req} = 0;
            }
         }
      }
   }
}

############################################################################
############################################################################

# This is the most complicated step of the process.  We actually need to
# build the package for the following reasons:
#   o  To make sure that we CAN build it non-interactively
#   o  To determine what the module provides for this architecture
#   o  To determine what the module requires for this architecture
#
# With Build.PL, it is especially complicated because we want to be able
# to override the install directories, but to do so, we want to use 'installdirs'
# from the Build.PL script.  In order to not parse the file, we'll actually
# do a 'perl Build.PL' without directory arguments.  This will create a
# _build/build_params file which contains the information.

sub _build {
   my($self) = @_;

   $self->_log_message('HEAD',"Building package: $package{dir}");
   my $type = $package{'build_type'};

   #
   # Get the config command (perl Makefile.PL), the build command
   # (make), and the install command (make install).
   #
   # First, we'll get the commands ignoring an alternate directory.
   # We'll do this so we can figure out what installation type (if any)
   # is hardcoded into the module.
   #
   # We'll run the configure and build commands to make sure
   # everything works, and to verify where the module wants to be
   # installed by default.
   #

   $self->_log_message('INFO',"Generating commands to build the module");

   $self->_commands('',0);

   my $status = $self->_run_command("$TMPDIR/config",
                                    @{ $package{'config_cmd_l'} });
   if ($status eq 'WAITING') {
      my @err = `cat "$TMPDIR/config.out"`;
      chomp(@err);
      $self->_log_message('ERR',
                          'Config command failed waiting on input.',
                          'Output is as follows:',
                          '#'x70,
                          @err);
   } elsif ($status eq 'ERROR') {
      my @err = `cat "$TMPDIR/config.err"`;
      chomp(@err);
      $self->_log_message('ERR',
                          'Config command failed with an exit code.',
                          'Output is as follows:',
                          '#'x70,
                          @err);
   }

   $status = $self->_run_command("$TMPDIR/config",
                                 @{ $package{'build_cmd_l'} });
   if ($status eq 'WAITING') {
      my @err = `cat "$TMPDIR/config.out"`;
      chomp(@err);
      $self->_log_message('ERR',
                          'Build command failed waiting on input.',
                          'Output is as follows:',
                          '#'x70,
                          @err);
   } elsif ($status eq 'ERROR') {
      my @err = `cat "$TMPDIR/config.err"`;
      chomp(@err);
      $self->_log_message('ERR',
                          'Build command failed with an exit code.',
                          'Output is as follows:',
                          '#'x70,
                          @err);
   }

   #
   # If we didn't pass get an installation type, we need to figure out
   # what it is now.  This is because Build.PL uses the same variables
   # to set the locations of all types of builds, so we need to know
   # what installation type so we can set them appropriately in the
   # final config command.
   #
   # This is only technically necessary if we're installing in an
   # alternate directory, but it doesn't hurt even if we're not.
   #

   $package{'build_tiny'} = 0;
   if (! $$self{'inst_type'}) {
      if ($type eq 'build') {

         if (-f "_build_params") {
            # Module::Build::Tiny
            #    _build_params includes: "installdirs=core"

            $self->_log_message('INFO','Using Module::Build::Tiny');
            $package{'build_tiny'} = 1;
            my @tmp = `cat _build_params | grep "installdirs"`;
            chomp(@tmp);
            if (@tmp) {
               if (@tmp != 1) {
                  $self->_log_message
                    ('ERR',
                     'perl Build.PL did not produce a _build_params',
                     'file of the expected format.');
               }
               $tmp[0] =~ /"installdirs=(.*?)"/;
               $$self{'inst_type'} = $1;
            } else {
               $$self{'inst_type'} = 'site';
            }

         } elsif (-f "_build/build_params") {

            # Module::Build
            #    _build/build_params contains:
            #       'installdirs' => 'core',

            $self->_log_message('INFO','Using Module::Build');
            my @tmp = `cat _build/build_params | grep "'installdirs' =>"`;
            chomp(@tmp);
            if (@tmp != 1) {
               $self->_log_message
                 ('ERR',
                  'perl Build.PL did not produce a _build/build_params',
                  'file of the expected format.');
            }
            $tmp[0] =~ /=> '(.*?)'/;
            $$self{'inst_type'} = $1;

         } else {
            $self->_log_message
              ('ERR',
               'perl Build.PL did not produce a build_params file',
               'using any known Build.PL method');
         }

         $$self{'inst_type'} = 'perl'  if ($$self{'inst_type'} eq 'core');

      } else {
         # Makefile contains:
         #    INSTALLDIRS = perl

         my @file = `cat Makefile`;
         chomp(@file);

         my @tmp = grep /^INSTALLDIRS =/,@file;
         if (@tmp != 1) {
            $self->_log_message
              ('ERR',
               'perl Makefile.PL did not produce a Makefile file of',
               'the expected format.');
         }
         $tmp[0] =~ /= (.*)$/;
         $$self{'inst_type'} = $1;
      }
   }

   $self->_log_message('INFO',"Determined installation type: $$self{inst_type}");
   $self->_log_message('INFO',
                       "Generating commands to build the module to that location");

   $self->_commands($$self{'inst_base'},1);

   #
   # Now, update the file list based on the files that will actually
   # be installed.  Get the modules and scripts.
   #

   my %files = $self->_get_filelist("$package{DIR}/blib");
   $self->_categorize_files('build',"$package{DIR}/blib",%files);
}

# This figures out the config, build, and install commands. It takes
# the type (build, make), $insttype (perl/core, site, vendor), an
# alternate install directory ($dir), and $for_spec.
#
# If $for_spec is 1, the config commands will be suitable for the
# putting in the SPEC file.  Otherwise, they will be suitable for
# running to make sure it can build.
#
sub _commands {
   my($self,$dir,$for_spec) = @_;

   my $type = $package{'build_type'};
   my $insttype = $$self{'inst_type'};

   my(@config_cmd,@build_cmd,@test_cmd,@install_cmd,@clean_cmd);

   #
   # Configure the module.
   #

   if ($type eq 'build') {
      if ($for_spec) {
         @config_cmd  = (qw(%{__perl} <build> optimize="<_optimize>"));
      } else {
         @config_cmd  = ('perl',$package{build});
      }
      @build_cmd      = (qw(./Build));
      @test_cmd       = (qw(./Build test));
      if ($package{'build_tiny'}) {
         @install_cmd = (qw(./Build install --destdir=<_buildroot>
                            --create_packlist=0));
         @clean_cmd   = (qw(./Build realclean));
      } else {
         @install_cmd = (qw(./Build pure_install destdir=<_buildroot>
                            create_packlist=0));
         @clean_cmd   = (qw(./Build distclean));
      }
   } else {
      if ($for_spec) {
         @config_cmd  = (qw(%{__perl} <make> OPTIMIZE="<_optimize>"));
         @build_cmd   = (qw(make %{?_smp_mflags}));
      } else {
         @config_cmd  = ('perl',$package{make});
         @build_cmd   = ('make');
      }
      @test_cmd       = (qw(make test));
      @install_cmd    = (qw(make pure_install PERL_INSTALL_ROOT=<_buildroot>));
      @clean_cmd      = (qw(make distclean));
   }

   # Handle directory arguments
   #
   # We have to record which directories things can get installed into.

   my $t = $insttype;
   my $T = uc($t);

   DIR_ARGS:
   {
      # If we don't specify an installation directory or type,
      # we don't have to add any arguments.
      #
      # Note: this will never be the information that goes in the SPEC
      # file because the installation type will always be determined,
      # so we don't have to record installation directories here.

      if (! $dir  &&  ! $insttype) {
         last DIR_ARGS;
      }

      # If we know the installation type, but we're not using
      # a special directory, it's a simple case.

      if (! $dir  &&  $insttype) {

         if      ($insttype eq 'perl') {
            $package{'lib_dir'}  = '%{perl_privlib}';
            $package{'arch_dir'} = '%{perl_archlib}';
         } elsif ($insttype eq 'site') {
            $package{'lib_dir'}  = '%{perl_sitelib}';
            $package{'arch_dir'} = '%{perl_sitearch}';
         } else {
            $package{'lib_dir'}  = '%{perl_vendorlib}';
            $package{'arch_dir'} = '%{perl_vendorarch}';
         }
         $package{'bin_dir'}  = '%{_bindir}';
         $package{'man1_dir'} = '%{_mandir}/man1';
         $package{'man3_dir'} = '%{_mandir}/man3';

         if ($type eq 'build') {

            if ($t eq 'perl') {
               push(@config_cmd,
                    "--installdirs core");
            } else {
               push(@config_cmd,
                    "--installdirs $t");
            }

            push(@config_cmd,
                 "--install_path script=%{_bindir}",
                 "--install_path bin=%{_bindir}",
                 "--install_path libdoc=%{_mandir}/man3",
                 "--install_path bindoc=%{_mandir}/man1",
                );

         } else {

            if ($t eq 'perl') {
               push(@config_cmd,
                    "INSTALLDIRS=perl",
                    "INSTALLBIN=%{_bindir}",
                    "INSTALLSCRIPT=%{_bindir}",
                    "INSTALLMAN1DIR=%{_mandir}/man1",
                    "INSTALLMAN3DIR=%{_mandir}/man3",
                   );
            } else {
               push(@config_cmd,
                    "INSTALLDIRS=$t",
                    "INSTALL${T}BIN=%{_bindir}",
                    "INSTALL${T}SCRIPT=%{_bindir}",
                    "INSTALL${T}MAN1DIR=%{_mandir}/man1",
                    "INSTALL${T}MAN3DIR=%{_mandir}/man3",
                    "INSTALLSCRIPT=%{_bindir}",       # necessary due to a bug
                   );
            }
         }

         last DIR_ARGS;
      }

      # If we're installing in an alternate location, we have made
      # sure to always pass in $insttype.

      if ($dir) {
         my $d = $dir;

         if ($type eq 'build') {
            if ($t eq 'perl') {
               push(@config_cmd,
                    "--installdirs core",
                    "--install_path arch=$d/lib/perl5/$VERS/$ARCH",
                    "--install_path lib=$d/lib/perl5/$VERS",
                    "--install_path script=$d/bin",
                    "--install_path bin=$d/bin",
                    "--install_path libdoc=$d/$MAN/man3",
                    "--install_path bindoc=$d/$MAN/man1",
                   );

            } else {
               push(@config_cmd,
                    "--installdirs $t",
                    "--install_path arch=$d/lib/perl5/${t}_perl/$VERS/$ARCH",
                    "--install_path lib=$d/lib/perl5/${t}_perl/$VERS",
                    "--install_path script=$d/bin",
                    "--install_path bin=$d/bin",
                    "--install_path libdoc=$d/$MAN/man3",
                    "--install_path bindoc=$d/$MAN/man1",
                   );
            }

         } else {
            if ($t eq 'perl') {
               push(@config_cmd,
                    "INSTALLDIRS=perl",
                    "PERLPREFIX=$d",
                    "INSTALLARCHLIB=$d/lib/perl5/$VERS/$ARCH",
                    "INSTALLPRIVLIB=$d/lib/perl5/$VERS",
                    "INSTALLBIN=$d/bin",
                    "INSTALLSCRIPT=$d/bin",
                    "INSTALLMAN1DIR=$d/$MAN/man1",
                    "INSTALLMAN3DIR=$d/$MAN/man3",
                   );
            } else {
               push(@config_cmd,
                    "INSTALLDIRS=$t",
                    "${T}PREFIX=$d",
                    "INSTALL${T}ARCH=$d/lib/perl5/${t}_perl/$VERS/$ARCH",
                    "INSTALL${T}LIB=$d/lib/perl5/${t}_perl/$VERS",
                    "INSTALL${T}BIN=$d/bin",
                    "INSTALL${T}SCRIPT=$d/bin",
                    "INSTALL${T}MAN1DIR=$d/$MAN/man1",
                    "INSTALL${T}MAN3DIR=$d/$MAN/man3",
                    "INSTALLSCRIPT=$d/bin",            # necessary due to a bug
                   );
            }
         }

         $package{'bin_dir'}  = "$d/bin";
         $package{'man1_dir'} = "$d/$MAN/man1";
         $package{'man3_dir'} = "$d/$MAN/man3";
         if      ($insttype eq 'perl') {
            $package{'lib_dir'}  = "$d/lib/perl5/$VERS";
         } else {
            $package{'lib_dir'}  = "$d/lib/perl5/${t}_perl/$VERS"
         }
         $package{'arch_dir'} = "$package{lib_dir}/$ARCH";
      }
   }

   #
   # Now handle everything else.
   #

   push(@config_cmd,@{ $$self{'config'} });
   push(@build_cmd,@{ $$self{'build'} });

   $package{'config_cmd'}  = join(' ',@config_cmd);
   $package{'build_cmd'}   = join(' ',@build_cmd);
   $package{'test_cmd'}    = join(' ',@test_cmd);
   $package{'install_cmd'} = join(' ',@install_cmd);
   $package{'clean_cmd'}   = join(' ',@clean_cmd);

   $package{'config_cmd_l'}  = [@config_cmd];
   $package{'build_cmd_l'}   = [@build_cmd];
   $package{'test_cmd_l'}    = [@test_cmd];
   $package{'install_cmd_l'} = [@install_cmd];
   $package{'clean_cmd_l'}   = [@clean_cmd];
}

# Some Makefile.PL and Build.PL scripts are interactive!  That really sucks.
# We have to run the commands and check on them, and if they ever enter a
# 'waiting for input' state, we'll kill them and report that this module
# can't be made.
#

sub _run_command {
   my($self,$output_file,@cmd) = @_;

   my $pid = fork();

   if (! $pid) {
      # We'll run the command in a child process.
      open(STDOUT, ">$output_file.out");
      open(STDERR, ">$output_file.err");

      exec(@cmd);
   }

   my $status;
   local $SIG{CHLD} = sub { $status = 'DONE'; };

   while (1) {
      $status = $self->_strace($pid);
      last  if ($status eq 'DONE'  ||
                $status eq 'WAITING');
   }

   if (-f "$output_file.exit") {
      $status = 'ERROR';
   }

   return $status;
}


sub _strace {
   my($self,$pid) = @_;

   my $strace;
   if ($^O eq 'aix') {
      $strace = $self->_find_exe('truss');
   } else {
      $strace = $self->_find_exe('strace');
   }
   if (! $strace) {
      $self->_log_message('ERR','strace executable not found');
   }

   my($strace_pid,$strace_fh);
   $strace_pid = open $strace_fh, "-|", "$strace -qp $pid 2>&1"  ||
     $self->_log_message('ERR',"Unable to run strace: $!");

   local $SIG{ALRM} = sub { kill INT => $strace_pid };
   alarm 3;
   my $trace;
   $trace  .= $_ while <$strace_fh>;
   alarm 0;
   close $strace_fh;

   if (! $trace) {
      return "RUNNING";

   } elsif ($trace =~ /^read\(.*$/) {   # check strace output
      kill TERM => $pid;
      return "WAITING";

   } elsif ($trace =~ /No such process/  ||
            $trace =~ /Operation not permitted/  ||
            $trace =~ /Cannot control process/) {
      # If the process is done or in defunct state
      return "DONE";
   }
   return "RUNNING";
}

############################################################################
############################################################################

# We'll check the dependencies to make sure we can build it.

sub _check_deps {
   my($self) = @_;

   # We'll check build dependencies (which includes all runtime tests).
   # We'll also check test dependencies IF we're going to be running
   # tests.

   my %deps = %{ $package{'requires'}{'build'} }
     if (exists $package{'requires'}  &&
         exists $package{'requires'}{'build'});

   if ($$self{'no_tests'} == 0) {
      foreach my $feat (keys %{ $package{'requires'}{'test'} }) {
         next  if (exists $deps{$feat});
         $deps{$feat} = $package{'requires'}{'test'}{$feat};
      }
   }

   # Check them.

   if (exists $deps{'perl'}) {
      my $v = $deps{'perl'};
      delete $deps{'perl'};
      if ($v) {
         my $err = $self->_load_module('',$v);
         if ($err) {
            $self->_log_message
              ('ERR',
               "Perl version $v is required to build this module.");
         }
      }
   }

   my $error = 0;
   foreach my $feat (sort keys %deps) {
      next  if ($feat !~ /^perl\((.*)\)/);
      my $mod = $1;
      my $v   = $deps{$feat};
      my $err = $self->_load_module($mod,$v);
      if ($err) {
         $error = 1;
         $self->_log_message
           ('WARN',
            "Unable to load module $feat" . ($v ? " [$v]" : ''));
      }
   }
   if ($error) {
      $self->_log_message('ERR',
                          "Unable to load required modules.  Aborting.");
   }
}

############################################################################
############################################################################

# Read meta data from the distribution (this does only the bare minimum).
# A more comprehensive look will be done after building (so a META.* file
# can be generated as appropriate).

sub _get_meta_pre_build {
   my($self) = @_;

   $self->_log_message('HEAD',
                       "Reading package metadata (pre-build): $package{dir}");

   my %files = $self->_get_filelist($package{"DIR"});
   $self->_categorize_files("pre_build",$package{"DIR"},%files);

   #
   # Figure out if we'll be using a Build.PL or Makefile.PL method.
   #

   $self->_get_meta_build_pl($files{'build.pl'})
     if (exists $files{'build.pl'});
   $self->_get_meta_makefile_pl($files{'makefile.pl'})
     if (exists $files{'makefile.pl'});

   if (! $package{'build'}  &&
       ! $package{'make'}) {
      $self->_log_message
        ('ERR',
         "Package has no Makefile.PL/Build.PL script: $package{dir}",
         "It cannot be built automatically with this sript.");
   }

   if      ($package{'build'}  &&  $package{'make'}) {
      if ($$self{'build_type'} eq 'make') {
         $package{'build_type'} = 'make';
      } else {
         $package{'build_type'} = 'build';
      }

   } elsif ($package{'build'}) {
      if ($$self{'build_type'} eq 'make') {
         $self->_log_message
           ('ERR','Makefile.PL specified with --build-type does not exist.');
      }
      $package{'build_type'} = 'build';
   } else {
      if ($$self{'build_type'} eq 'build') {
         $self->_log_message
           ('ERR','Build.PL specified with --build-type does not exist.');
      }
      $package{'build_type'} = 'make';
   }

   $self->_log_message('INFO',"Build type: $package{build_type}");

   #
   # If any META files exist, we'll get a list of requires from them now.
   # If a distribution is totally broken and does not include any, we'll
   # check again after the build.
   #

   foreach my $f (qw(meta.json mymeta.json meta.yml mymeta.yml)) {
      my $type = ($f =~ /json/ ? 'json' : 'meta');
      $self->_get_meta_meta($type,$files{$f})           if (exists $files{$f});
   }

   $self->_requires('files');
}

# Get as much information from the Build.PL file as possible.
#
sub _get_meta_build_pl {
   my($self,$filehash) = @_;
   if (exists $filehash->{'Build.PL'}) {
      $package{'build'} = 'Build.PL';
      my @tmp = keys %$filehash;
      if (@tmp != 1) {
         $self->_log_message
           ('WARN',
            "Multiple Build.PL files exist (with different cases).",
            "The one with the correct case will be used");
      }
   } else {
      my @tmp = keys %$filehash;
      if (@tmp == 1) {
         $self->_log_message
           ('WARN',
            "Build.PL exists, but is the wrong case.",
            "It will used.");
         $package{'build'} = $tmp[0];
      } else {
         $self->_log_message
           ('WARN',
            "Multiple Build.PL files exist (with different cases).",
            "None have the correct case, so they will be ignored.");
      }
   }
}

# Get as much information from the Makefile.PL file as possible.
#
sub _get_meta_makefile_pl {
   my($self,$filehash) = @_;
   if (exists $filehash->{'Makefile.PL'}) {
      $package{'make'} = 'Makefile.PL';
      my @tmp = keys %$filehash;
      if (@tmp != 1) {
         $self->_log_message
           ('WARN',
            "Multiple Makefile.PL files exist (with different cases).",
            "The one with the correct case will be used");
      }
   } else {
      my @tmp = keys %$filehash;
      if (@tmp == 1) {
         $self->_log_message
           ('WARN',
            "Makefile.PL exists, but is the wrong case.",
            "It will used.");
         $package{'make'} = $tmp[0];
      } else {
         $self->_log_message
           ('WARN',
            "Multiple Makefile.PL files exist (with different cases).",
            "None have the correct case, so they will be ignored.");
      }
   }
}

############################################################################
############################################################################

# Get the module, put it into TMPDIR and extract it.

# This gets a package and creates a directory in the temporary directory
# containing it.
#
sub _get_package {
   my($self,$package) = @_;

   $self->_log_message('HEAD',"Obtaining package: $package");

   if      ($package =~ m,^(http|ftp)://,) {
      $self->_get_package_url($package);
   } elsif (-d $package) {
      $self->_get_package_dir($package);
   } elsif (-e $package) {
      $self->_get_package_file($package);
   } else {
      $self->_get_package_cpan($package);
   }

   $self->_log_message
     ('INFO',
      "Package    : $package",
      "  Archive  : " . ($package{'archive'} ? $package{'archive'} : ''),
      "  DIR      : $package{DIR}",
      "  Dir      : $package{dir}",
      "  Dist     : $package{dist}",
      "  Vers     : $package{vers}",
      "  Ext      : " . ($package{'ext'} ? $package{'ext'} : ''),
      "  CPAN dir : " . ($package{'cpandir'} ? $package{'cpandir'} : '')
     );

   $self->_apply_patch();
   $self->_run_script();
}

# This will copy the directory unmodified into the temporary directory.
# It can use any of the following methods:
#    File::Copy::Recursive
#    system(cp -r)
#
sub _get_package_dir {
   my($self,$package) = @_;
   my($err);

   $self->_log_message('INFO',"Package type: directory");

   $package{'from'}    = 'dir';
   $package{'fromsrc'} = $package;

   # If directory ends in '.' or '..', then we'll have to do a pwd
   # to handle it.

   $package =~ m,^(.*/)?(.*)$,;
   my $dir  = $2;

   if ($dir eq '.'  ||  $dir eq '..') {
      $self->_log_message('INFO',"Diretory name not specified. Assuming '.'");
      my $succ = $self->_multiple_methods( [ sub { 1; } ],
                                           ['system','pwd',
                                            "cd '$package'; {pwd}"],
                                         );

      if (! $succ  ||  ! @OUTPUT) {
         $self->_log_message('ERR',
                             "Unable to determine package directory: $package");
      }

      $package = $OUTPUT[0];
      $package =~ m,^(.*/)?(.*)$,;
      $dir     = $2;
   }

   my ($dist,$vers);
   if ($dir =~ /^(.+)\-(.+)$/) {
      ($dist,$vers) = ($1,$2);
   } else {
      $self->_log_message('ERR','Invalid directory name: $dir');
   }
   $package{'DIR'}  = "$TMPDIR/$dir";
   $package{'dir'}  = $dir;
   $package{'dist'} = $dist;
   $package{'vers'} = $vers;

   # Copy in the directory

   $self->_log_message('INFO',"Copying diretory");
   my $succ = $self->_multiple_methods
     ( [ sub { -d "$TMPDIR/$dir" } ],
       ['module','File::Copy::Recursive',['dircopy'],
        "\$File::Copy::Recursive::CPRFComp = 1; " .
        "dircopy('$package','$TMPDIR')" ],
       ['system','cp',
        "{cp} -r '$package' '$TMPDIR'"],
     );

   if (! $succ) {
      $self->_log_message('ERR',"Unable to copy directory: $package");
   }
}

# This takes an archive file containing a package and copies it into
# the temporary directory.  It can use any of the following methods:
#    File::Copy
#    system(cp)
#
sub _get_package_file {
   my($self,$package) = @_;
   my $err;

   $self->_log_message('INFO',"Package type: archive file");

   $package{'from'}    = 'file';
   $package{'fromsrc'} = $package;

   my($valid,$dir,$dist,$vers,$archive,$ext,$filetype) =
     $self->_is_archive($package);

   if (! $valid) {
      $self->_log_message('ERR',"Package file not a valid archive: $package");
   }
   $package{'DIR'}       = "$TMPDIR/$dir";
   $package{'dir'}       = $dir;
   $package{'dist'}      = $dist;
   $package{'vers'}      = $vers;
   $package{'archive'}   = $archive;
   $package{'ext'}       = $ext;
   $package{'filetype'}  = $filetype;

   # Copy in the file

   $self->_log_message('INFO',"Copying file");

   $self->_backup_file($package,$TMPDIR,1);

   # Extract it.

   $self->_extract_archive();
}

sub _apply_patch {
   my($self) = @_;

   return  if (! $$self{'patch'}  &&  ! $$self{'patch_dir'});

   my $file;

   if ($$self{'patch'}) {
      $file = $$self{'patch'};

   } elsif (-f "$$self{patch_dir}/$package{fromsrc}.diff") {
      $file = "$$self{patch_dir}/$package{fromsrc}.diff";

   } else {
      return;
   }

   # Run the patch.

   $self->_log_message('INFO',"Applying patch: $file");

   my $patch = $self->_find_exe('patch');
   if (! $patch) {
      $self->_log_message
        ('ERR','patch executable not found when trying to apply patch');
   }
   my $cmd = "cd $package{DIR}; $patch -p0 < $file";
   $self->_log_message('INFO',"Attempting system command: $cmd");

   if (system($cmd) != 0) {
      $self->_log_message('ERR',"pre-package patch failed: $file");
   }
}

sub _run_script {
   my($self) = @_;
   return  if (! $$self{'script'}  &&  ! $$self{'script_dir'});

   my $script;

   if ($$self{'script'}) {
      $script = $$self{'script'};

   } elsif (-f "$$self{script_dir}/$package{fromsrc}.sh") {
      $script = "$$self{script_dir}/$package{fromsrc}.sh";

   } else {
      return;
   }

   # Run the script.

   $self->_log_message('INFO',"Running script: $script");

   my $cmd = "cd $package{DIR}; sh $script";
   $self->_log_message('INFO',"Attempting system command: $cmd");

   if (system($cmd) != 0) {
      $self->_log_message('ERR',"pre-package script failed: $script");
   }
}

# We'll support lots of different ways to download an archive from a URL
# including:
#    LWP::UserAgent
#    HTTP::Lite
#    system(curl)
#    system(wget)
#    system(lynx)
#    system(links)
#    system(lftp)
#
sub _get_package_url {
   my($self,$package) = @_;

   $self->_log_message('INFO',"Package type: URL");

   $package{'from'}    = 'url';
   $package{'fromsrc'} = $package;

   my($valid,$dir,$dist,$vers,$archive,$ext,$filetype) =
     $self->_is_archive($package);

   if (! $valid) {
      $self->_log_message('ERR',"Package file not a valid archive: $package");
   }
   $package{'DIR'}       = "$TMPDIR/$dir";
   $package{'dir'}       = $dir;
   $package{'dist'}      = $dist;
   $package{'vers'}      = $vers;
   $package{'archive'}   = $archive;
   $package{'ext'}       = $ext;
   $package{'filetype'}  = $filetype;

   # Download the URL

   $self->_log_message('INFO',"Downloading from URL");

   my $succ = $self->_multiple_methods
     ( [ sub { -f "$TMPDIR/$package{archive}" } ],
       ['module','LWP::UserAgent',[],
        qq{ my \$ua = LWP::UserAgent->new;
           \$ua->timeout(10);
           \$ua->env_proxy;
           \$ua->get('$package',':content_file'=>'$TMPDIR/$package{archive}'); }
       ],
       ['module','HTTP::Lite',[],
        qq{ my \$x = HTTP::Lite->new();
           \$x->request('$package');
           open OUT,"> '$TMPDIR/$package{archive}'";
           print OUT \$x->body();
           close OUT; }
       ],
       [ 'system', 'curl',
         "{curl} -s -o '$TMPDIR/$package{archive}' '$package'" ],
       [ 'system', 'wget',
         "cd '$TMPDIR'; {wget} -q '$package'" ],
       [ 'system', 'lynx',
         "{lynx} -dump '$package' > '$TMPDIR/$package{archive}'" ],
       [ 'system', 'links',
         "{links} -source '$package' > '$TMPDIR/$package{archive}'" ],
       [ 'system', 'lftp',
         "{lftp} -c get '$package' -o '$TMPDIR/$package{archive}'" ],
     );

   if (! $succ) {
      $self->_log_message('ERR',"Unable to dowload URL: $package");
   }

   # Extract it.

   $self->_extract_archive();
}

sub _get_package_cpan {
   my($self,$package) = @_;

   $self->_log_message('INFO',"Package type: CPAN module");

   $package{'from'}    = 'CPAN';
   $package{'fromsrc'} = $package;

   CPAN:
   while (1) {

      #
      # Use CPANPLUS to get the module.
      #

      if ($$self{'cpan'} eq 'cpanplus') {

         $self->_log_message('INFO',"Using CPANPLUS");
         my $err = $self->_load_module("CPANPLUS::Backend");
         if (! $err) {
            my $cb   = CPANPLUS::Backend->new;
            my @mods = $cb->search ( type  => 'module',
                                     allow => [ qr/^$package$/ ] );

            if (@mods == 0) {
               $self->_log_message('ERR',
                                   "CPANPLUS: Module not found: $package");
            } elsif (@mods > 1) {
               $self->_log_message('ERR',
                                   "CPANPLUS: Multiple versions exist: $package");
            }

            my $mod = $mods[0];
            if (! $mod->{'package'}  ||
                ! $mod->{'path'}) {
               $self->_log_message('ERR',"CPANPLUS: Metadata incomplete: $package");
            }

            my($valid,$dir,$dist,$vers,$archive,$ext,$filetype) =
              $self->_is_archive($mod->{'package'});

            if (! $valid) {
               $self->_log_message
                 ('ERR',
                  "CPANPLUS: Metadata invalid (package): $package");
            }

            $package{'DIR'}       = "$TMPDIR/$dir";
            $package{'dir'}       = $dir;
            $package{'dist'}      = $dist;
            $package{'vers'}      = $vers;
            $package{'archive'}   = $archive;
            $package{'ext'}       = $ext;
            $package{'filetype'}  = $filetype;
            $package{'cpandir'}   = $mod->{'path'};

            my $succ = $mod->fetch( module   => $mod,
                                    fetchdir => "$TMPDIR" );

            if (! $succ  ||  ! -f "$TMPDIR/$archive") {
               $self->_log_message('ERR',
                                   "CPANPLUS: Unable to fetch module: $package");
            }

            last CPAN;
         }
      }

      #
      # Use CPAN to get the module.
      #

      $self->_log_message('INFO',"Using CPAN");
      my $err = $self->_load_module("CPAN::Shell");
      $err    = $self->_load_module("CPAN")  if (! $err);
      if (! $err) {

         my $mod = CPAN::Shell->expand('Module', $package);

         if (! $mod) {
            $self->_log_message('ERR',"CPAN: Module not found: $package");
         }

         $mod    = $mod->{'RO'}  if ($mod->{'RO'});

         if (! $mod->{'CPAN_FILE'}) {
            $self->_log_message('ERR',"CPAN: Metadata incomplete: $package");
         }

         my $cpan_file   = $mod->{'CPAN_FILE'};
         $cpan_file      =~ m,(.*)/(.*),;
         my($cpandir,$file) = ($1,$2);

         my($valid,$dir,$dist,$vers,$archive,$ext,$filetype) =
           $self->_is_archive($file);

         if (! $valid) {
            $self->_log_message('ERR',"CPAN: Metadata invalid (package): $package");
         }

         $package{'DIR'}       = "$TMPDIR/$dir";
         $package{'dir'}       = $dir;
         $package{'dist'}      = $dist;
         $package{'vers'}      = $vers;
         $package{'archive'}   = $archive;
         $package{'ext'}       = $ext;
         $package{'filetype'}  = $filetype;
         $package{'cpandir'}   = $cpandir;

         CPAN::get($cpan_file);

         if (! $CPAN::Config->{'keep_source_where'}) {
            $self->_log_message('ERR',
                                "CPAN: Unable to determine source dir: $package");
         }

         my $srcdir = $CPAN::Config->{'keep_source_where'} . "/authors/id";

         if (! -f "$srcdir/$cpandir/$archive") {
            $self->_log_message('ERR',"CPAN: Unable to fetch module: $package");
         }

         # Copy the file into the main directory.

         $self->_log_message('INFO',"Copying file");
         my $succ = $self->_multiple_methods
           ( [ sub { -f "$TMPDIR/$archive" } ],
             ['module','File::Copy',['copy'],
              "copy('$srcdir/$cpandir/$archive','$TMPDIR')" ],
             ['system','cp',
              "{cp} '$srcdir/$cpandir/$archive' '$TMPDIR'"],
           );

         if (! $succ) {
            $self->_log_message('ERR',"Unable to copy file: $package");
         }

         last CPAN;
      }

      $self->_log_message('ERR',"Unable to dowload CPAN module: $package");
   }

   # Extract the file.

   $self->_extract_archive();
}

sub _is_archive {
   my($self,$file) = @_;

   my $tmp =  $file;
   $tmp    =~ s,^.*/,,;

   if ($tmp =~ /^(.+)\-(.+)\.(tar|tar\.gz|tgz|tar\.bz2|zip)$/) {
      my ($dist,$vers,$ext) = ($1,$2,$3);
      my $dir               = "$dist-$vers";
      my $pack              = $tmp;
      my %filetype          = ('tar'      => 'tar',
                               'tar.gz'   => 'tar.gz',
                               'tgz'      => 'tar.gz',
                               'tar.bz2'  => 'tar.bz2',
                               'zip'      => 'zip');
      my $filetype          = $filetype{$ext};

      return (1,$dir,$dist,$vers,$pack,$ext,$filetype);
   }
   return (0);
}

# For tar files, it can use the following methods:
#    Archive::Extract
#    Archive::Tar
#    system(tar)
#
# For zip files, it can use the following methods:
#    Archive::Extract
#    Archive::Zip
#    unzip
#
sub _extract_archive {
   my($self) = @_;
   my($type) = $package{'filetype'};
   my $succ;

   # The expected directory that will be extracted.
   my $dir   = ($$self{'extracted'} ? $$self{'extracted'} : $package{'dir'});

   if      ($type eq 'zip') {

      $succ = $self->_multiple_methods
        ( [ sub { -d "$TMPDIR/$dir" } ],
          ['module','Archive::Extract',[],
           qq{ chdir('$TMPDIR');
              my \$arch=Archive::Extract->new(archive=>'$TMPDIR/$package{archive}');
              \$arch->extract(); }
          ],
          ['module','Archive::Zip',[],
           qq{ chdir('$TMPDIR');
              my \$zip = Archive::Zip->new('$TMPDIR/$package{archive}');
              \$zip->extractTree(); }
          ],
          ['system','unzip',
           "cd '$TMPDIR'; {unzip} -qq $package{archive}" ]
        );

   } else {

      my $comp = ($type eq 'tar' ? 0 : 1);
      my $opt  = ($type eq 'tar'    ? ''  :
                  $type eq 'tar.gz' ? 'z' :
                  'j');

      $succ = $self->_multiple_methods
        ( [ sub { -d "$TMPDIR/$dir" } ],
          ['module','Archive::Extract',[],
           qq{ chdir('$TMPDIR');
              my \$arch=Archive::Extract->new(archive=>'$TMPDIR/$package{archive}');
              \$arch->extract(); }
          ],
          ['module','Archive::Tar',[],
           qq{ chdir('$TMPDIR');
              Archive::Tar->extract_archive('$TMPDIR/$package{archive}',$comp); }
          ],
          ['system','tar',
           "cd '$TMPDIR'; {tar} xf$opt $package{archive}" ]
        );
   }

   if (! $succ) {
      $self->_log_message('ERR',"Unable to extract archive: $package{archive}");
   }

   if ($$self{'extracted'}) {
      if (! rename("$TMPDIR/$dir","$TMPDIR/$package{dir}")) {
         $self->_log_message
           ('ERR',
            "Unable to rename extracted directory: $package{archive}");
      }
   }
}

############################################################################
############################################################################

# Initialize the run.
sub _init {
   my($self) = @_;

   #
   # Make sure that the scratch directory exists, is new, and is empty.
   #

   $self->_log_message('HEAD',"Initializing cpantorpm ($VERSION)");
   $self->_log_message('INFO',"Creating modules for: $VERS [ $ARCH ]...");

   $self->_log_message('INFO',"Checking cpantorpm dir: $TMPDIR");
   $self->_log_indent(+1);

   if (-d $TMPDIR) {

      # If it already exists, remove it so we can start fresh.

      $self->_log_message('INFO','Exists.  Removing it...');

      my $func = sub { return ! -d $TMPDIR };

      my $succ = $self->_multiple_methods( [$func],
                                           ['module', 'File::Path', ['remove_tree'],
                                            "remove_tree('$TMPDIR')" ],
                                           ['system-null','rm',
                                            "{rm} -rf '$TMPDIR'"]
                                         );

      $self->_log_message
        ('ERR',
         "Unable to clean temporary directory: $TMPDIR",
         "Make sure that File::Path is installed, or the 'rm' command",
         "is in your path.  Also, check permissions on the directory.")
          if (! $succ);

   } elsif (-e $TMPDIR) {
      $self->_log_message('ERR',
                          'File exists.  Directory cannot be created.');
   } else {
      $self->_log_message('INFO','Does not exist.');
   }

   $self->_log_message('INFO','Creating it...');

   $self->_make_dir($TMPDIR);
   $package{'TMP'} = $TMPDIR;
   $self->_log_indent(-1);
}

sub _make_dir {
   my($self,$dir) = @_;

   my $func = sub { return -d $dir };

   my $succ = $self->_multiple_methods
     ( [$func],
       ['module', 'File::Path', ['make_path'],
        "make_path('$dir')" ],
       [($dir eq $TMPDIR ? 'system-null' : 'system'),
        'mkdir',
        "{mkdir} -p '$dir'"]
     );

   $self->_log_message
     ('ERR',
      "Unable to create directory: $dir",
      "Make sure that File::Path is installed, or the 'mkdir' command",
      "is in your path.  Also, make sure that permissions on the",
      "parent directory are correct.")
       if (! $succ);
}

1;

#
# The SPEC file is a stored in the __DATA__ section of this script.  It
# is unmodified except that macros are replaced as follows:
#
# <eof>         Signals the end of the file.
# <VAR>         <VAR> is replaced by $package{VAR}.  If it does not exist,
#               a warning is issued and it is replaced by an empty string.
# <quiet:VAR>   Similar to <VAR> but no warning will be issued.
# <skip:VAR>    This line is skipped if $package{VAR} does not exist.
#
# <hash:VAR>    This line is repeated for each key/value pair in the hash.
#               <hash:VAR> is replace by the key and <val> is replaced by
#               the value.
# <hash:true:VAR>
# <hash:false:VAR>
#               These are similar to <hash:VAR> except that the line is
#               only included for key/value pairs where the value evaluates
#               to true (in the first case) or false (in the second case).
# <list:VAR>    This line is repeated once for each value in a list with
#               <list:VAR> replaced by each value.
#
# <if:VAR>
# ... lines A ...
# <else:VAR>
# ... lines B ...
# <endif:VAR>   This will include the A set of lines if $package{VAR} is true
#               and the B set of lines otherwise.
#

__DATA__
#
# This SPEC file was automatically generated using the cpantorpm
# script.
#
#    Package:           <rpmname>
#    Version:           <version>
#    cpantorpm version: <VERSION>
#    Date:              <date>
#    Command:
# <command> <args>
#

Name:           <rpmname>
Version:        <version>
Release:        <release><disttag>
Epoch:          <skip:epoch>
Summary:        <summary>
License:        <license>
Group:          <group>
URL:            <url>
BuildArch:      <arch>
Source0:        <name>-%{version}.tar.gz

#
# Unfortunately, the automatic provides and requires do NOT always work (it
# was broken on the very first platform I worked on).  We'll get the list
# of provides and requires manually (using the RPM tools if they work, or
# by parsing the files otherwise) and manually specify them in this SPEC file.
#

AutoReqProv:    no
AutoReq:        no
AutoProv:       no

Provides:       <hash:true:provides> = <val>
Provides:       <hash:false:provides>
<if:incl_deps>
Requires:       <hash:true:runtime_req> >= <val>
Requires:       <hash:false:runtime_req>
BuildRequires:  <hash:true:build_req> >= <val>
BuildRequires:  <hash:false:build_req>
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
<endif:incl_deps>

%description
<desc>

%prep

rm -rf %{_builddir}/<name>-%{version}
%setup -D -n <name>-<version>
chmod -R u+w %{_builddir}/<name>-%{version}

if [ -f pm_to_blib ]; then rm -f pm_to_blib; fi

%build

<config_cmd>
<build_cmd>
<list:post_build>

<if:incl_tests>
#
# This is included here instead of in the 'check' section because
# older versions of rpmbuild (such as the one distributed with RHEL5)
# do not do 'check' by default.
#

if [ -z "$RPMBUILD_NOTESTS" ]; then
   <test_cmd>
fi
<endif:incl_tests>

%install

rm -rf <_buildroot>
<install_cmd>
find <_buildroot> -type f -name .packlist -exec rm -f {} \;
find <_buildroot> -type f -name '*.bs' -size 0 -exec rm -f {} \;
find <_buildroot> -depth -type d -exec rmdir {} 2>/dev/null \;
%{_fixperms} <_buildroot>/*

%clean

rm -rf <_buildroot>

%files

%defattr(-,root,root,-)
<if:bin_inst>
<bin_dir>/*
<endif:bin_inst>
<if:lib_inst>
<lib_dir>/*
<endif:lib_inst>
<if:arch_inst>
<arch_dir>/*
<endif:arch_inst>
<if:man1_inst>
<man1_dir>/*
<endif:man1_inst>
<if:man3_inst>
<man3_dir>/*
<endif:man3_inst>

%changelog
* <date> <packager> <version>-<release>
- Generated using cpantorpm

<eof>
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:
