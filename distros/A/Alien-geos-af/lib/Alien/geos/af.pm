package Alien::geos::af;

use strict;
use warnings;
use parent qw( Alien::Base );

our $VERSION = '1.005';

#  make sure we find geos and geos_c
sub dynamic_libs {
    my ($class) = @_;

    require FFI::CheckLib;

    if ($class->install_type('system')) {
        my @libs;
        push @libs, FFI::CheckLib::find_lib(
            lib => 'geos',
        );
        push @libs, FFI::CheckLib::find_lib(
            lib => 'geos_c',
        );
        return wantarray ? @libs : $libs[0];
    }
    else {
        my $dir = $class->dist_dir;

        my $dynamic = Path::Tiny->new($class->dist_dir, 'dynamic');
        if (-d $dynamic) {
            $dir = $dynamic;
        }
        
        my @libs;
        if ($^O =~ /mswin/i) {
            #warn "Checking $dir\n";
            #  until FFI::CheckLib::find_lib handles names like geos-3-7-0.dll 
            my $dh;
            opendir $dh, "$dir/bin" or die "Unable to open dir handle for $dir/bin";
            my @dlls
              = map {"$dir/$_"}
                grep {/geos.+\.dll$/}
                readdir $dh;
            push @libs, @dlls;
            $dh->close;
        }
        else {
            push @libs, FFI::CheckLib::find_lib(
                lib        => ['geos', 'geos_c'],
                libpath    => $dir,
                systempath => [],
                recursive  => 1,
            );
        }
        #warn "FOUND LIBS: " . join (':', @libs);
        return wantarray ? @libs : $libs[0];
    }
}

1;

__END__

=head1 NAME

Alien::geos::af - Compile GEOS, the Geometry Engine, Open Source

=head1 BUILD STATUS
 
=begin HTML
 
<p>
    <img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
    <a href="https://travis-ci.org/shawnlaffan/perl-alien-geos"><img src="https://travis-ci.org/shawnlaffan/perl-alien-geos.svg?branch=master" /></a>
    <a href="https://ci.appveyor.com/project/shawnlaffan/perl-alien-geos"><img src="https://ci.appveyor.com/api/projects/status/1tqk5rd40cv2ve8q?svg=true" /></a>
</p>

=end HTML

=head1 SYNOPSIS

    use Alien::geos::af;

    use Env qw(@PATH);
    unshift @PATH, Alien::geos::af->bin_dir;

    print Alien::geos::af->dist_dir;

    
=head1 DESCRIPTION

GEOS is the Geometry Engine, Open Source.  See L<http://geos.osgeo.org/>.

The name is chosen to not clash with a pre-existing Alien::GEOS distribution.
This package differs in that it uses the alienfile approach, hence the ::af
suffix in the name.  


=head1 REPORTING BUGS

Please send any bugs, suggestions, or feature requests to 
L<https://github.com/shawnlaffan/perl-alien-geos/issues>.

=head1 SEE ALSO

L<Geo::GDAL>

L<Geo::GDAL::FFI>

L<Alien::gdal>

=head1 AUTHORS

Shawn Laffan, E<lt>shawnlaffan@gmail.comE<gt>


=head1 COPYRIGHT AND LICENSE


Copyright 2018 by Shawn Laffan


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
