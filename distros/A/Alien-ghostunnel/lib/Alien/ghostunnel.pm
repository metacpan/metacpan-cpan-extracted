package Alien::ghostunnel;

use strict;
use warnings;
use 5.008004;
use base qw( Alien::Base );

# ABSTRACT: Find or install ghostunnel TLS proxy
our $VERSION = '0.01'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::ghostunnel - Find or install ghostunnel TLS proxy

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use Alien::ghostunnel;
 use Env qw( @PATH );
 
 unshift @PATH, Alien::ghostunnel->bin_dir;

 system 'ghostunnel', ...;

=head1 DESCRIPTION

This L<Alien> will find or build L<ghostunnel|https://github.com/ghostunnel/ghostunnel>,
and make it available to Perl modules.  Ghostunnel is a simple TLS proxy with mutual
authentication support for securing non-TLS backend applications.

If there is a known binary build on the C<ghostunnel> project page for your platform,
then that will be downloaded.  Otherwise if you have a Go compiler available it will
be built from source.  If neither of those options work then you are out of luck,
unfortunately.

If for whatever reason you prefer not to install the binary version of ghostunnel,
you can set C<ALIEN_GHOSTUNNEL_SOURCE> to a true value when installing:

 $ env ALIEN_GHOSTUNNEL_SOURCE=1 cpanm Alien::ghostunnel

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
