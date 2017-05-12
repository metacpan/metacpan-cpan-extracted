package My::Build::Any_wx_config_Bakefile;

use strict;
our @ISA = qw(My::Build::Any_wx_config::Base);
use Config;

sub awx_wx_config_data {
    my $self = shift;
    return $self->{awx_data} if $self->{awx_data};

    my %data;

    foreach my $item ( qw(cxx ld cxxflags version libs basename prefix) ) {
        $data{$item} = $self->_call_wx_config( $item );
    }
    $data{ld} =~ s/\-o\s*$/ /; # wxWidgets puts 'ld -o' into LD
    $data{libs} =~ s/\-lwx\S+//g;

    my @mono_libs = $self->_version_2_dec( $data{version} ) >= 2.009 ?
                        @My::Build::Any_wx_config::MONO_LIBRARIES_2_9 :
                        @My::Build::Any_wx_config::MONO_LIBRARIES_2_8;
    my $arg = 'libs' . $My::Build::Any_wx_config::WX_CONFIG_LIBSEP .
        join ',', grep { !m/base/ }
                       ( $self->awx_is_monolithic ?
                             @mono_libs :
                             @My::Build::Any_wx_config::LIBRARIES );
    my $libraries = $self->_call_wx_config( $arg );

    my( $libname_re, $libsuffix );
    if( $^O eq 'openbsd' ) {
        $libname_re = '-l(.*_(\w+))';
        $libsuffix = '.1.0';
    } else {
        $libname_re = '-l(.*_(\w+)-.*)';
        $libsuffix = '';
    }
    foreach my $lib ( grep { m/\-lwx/ } split ' ', $libraries ) {
        $lib =~ m/$libname_re/ or die $lib;
        my( $key, $name ) = ( $2, $1 );
        $key = 'base' if $key =~ m/^base[ud]{0,2}/;
        $key = 'base' if $key =~ m/^carbon|^cocoa/ && $name !~ /osx_/; # here for Mac
        $key = 'core' if $key =~ m/^carbon|^cocoa/ && $name =~ /osx_/; # here for Mac
        $key = 'core' if $key =~ m/^mac[ud]{0,2}/;
        $key = 'core' if $key =~ m/^gtk2?[ud]{0,2}/
                              && $self->awx_is_monolithic
                              && $lib =~ m/(?:gtk2?|mac)[ud]{0,2}-/;
        my $dll = "lib${name}." . $self->awx_dlext . $libsuffix;

        $data{dlls}{$key} = { dll  => $dll,
                              link => $lib };
    }
    if( $self->awx_is_monolithic ) {
        $data{dlls}{mono} = delete $data{dlls}{core};
    }

    $self->{awx_data} = \%data;
}

1;
