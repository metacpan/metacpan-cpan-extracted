package Alien::gdal;

use 5.010;
use strict;
use warnings;
use parent qw( Alien::Base );
use FFI::CheckLib;

our $VERSION = '1.16';

my ($have_geos, $have_proj);
my @have_aliens;
BEGIN {
    my $sep_char = ($^O =~ /mswin/i) ? ';' : ':';
    $have_geos = eval 'require Alien::geos::af';
    foreach my $alien_lib (qw /Alien::geos::af Alien::sqlite Alien::spatialite Alien::freexl Alien::proj/) {
        my $have_lib = eval "require $alien_lib";
        my $pushed_to_env = 0;
        if ($have_lib && $alien_lib->install_type eq 'share') {
            push @have_aliens, $alien_lib;
            #  crude, but otherwise Geo::GDAL::FFI does not
            #  get fed all the needed info
            #warn "Adding Alien::geos bin to path: " . Alien::geos::af->bin_dir;
            $ENV{PATH} =~ s/;$//;
            $ENV{PATH} .= $sep_char . join ($sep_char, $alien_lib->bin_dir);
            #warn $ENV{PATH};
        }
    }
    # 
    if (!$ENV{PROJSO} and $^O =~ /mswin/i) {
        my $libpath;
        $have_proj = eval 'require Alien::proj';
        if ($have_proj) {
            #  make sure we get the proj lib early in the search
            ($libpath) = Alien::proj->bin_dir;
        }
        my $proj_lib = FFI::CheckLib::find_lib (
            libpath => $libpath,
            lib     => 'proj',
        );
        #warn "PROJ_LIB FILE IS $proj_lib";
        $ENV{PROJSO} //= $proj_lib;
    }
}

sub dynamic_libs {
    my $self = shift;
    
    my (@libs) = $self->SUPER::dynamic_libs;

    foreach my $alien (@have_aliens) {
        push @libs, $alien->dynamic_libs;
    }
    my (%seen, @libs2);
    foreach my $lib (@libs) {
        next if $seen{$lib};
        push @libs2, $lib;
        $seen{$lib}++;
    }
    
    return @libs2;
}

sub cflags {
    my $self = shift;
    
    my $cflags = $self->SUPER::cflags;
    
    if ($have_geos) {
        $cflags .= ' ' . Alien::geos::af->cflags;
    }
    
    return $cflags;
}

sub libs {
    my $self = shift;
    
    my $cflags = $self->SUPER::libs;
    
    if ($have_geos) {
        $cflags .= ' ' . Alien::geos::af->libs;
    }
    
    return $cflags;
}

#sub cflags_static {
#    my $self = shift;
#    
#    my $cflags = $self->SUPER::cflags_static;
#    
#    if ($have_geos) {
#        $cflags .= ' ' . Alien::geos::af->cflags_static;
#    }
#    
#    return $cflags;
#}
#
#sub libs_static {
#    my $self = shift;
#    
#    my $cflags = $self->SUPER::libs_static;
#    
#    if ($have_geos) {
#        $cflags .= ' ' . Alien::geos::af->libs_static;
#    }
#    
#    return $cflags;
#}

sub data_dir {
    my $self = shift;
 
    my $path = $self->dist_dir . '/share/gdal';
    
    if (!-d $path) {
        #  try PkgConfig
        use PkgConfig;
        my %options;
        if (-d $self->dist_dir . '/lib/pkgconfig') {
            $options{search_path_override} = [$self->dist_dir . '/lib/pkgconfig'];
        }
        my $o = PkgConfig->find('gdal', %options);
        if ($o->errmsg) {
            warn $o->errmsg;       
        }
        else {
            $path = $o->get_var('datadir');
            if ($path =~ m|/data$|) {
                my $alt_path = $path;
                $alt_path =~ s|/data$||;
                if (!-d $path && -d $alt_path) {
                    #  GDAL 2.3.x and earlier erroneously appended /data
                    $path = $alt_path;
                }
            }
        }
    }

    warn "Cannot find gdal data dir"
      if not (defined $path and -d $path);

    return $path;
}

1;

__END__

=head1 NAME

Alien::gdal - Compile GDAL, the Geographic Data Abstraction Library

=head1 BUILD STATUS
 
=begin HTML
 
<p>
    <img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
    <a href="https://travis-ci.org/shawnlaffan/perl-alien-gdal"><img src="https://travis-ci.org/shawnlaffan/perl-alien-gdal.svg?branch=master" /></a>
    <a href="https://ci.appveyor.com/project/shawnlaffan/perl-alien-gdal"><img src="https://ci.appveyor.com/api/projects/status/1tqk5rd40cv2ve8q?svg=true" /></a>
</p>

=end HTML

=head1 SYNOPSIS

    use Alien::gdal;

    use Env qw(@PATH);
    unshift @PATH, Alien::gdal->bin_dir;

    print Alien::gdal->dist_dir;

    #  assuming you have populated @args already
    system (Alien::gdal->bin_dir . '/gdalwarp', @args);
    
    #  access the GDAL data directory (note that not all system installs include it)
    my $path = Alien::gdal->data_dir;
    
=head1 DESCRIPTION

GDAL is the Geographic Data Abstraction Library.  See L<http://www.gdal.org>.


=head1 REPORTING BUGS

Please send any bugs, suggestions, or feature requests to 
L<https://github.com/shawnlaffan/perl-alien-gdal/issues>.

=head1 SEE ALSO

L<Geo::GDAL>

L<Geo::GDAL::FFI>

L<Alien::geos::af>

=head1 AUTHORS

Shawn Laffan, E<lt>shawnlaffan@gmail.comE<gt>

Jason Mumbulla (did all the initial work - see git log for details)

Ari Jolma

=head1 COPYRIGHT AND LICENSE


Copyright 2017- by Shawn Laffan and Jason Mumbulla


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
