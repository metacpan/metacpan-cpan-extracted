package My::Build::Win32_MSVC;

use strict;
use base qw(My::Build::Win32);
use My::Build::Utility qw(awx_install_arch_file awx_install_arch_dir);
use Alien::wxWidgets::Utility qw(awx_cc_version);
use Config;

sub awx_configure {
    my $self = shift;
    my %config = $self->SUPER::awx_configure;

    $config{c_flags} .= ' -GF -TP ';

    if( $self->awx_debug ) {
        $config{link_flags} .= ' -debug ';
    }

    my $cccflags = $self->wx_config( 'cxxflags' );
    my $libs = $self->wx_config( 'libs' );
    my $incdir = $self->awx_wx_config_data->{wxinc};
    my $cincdir = $self->awx_wx_config_data->{wxcontrinc};
    my $iincdir = awx_install_arch_dir( $self, 'rEpLaCe/include' );

    foreach ( split /\s+/, $cccflags ) {
        m(^-DSTRICT) && next;
        m(^-I) && do {
            next if m{(?:regex|zlib|jpeg|png|tiff|expat[\\/]lib)$};
            if( $self->notes( 'build_wx' ) ) {
                $_ =~ s{\Q$cincdir\E}{$iincdir};
                $_ =~ s{\Q$incdir\E}{$iincdir};
            }
            if( $_ =~ /-I\Q$self->{awx_setup_dir}\E/ && !$self->is_wince ) {
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
        next if m{(?:(?:zlib|regexu?|expat|png|jpeg|tiff)[uhd]{0,2}\.lib)$};
        $config{link_libraries} .= "$_ ";
    }
    $config{link_libraries} .= 'msvcprt.lib ' if awx_cc_version( 'cl' ) > 6;

    my $dlls = $self->awx_wx_config_data->{dlls};
    $config{_libraries} = {};

    while( my( $key, $value ) = each %$dlls ) {
        $config{_libraries}{$key} =
          { map { $_ => File::Basename::basename( $value->{$_} ) }
                keys %$value };
        if( $value->{link} ) {
            $config{_libraries}{$key}{link} = $value->{link};
        } elsif( $value->{lib} ) {
            $config{_libraries}{$key}{link} = $config{_libraries}{$key}{lib};
        }
    }

    $config{config}{build} =
        $self->awx_wx_config_data->{build_kind} || 'multi';

    return %config;
}

sub awx_compiler_kind { 'cl' }

sub awx_strip_dlls { }


1;
