package My::Build::Win32;

use strict;
use base qw(My::Build::Base);
use My::Build::Utility qw(awx_arch_file awx_install_arch_file
                          awx_install_arch_dir);
use Config;
use Fatal qw(open close);
use Carp qw(cluck);
use File::Glob qw(bsd_glob);

my $initialized;

sub _init {
    return if $initialized;
    $initialized = 1;

    return if Module::Build->current->notes( 'build_wx' );
    # install_only is set when a wxWidgets build is already configured
    # with Alien::wxWidgets
    return if Module::Build->current->notes( 'install_only' );

    # check for WXDIR and WXWIN environment variables
    unless( exists $ENV{WXDIR} or exists $ENV{WXWIN} ) {
        cluck <<EOT;

**********************************************************************
WARNING!

You need to set the WXDIR or WXWIN variables; refer to
docs/install.txt for a detailed explanation
**********************************************************************

EOT
        exit 1;
    }

    $ENV{WXDIR} = $ENV{WXWIN} unless exists $ENV{WXDIR};
    $ENV{WXWIN} = $ENV{WXDIR} unless exists $ENV{WXWIN};
}

sub _patch_command {
    my( $self, $base_dir, $patch_file ) = @_;
    my $patch_exe = File::Spec->catfile( File::Spec->updir,
                                         qw(inc bin patch.exe) );

    my $cmd = qq{perl -pe "" -- "$patch_file"} .
              qq{ | "$patch_exe" -N -p0 -u -b -z .bak};

    return $cmd;
}

sub awx_grep_dlls {
    my( $self, $libdir, $digits, $mono ) = @_;
    my $ret = {};
    my $ver = $self->_version_2_dec( $self->awx_w32_bakefile_version );
    my $suff = ( $self->awx_unicode ? 'u' : '' ) .
               ( $self->awx_debug && $ver <= 2.009 ? 'd' : '' );

    my @dlls = grep { m/${digits}\d*${suff}_/ }
               bsd_glob( File::Spec->catfile( $libdir, '*.dll' ) );
    my @libs = grep { m/(?:lib)?wx(?:wince|msw|base)[\w\.]+$/ }
               grep { m/${digits}\d*${suff}(_|\.)/ }
               bsd_glob( File::Spec->catfile( $libdir, "*$Config{lib_ext}" ) );
    # we want builtins on Win32 so that they are available for wxWidgets extensions
    my @builtins = grep { m/wx(zlib|regex|expat|png|jpeg|tiff)/ }
               bsd_glob( File::Spec->catfile( $libdir, "*$Config{lib_ext}" ) );

    $self->{w32builtins} = \@builtins;
    
    foreach my $full ( @dlls, @libs ) {
        my( $name, $type );
        local $_ = File::Basename::basename( $full );
        m/^[^_]+_([^_\.]+)/ and $name = $1;
        $name = 'base' if !defined $name || $name =~ m/^(gcc|vc|evc)$/;
        $type = m/$Config{lib_ext}$/i ? 'lib' : 'dll';
        $ret->{$name}{$type} = $full;
    }

    if( $mono ) {
        $ret->{mono} = delete $ret->{base};
    }

    die "Configuration error: could not find libraries for configuration: "
        . join ' ', map "'$_'", $suff, $digits
      unless ( exists $ret->{core}{dll} and exists $ret->{core}{lib} )
          or ( exists $ret->{mono}{dll} and exists $ret->{mono}{lib} );

    return $ret;
}

sub awx_wx_config_data {
    my $self = shift;
    my $wxdir_b = $ENV{WXDIR};
    my $wxdir = $self->notes( 'build_wx' ) ?
      awx_install_arch_dir( $self, 'rEpLaCe' ) : $wxdir_b;

    return { 'wxdir'       => $wxdir,
             'wxdir_build' => $wxdir_b,
             'wxinc'       => File::Spec->catdir( $wxdir_b, 'include' ),
             'wxcontrinc'  => File::Spec->catdir( $wxdir_b, 'contrib',
                                                 'include' ),
             };
}

