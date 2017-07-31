package Alien::autoconf;

use strict;
use warnings;
use 5.008001;
use base qw( Alien::Base );

# ABSTRACT: Build or find autoconf
our $VERSION = '0.05'; # VERSION







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::autoconf - Build or find autoconf

=head1 VERSION

version 0.05

=head1 SYNOPSIS

In your script or module:

 use Alien::autoconf;
 use Env qw( @PATH );
 
 unshift @ENV, Alien::autoconf->bin_dir;

=head1 DESCRIPTION

This distribution provides autoconf so that it can be used by other 
Perl distributions that are on CPAN.  It does this by first trying to 
detect an existing install of autoconf on your system.  If found it 
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=head1 SEE ALSO

L<Alien>, L<Alien::Base>, L<Alien::Build::Manual::AlienUser>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
