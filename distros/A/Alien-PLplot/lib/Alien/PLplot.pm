package Alien::PLplot;
$Alien::PLplot::VERSION = '0.001';
use strict;
use warnings;
use base qw( Alien::Base );
use File::Spec;
use 5.008004;

sub inline_auto_include {
	return  [ 'plplot.h' ];
}

1;

=pod

=encoding UTF-8

=head1 NAME

Alien::PLplot - Alien package for the PLplot plotting library

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This distribution provides PLplot so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of PLplot on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=head1 SEE ALSO

=over 4

=item L<Alien>

Documentation on the Alien concept itself.

=item L<Alien::Base>

The base class for this Alien.

=item L<PLplot|http://plplot.sourceforge.net/>

=back

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
# ABSTRACT: Alien package for the PLplot plotting library

