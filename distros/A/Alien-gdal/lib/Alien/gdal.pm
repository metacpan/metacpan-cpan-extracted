package Alien::gdal;

use strict;
use warnings;
use base qw( Alien::Base );

our $VERSION = '1.02';

1;

__END__

=head1 NAME

Alien::gdal - Compile gdal

=head1 SYNOPSIS

  use Alien::gdal;


=head1 ABSTRACT

use Env qw(@PATH);
unshift @PATH, Alien::gdal->bin_dir;
 
print Alien::gdal->dist_dir;

#  example assumes @args exists already
system (Alien::gdal->bin_dir, 'gdalwarp', @args);

=head1 DESCRIPTION

GDAL is the Geographic Data Abstraction Library.  See L<http://www.gdal.org>.


=back

=head1 REPORTING BUGS

Please send any bugs, suggestions, or feature requests to
  L<https://github.com/shawnlaffan/perl-alien-gdal/issues>.

=head1 SEE ALSO

L<Geo::GDAL>

=head1 AUTHORS

Shawn Laffan, E<lt>shawnlaffan@gmail.comE<gt>
Jason Mumbulla (did all the initial work - see github log for details)
Ari Jolma

=head1 COPYRIGHT AND LICENSE


Copyright 2017 by Shawn Laffan and Jason Mumbulla


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
