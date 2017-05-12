#!/usr/bin/perl -w

BEGIN { our $NO_INIT = 1 }

use strict;
use lib "./lib", "./inc";
use My::Build;
use Config;

our( $TYPE, $URL, $FORCE_GTX );

my %VERSIONS =

  ( '2.8.12'        => 'patches/data-2.8.12',
    '2.8.11'        => 'patches/data-2.8.11',
    '2.8.10'        => 'patches/data-2.8.10',
    '2.9.0'         => 'patches/data-2.9.0',
    '2.9.1'         => 'patches/data-2.9.1',
    '2.9.2'         => 'patches/data-2.9.2',
    '2.9.3'         => 'patches/data-2.9.3',
    '2.9.4'	        => 'patches/data-2.9.4',
    '3.0.0'         => 'patches/data-3.0.0',
    '3.0.1'         => 'patches/data-3.0.1',
    '3.0.2'         => 'patches/data-3.0.2',
    );

my ($DEFAULT_VERSION, $DEFAULT_ARCHIVE_TYPE) = _get_default_wxwidgets_version_and_type();

if( $^O eq 'cygwin' ) {
    print <<EOT;
==========================================================
There is no support to build Alien::wxWidgets (and wxPerl)
on Cygwin.
==========================================================
EOT
    exit 1;
}

# new_from_context is broken: it does not restore
# @INC set in Build.PL before trying to load a base class not
# defined using ->subclass...
my $class = Module::Build->subclass
  ( class            => 'My::Build::new_from_context_is_broken',
    code             => <<'EOC' );
use lib qw(lib inc);
@ISA = qw(My::Build Module::Build);
require My::Build;
EOC
my $build = $class->new
  ( module_name     => 'Alien::wxWidgets',
    license         => 'perl',
    author          => 'Mattia Barbon <mbarbon@cpan.org>',
    requires        => { perl                             => '5.006',
                         'Module::Pluggable'              => '2.6',
                        },
    build_requires  => { 'Module::Build'                  => '0.28',
                         'ExtUtils::CBuilder'             => '0.24',
                         'File::Spec'                     => '1.50',
                         'LWP::Protocol::https'           => '0',
                         },
    configure_requires => { 'Module::Build'               => '0.28',
                            },
    get_options     => { 'wxWidgets-debug'           => { type => '!' },
                         'wxWidgets-unicode'         => { type => '!' },
                         'wxWidgets-mslu'            => { type => '!' },
                         'wxWidgets-static'          => { type => '!' },
                         'wxWidgets-monolithic'      => { type => '!' },
                         'wxWidgets-universal'       => { type => '!' },
                         'wxWidgets-build'           => { type => '!' },
                         'wxWidgets-portable'        => { type => '!',
                                                        default => $^O eq 'MSWin32' },
                         'wxWidgets-build-opengl'    => { type => '!' },
                         'wxWidgets-source'          => { type => '=s' },
                         'wxWidgets-version'         => { type => '=s' },
                         'wxWidgets-extraflags'      => { type => '=s' },
                         'wxWidgets-userpatch'       => { type => '=s' },
                         'wxWidgets-graphicscontext' => { type => '!', default => 1 },
                         },
    
    create_makefile_pl => 'passthrough',
    meta_merge =>
      { resources       =>
          { 'license'       => [ 'http://dev.perl.org/licenses/' ],
            'homepage'      => 'http://www.wxperl.it/',
            'bugtracker'    => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-wxWidgets',
            'repository'    => 'http://svn.code.sf.net/p/wxperl/code/Alien-wxWidgets',
            'MailingList'   => 'http://lists.perl.org/list/wxperl-users.html',
            },
        },
  );

my $accept_defaults = $ENV{PERL5_CPANPLUS_IS_RUNNING}
                   || $ENV{CPAN_SHELL_LEVEL}; 
my $build_wx_dflt = 'yes';
my $build_wx_opengl_dflt = 'yes';
my $build_prompt = 'Do you want to fetch and build wxWidgets from sources?';
my $have_alien_configuration = 0;

# try to detect if wxWidgets has been installed using Alien::wxWidgets and if
# it is the latest version; the rule is:
#
# if there is any any wxWidgets installation registered with Alien::wxWidgets
# it will only get upgraded if it was compiled using Alien::wxWidgets itself and
# it is older than $DEFAULT_VERSION

