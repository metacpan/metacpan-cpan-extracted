package Alien::gdal;

use strict;
use warnings;
use parent qw( Alien::Base );

our $VERSION = '1.11';

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
    system (Alien::gdal->bin_dir, 'gdalwarp', @args);
    
    #  access the example data distributed with gdal
    my $path = Alien::gdal->data_dir;
    
=head1 DESCRIPTION

GDAL is the Geographic Data Abstraction Library.  See L<http://www.gdal.org>.


=head1 REPORTING BUGS

Please send any bugs, suggestions, or feature requests to 
L<https://github.com/shawnlaffan/perl-alien-gdal/issues>.

=head1 SEE ALSO

L<Geo::GDAL>

L<Geo::GDAL::FFI>

=head1 AUTHORS

Shawn Laffan, E<lt>shawnlaffan@gmail.comE<gt>

Jason Mumbulla (did all the initial work - see git log for details)

Ari Jolma

=head1 COPYRIGHT AND LICENSE


Copyright 2017 by Shawn Laffan and Jason Mumbulla


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
