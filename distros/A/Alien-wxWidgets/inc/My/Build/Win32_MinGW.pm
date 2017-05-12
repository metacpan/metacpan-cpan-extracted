package My::Build::Win32_MinGW;

use strict;
use base qw(My::Build::Win32);
use My::Build::Utility qw(awx_arch_file awx_install_arch_file
                          awx_install_arch_dir awx_arch_dir);
use Config;
use File::Basename qw();
use File::Glob qw(bsd_glob);
use Data::Dumper;

sub _find_make {
    my( @try ) = qw(mingw32-make gmake make);
    push @try, $Config{gmake} if $Config{gmake};

    foreach my $name ( @try ) {
        foreach my $dir ( File::Spec->path ) {
            my $abs = File::Spec->catfile( $dir, "$name.exe" );
            return $name if -x $abs;
        }
    }

    return 'make';
}

sub awx_configure {
    my $self = shift;
    my %config = $self->SUPER::awx_configure;

	my $mxarchflags = ( $Config{ptrsize} == 8 ) ? '-m64' : '-m32';

    if( $self->awx_debug ) {
        $config{c_flags} .= qq( -g $mxarchflags );
        $config{link_flags} .= qq( $mxarchflags );
    } else {
        $config{c_flags} .= qq( $mxarchflags );
        $config{link_flags} .= qq( -s $mxarchflags );
    }

    my $cccflags = $self->wx_config( 'cxxflags' );
    my $libs = $self->wx_config( 'libs' );
    my $incdir = $self->awx_wx_config_data->{wxinc};
    my $cincdir = $self->awx_wx_config_data->{wxcontrinc};
    my $iincdir = awx_install_arch_dir( $self, 'rEpLaCe/include' );

    foreach ( split /\s+/, $cccflags ) {
        m(^-DSTRICT) && next;
        m(^\.d$) && next; # broken makefile
        m(^-W.*) && next; # under Win32 -Wall gives you TONS of warnings
        m(^-I) && do {
            next if m{(?:regex|zlib|jpeg|png|tiff)$};
            if( $self->notes( 'build_wx' ) ) {
                $_ =~ s{\Q$cincdir\E}{$iincdir};
                $_ =~ s{\Q$incdir\E}{$iincdir};
            }
            if( $_ =~ /-I\Q$self->{awx_setup_dir}\E/ ) {
                $config{include_path} .=
                  '-I' . awx_install_arch_file( $self, 'rEpLaCe/lib' ) . ' ';
            } else {
                $config{include_path} .= "$_ ";
            }
            next;
        };
        m(^-D) && do { $config{defines} .= "$_ "; next; };
        $config{c_flags} .= "$_ ";
    }

    foreach ( split /\s+/, $libs ) {
        m(wx|unicows)i || next;
        next if m{(?:wx(?:zlib|regexu?|expat|png|jpeg|tiff)[ud]{0,2})$};
        $config{link_libraries} .= "$_ ";
    }

    my $dlls = $self->awx_wx_config_data->{dlls};
    $config{_libraries} = {};

    while( my( $key, $value ) = each %$dlls ) {
        $config{_libraries}{$key} =
          { map { $_ => File::Basename::basename( $value->{$_} ) }
                keys %$value };
        if( $value->{link} ) {
            $config{_libraries}{$key}{link} = $value->{link};
        } elsif( $value->{lib} ) {
            my $lib = $config{_libraries}{$key}{lib};
            $lib =~ s/^lib(.*?)(?:\.dll)?\.a$/$1/;
            $config{_libraries}{$key}{link} = '-l' . $lib;
        }
    }

    return %config;
}

sub awx_compiler_kind { 'gcc' }

sub files_to_install {
    my $self = shift;
    
    # wxWidgets dlls may be linked to
    # libgcc_* ( suffix could be may variants as some mingw dists distinguish between 32 / 64 bit dlls )
    # libstdc++*
    # mingwm10.dll
    
    my @searchfordlls;
    
    # get the dlls used
    
    {
    	# objdump will give us confirmed dll names
    	# while a fallback wildcard search may fail
    	# if multiple different named libcc files exist 
    	my $wxdlls = $self->awx_wx_config_data->{dlls};
    	
    	my $checkfile = ( exists($wxdlls->{base}) ) ? $wxdlls->{base}->{dll} : $wxdlls->{mono}->{dll};
        #$checkfile =~ s/\\+/\//g;
        #print qq(CHECKING FILE $checkfile\n);
		my @dumplines = qx(objdump -x $checkfile);
		
		for ( @dumplines ) {
			if( /^\s+DLL Name: (libgcc_|mingwm|libstdc++)(.+\.dll)\s+$/ ) {
				push @searchfordlls, $1 . $2;
			}
		}
		
	}
	
	my @try = ( @searchfordlls ) ? @searchfordlls : (qw(libgcc_*.dll mingwm10.dll));
	       
    my @gccdlls;

    foreach my $d ( @try ) {
        my $dll_from = $self->awx_path_search( $d );
        if( defined $dll_from ) {
            my $dll = File::Basename::basename( $dll_from );
            push @gccdlls, [ $dll_from, $dll  ];
     
        }
    }
    
    if(!@gccdlls) {
        # check for special case ActivePerl mingw 3.4 PPM
        my $ppmmingw = qq($Config{sitearch}/auto/MinGW/bin/mingwm10.dll);
        if( -f $ppmmingw ) {
            my $dll = File::Basename::basename( $ppmmingw );
            push @gccdlls, [ $ppmmingw, $dll  ];
        }
    }
    
    my %returnfiles = $self->SUPER::files_to_install();
    
    for( @gccdlls ) {
    	$returnfiles{$_->[0]} = awx_arch_file( "rEpLaCe/lib/$_->[1]" );
    }
    
    print qq(MinGW gcc libs - none found\n) if !@gccdlls;
    
    return %returnfiles;

}

sub awx_strip_dlls {
    my( $self ) = @_;
    my( $dir ) = grep !/Config/, bsd_glob( awx_arch_dir( '*' ) );

    $self->_system( "attrib -r $dir\\lib\\*.dll" );
    $self->_system( "strip $dir\\lib\\*.dll" );
    $self->_system( "attrib +r $dir\\lib\\*.dll" );
}


1;