my $ok = eval {
    require Alien::wxWidgets;
    require File::Basename;
    require File::Spec;
    require Cwd;

    $DEFAULT_VERSION =~ m/^(\d+)\.(\d+)\.(\d+)$/ or die "Wrong default version";
    my $install_version = $1 + $2 / 1000 + $3 / 1000000;
    my @configs = Alien::wxWidgets->get_configurations;

    $build_wx_dflt = 'no' if @configs;
    $have_alien_configuration = @configs;

    foreach my $config ( @configs ) {
        last if $config->{version} >= $install_version;

        # installed version is older than $DEFAULT_VERSION, check if it
        # has been installed using Alien::wxWidgets
        my %values = $config->{package}->values;
        ( my $pm_filename = $config->{package} . '.pm' ) =~ s{::}{/}g;
        my $pm_file = $INC{$pm_filename};
        my $pm_path = File::Spec->catdir( File::Basename::dirname( $pm_file ),
                                          File::Spec->updir );
        my $prefix = File::Spec->catdir( $values{prefix}, File::Spec->updir );

        if( Cwd::realpath( $pm_path ) eq Cwd::realpath( $prefix ) ) {
            $build_wx_dflt = 'yes';
        }
    }

    1;
};
# if anything went wrong in the autodetection, revert to the correct
# default
if( !$ok ) {
    $build_wx_dflt = 'yes';
}

# detect wxWidgets using WXDIR/WXWIN environment variables on Win32
# and wx-config on other platforms
if( $^O eq 'MSWin32' && ( $ENV{WXWIN} || $ENV{WXDIR} ) ) {
    $build_wx_dflt = 'no';
    $build_prompt = sprintf <<EOP, ( $ENV{WXWIN} || $ENV{WXDIR} );
A wxWidgets build seems to be in '%s', so it should be safe to answer
'no' to the following question

$build_prompt
EOP
} else {
    require My::Build::Base;
    
    my $env_wxconfig = $ENV{WX_CONFIG};
    if ( $env_wxconfig && !-e $env_wxconfig && $env_wxconfig !~ /wx-config$/ ) {
        print STDERR qq(
=============================================================================
The specified environment WX_CONFIG does not appear to be a valid wx-config :
$env_wxconfig
==============================================================================
        );
        exit(1);
    }
    
    my $wx_config = $env_wxconfig || My::Build::Base->awx_path_search( 'wx-config' );
    if( $wx_config ) {
        my $ans = `$wx_config --version`;
        if( $ans =~ /^[23]\./ ) {
            my $prefix = `$wx_config --prefix`;
            chomp foreach $ans, $prefix;
            if( _check_installed_widgets_ok($ans, $prefix) ) {
                $build_wx_dflt = 'no' ;
                $build_prompt = sprintf <<EOP, $ans, $prefix;
wxWidgets %s seems to be installed in '%s', so it should be safe to
answer 'no' to the following question:

$build_prompt
EOP
            }
        }
    }
}
if( $^O ne 'darwin' && $^O ne 'MSWin32' ) {
    $build_wx_opengl_dflt = 'no';
}
if( $ENV{AWX_URL} ) {
    $build_wx_dflt = 'yes';
}
if( $ENV{AUTOMATED_TESTING} ) {
    if( $^O ne 'darwin' && $^O ne 'MSWin32' ) {
        my $pkg_config = $ENV{PKG_CONFIG} || 'pkg-config';
        my $ans = `$pkg_config --modversion gtk+-2.0 2>&1`;
        unless( $ans =~ /^[23]\./ ) {
            print <<EOT;
Could not detect GTK+ 2 by running '$pkg_config': aborting

== pkg-config output: ====================================
$ans==========================================================
EOT
            exit 0;
        }
    }
    if( $^O eq 'solaris' )
    {
        my $ans = `gmake -v`;
        unless( $ans =~ /gnu make/i ) {
            print <<EOT;
Could not find GNU Make as 'gmake': aborting
EOT
            exit 0;
        }
    }
}
chomp $build_prompt;
my $build_wx = _askyn( $build, 'wxWidgets-build',
                       $build_prompt, $build_wx_dflt );
my $wx_version;
$build->notes( 'build_wx' => $build_wx );
$build->notes( 'mk_portable' => $build->args('wxWidgets-portable') );
$build->notes( 'install_only' => $have_alien_configuration && !$build_wx && $accept_defaults );
$build->notes( 'extraflags' => $build->args('wxWidgets-extraflags') || '' );
$build->notes( 'userpatch' => $build->args('wxWidgets-userpatch') || '' );
$build->notes( 'graphicscontext' => $build->args('wxWidgets-graphicscontext') );