sub awx_configure {
    my $self = shift;
    my %config = $self->SUPER::awx_configure;

    $config{prefix} = $self->wx_config( 'wxdir' );
    $config{config}{toolkit} = $self->is_wince ? 'wce' : 'msw';
    $config{shared_library_path} = awx_install_arch_file( $self, "rEpLaCe/lib" );

    $self->awx_w32_find_setup_dir( $self->wx_config( 'cxxflags' ) );

    return %config;
}

sub awx_w32_find_setup_dir {
    my( $self, $cxxflags ) = @_;

    die "Unable to find setup.h directory"
      unless $cxxflags =~ m{[/-]I\s*(\S+lib[\\/][\w\\/]+)(?:\s|$)};
    $self->{awx_setup_dir} = $1;

    $self->{awx_data}{version} = $self->awx_w32_bakefile_version
      if -f $self->awx_w32_build_cfg;
}

sub awx_w32_bakefile_version {
    my $self = shift;
    my $build_cfg = $self->awx_w32_build_cfg;
    my $in;

    open $in, $build_cfg;
    my %ver = map { split /=/ } grep /^WXVER_/, map { s/\s//g; $_ } <$in>;
    close $in;

    return join '.', @ver{qw(WXVER_MAJOR WXVER_MINOR WXVER_RELEASE)};
}

sub awx_w32_build_cfg {
    my $self = shift;
    File::Spec->catfile( $self->{awx_setup_dir}, 'build.cfg' )
}

sub files_to_install {
    my $self = shift;
    my $dlls = $self->awx_wx_config_data->{dlls};

    my $setup_h = File::Spec->catfile( $self->{awx_setup_dir},
                                       'wx', 'setup.h' );
    my $build_cfg = $self->awx_w32_build_cfg;
    my %files;

    $files{$build_cfg} = awx_arch_file( "rEpLaCe/lib/build.cfg" )
      if -f $build_cfg;

    $files{$setup_h} = awx_arch_file( "rEpLaCe/lib/wx/setup.h" );
    foreach my $dll ( map { $_->{dll} } values %$dlls ) {
        next unless defined $dll;
        my $base = File::Basename::basename( $dll );
        $files{$dll} = awx_arch_file( "rEpLaCe/lib/$base" );
    }
    foreach my $lib ( map { $_->{lib} } values %$dlls ) {
        next unless defined $lib;
        my $base = File::Basename::basename( $lib );
        $files{$lib} = awx_arch_file( "rEpLaCe/lib/$base" );
    }
    
    if( $self->notes( 'build_wx' ) || $self->notes( 'mk_portable' )  ) {
        require File::Find;
        my $no_platform = join '|', qw(unix gtk x11 motif mac cocoa
                                       os2 palmos univ mgl msdos gtk1
                                       dfb);
        my $wx_base = $self->awx_wx_config_data->{wxdir_build};
        foreach my $find_base ( File::Spec->catdir( $wx_base, qw(include wx) ),
                             File::Spec->catdir( $wx_base, qw(contrib
                                                 include wx) ) ) {
            next unless -d $find_base;
            my $wanted = sub {
                $File::Find::prune ||=
                  -d $_ && $_ =~ m{include[/\\]wx[/\\](?:$no_platform)$};
                $File::Find::prune ||=
                  -d $_ && $_ =~ m{[/\\]\.svn$};
                return unless -f $_;
                my $rel = File::Spec->abs2rel( $_, $find_base );
                $files{$_} = awx_arch_file( "rEpLaCe/include/wx/$rel" );
                # print "$_ ==> $files{$_}\n";
            };
            File::Find::find
                ( { wanted   => $wanted,
                    no_chdir => 1,
                    },
                  $find_base
                  );
        }
    }
    
    for my $builtin ( @{ $self->awx_wx_config_data->{w32builtins} } ) {
	my $base = File::Basename::basename( $builtin );
        $files{$builtin} = awx_arch_file( "rEpLaCe/lib/$base" );
    }
    
    return %files;
}

sub copy_wxwidgets {
    my $self = shift;
    my %files = $self->files_to_install;

    while( my( $from, $to ) = each %files ) {
        $to =~ s/rEpLaCe/$self->{awx_key}/g;
        $self->copy_if_modified( from => $from, to => $to, verbose => 1 );
    }
}

sub install_wxwidgets {
    my $self = shift;

    $self->copy_wxwidgets;
}

sub awx_get_package {
    My::Build::Win32::_init();

    my $package;

    return 'WinCE' if $INC{'Cross.pm'};

    SWITCH: {
        local $_ = $Config{ccname} || $Config{cc};

        /^cl/i  and $package = 'Win32_MSVC'  and last SWITCH;
        /^gcc/i and $package = 'Win32_MinGW' and last SWITCH;

        # default
        die "Your compiler is not currently supported on Win32"
    };

    return $package . '_Bakefile';
}

# MSLU is off by default. It Must be explicitly enabled
sub awx_mslu {
    return $_[0]->args( 'wxWidgets-mslu' )
      if defined $_[0]->args( 'wxWidgets-mslu' );
    return 0;
}

sub massage_environment {
    my( $self ) = shift;

    if( $self->notes( 'build_wx' ) ) {
        $ENV{WXWIN} = $ENV{WXDIR} = File::Spec->rel2abs
          ( $self->notes( 'build_data' )->{data}{directory} );
    }
}

package My::Build::Win32_Bakefile;

use strict;
use Carp;
use Config;
# mixin: no use base

sub build_wxwidgets {
    my $self = shift;
    my $old_dir = Cwd::cwd();

    my $uni = $self->awx_unicode ? 'UNICODE=1'   : 'UNICODE=0';
    my $mslu = $self->awx_mslu   ? 'MSLU=1'      : 'MSLU=0';
    my $dbg = $self->awx_debug   ? 'BUILD=debug' : 'BUILD=release';
    my $opt = join ' ', $uni, $mslu, $dbg, 'SHARED=1';
    
    if( my $xbuildflags = $self->awx_w32_extra_buildflags ) {
		$opt .= ' ' . $xbuildflags;
	}
    
    # help windres in x compiler
    local $ENV{GNUTARGET} = ( $Config{ptrsize} == 8 )  ? 'pe-x86-64' : 'pe-i386';
    
    chdir File::Spec->catdir( $ENV{WXDIR}, 'build', 'msw' );
    $self->_system( $self->_make_command . ' ' . $opt );
    chdir File::Spec->catdir( $ENV{WXDIR}, 'contrib', 'build', 'stc' );
    $self->_system( $self->_make_command . ' ' . $opt );

    chdir $old_dir;
}

sub awx_w32_configure_extra_flags {
    my $self = shift; 
    return $self->notes( 'extraflags' );
}

sub awx_w32_extra_buildflags {
    my $self = shift;
    my $buildflags = '';
	my $extraflags = $self->awx_w32_configure_extra_flags;
	$buildflags .= $extraflags if $extraflags;
	
	return $buildflags if !$self->notes('build_wx');
	
	
	# extra flags for vers != 2.8 - that is >= 2.9
    
	if( $self->awx_version_type == 3 ) {
		if($self->awx_debug) {
			$buildflags .= ' DEBUG_INFO=default DEBUG_FLAG=2';
		} else {
			$buildflags .= ' DEBUG_INFO=default DEBUG_FLAG=1';
		}
	}

	# flags for vers == 2.x

	if( $self->awx_version_type == 2 ) {

		# do graphicscontext for 2.8 build if requested
		if( $self->notes( 'graphicscontext' ) ) {
			$buildflags .= ' USE_GDIPLUS=1';
		}

	}

	if( my $ldflags = $self->awx_w32_ldflags ) {
		# only add if user has not specified LDFLAGS in 'extraflags'
		if( $extraflags !~ / LDFLAGS=/ ) {
			$buildflags .= qq( LDFLAGS=\"$ldflags\");
		}
	}

	if( my $cppflags = $self->awx_w32_cppflags ) {
		# only add if user has not specified CPPFLAGS in 'extraflags'
		if( $extraflags !~ / CPPFLAGS=/ ) {
			$buildflags .= qq( CPPFLAGS=\"$cppflags\");
		}
	}
	
	return $buildflags;
	
}

sub is_wince { 0 }


1;