if( $build_wx ) {
    $wx_version = _askmulti( $build, 'wxWidgets-version',
                             'Which wxWidgets version?',
                             [ sort keys %VERSIONS ], $DEFAULT_VERSION );
    
    $DEFAULT_ARCHIVE_TYPE = 'tar.bz2' if $wx_version =~ /^(2\.9|3\.)/; # no tar.gz at sourceforge site
    
    $TYPE = _ask( $build, 'wxWidgets-source', 'Which archive type?', $DEFAULT_ARCHIVE_TYPE );
    $URL = $ENV{AWX_URL};
    $FORCE_GTX = $build->args('wxWidgets-graphicscontext');
    $build->notes( 'build_data' => do $VERSIONS{$wx_version} );
}

if( $build_wx && $wx_version !~ /^(2\.9|3\.)/ ) {
    my $build_wx_unicode = _askyn( $build, 'wxWidgets-unicode',
                                   'Do you want to enable Unicode support',
                                   'yes' );
    $build->notes( 'build_wx_unicode' => $build_wx_unicode );
} elsif( $build_wx ) {
    # Unicode-only for 2.9.x and higher
    $build->notes( 'build_wx_unicode' => 1 );
}
if( $build_wx ) {
    my $build_wx_opengl = _askyn( $build, 'wxWidgets-build-opengl',
                                  'Do you want to include OpenGL support',
                                  $build_wx_opengl_dflt );
    $build->notes( 'build_wx_opengl' => $build_wx_opengl );
}

$build->create_build_script;

sub _is_yes {
    return lc( $_[0] ) eq 'y' || lc( $_[0] ) eq 'yes' || $_[0] eq 1;
}

sub _askyn {
    my( $build, $arg, $question, $default ) = @_;
    my $res =
      defined $build->args( $arg ) ? _is_yes( $build->args( $arg ) ) :
      exists $ENV{"AWX_\U$arg"}    ? _is_yes( $ENV{"AWX_\U$arg"} ) :
      $accept_defaults             ? _is_yes( $default ) :
                                     $build->y_n( $question, $default );

    return $res
}

sub _askmulti {
    my( $build, $arg, $question, $options, $default ) = @_;
    $question .= " (" . join( ', ', @$options ) . ")";
    my $res =
      defined $build->args( $arg ) ? $build->args( $arg ) :
      exists $ENV{"AWX_\U$arg"}    ? $ENV{"AWX_\U$arg"} :
      $accept_defaults             ? $default :
                                     $build->prompt( $question, $default );

    die "Invalid value '$res' for option '$arg': must be one of ",
        join( ', ', map "'$_'", @$options ), "\n"
        unless grep $_ eq $res, @$options;

    return $res
}

sub _ask {
    my( $build, $arg, $question, $default ) = @_;
    my $res =
      defined $build->args( $arg ) ? $build->args( $arg ) :
      exists $ENV{"AWX_\U$arg"}    ? $ENV{"AWX_\U$arg"} :
      $accept_defaults             ? $default :
                                     $build->prompt( $question, $default );

    return $res
}

sub _get_default_wxwidgets_version_and_type {
    
    # default version and archive type
    my $defver = '3.0.2';
    my $deftype = 'tar.bz2';
    
    if( $^O =~ /^linux/i) {
        # 2.8.10 if this is gtk < 2.4
        my $pkg_config = $ENV{PKG_CONFIG} || 'pkg-config';
        if( my $gtkfullver = qx($pkg_config --modversion gtk+-2.0 2>&1) ) {
            if($gtkfullver =~ /^\d+\.(\d+)\.\d+/) {
                if ( $1 < 4 ) {
                    $defver = '2.8.10';
                    $deftype = 'tar.gz';
                }
            }
        }
    }
    
    return ($defver, $deftype);
}

sub _check_installed_widgets_ok {
    my($wxversion, $wxprefix) = @_;
    
    return 1 if $^O !~ /^darwin/i;
    
    # catch current common case of system installed
    # widgets 2.8.x on a 64 bit capable Mac + 64 bit
    # perl
    # assume installed 2.9.x is osx-cocoa 64 bit
    
    if( $Config{ptrsize} == 8
        && $wxversion =~ /^2\.8\./
       ) {
        return 0;
    } else {
        return 1;
    }
}

1;


