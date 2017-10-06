package Alien::LibreSSL;

use strict;
use warnings;
use 5.008001;
use base qw( Alien::Base );

# ABSTRACT: Alien wrapper for LibreSSL (alternative to OpenSSL)
our $VERSION = '0.02'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::LibreSSL - Alien wrapper for LibreSSL (alternative to OpenSSL)

=head1 VERSION

version 0.02

=head1 SYNOPSIS

EUMM:

 use ExtUtils::MakeMaker;
 use Alien::Base::Wrapper qw( Alien::LibreSSL !export );
 
 WriteMakefile(
   ...
   CONFIGURE => {
     'Alien::Build::Wrapper' => 0,
     'Alien::LibreSSL'       => 0,
   },
   Alien::Base::Wrapper->mm_args,
 );

MB:

 use Module::Build;
 use Alien::Base::Wrapper qw( Alien::LibreSSL !export );
 
 my $build = Module::Build->new(
   ...
   configure_requires => {
     'Alien::Build::Wrapper' => 0,
     'Alien::LibreSSL'       => 0,
   },
   Alien::Base::Wrapper->mb_args,
   ...
 );
 
 $build->create_build_script;

Perl script:

 use Alien::LibreSSL;
 use Env qw( @PATH );
 
 unshift @PATH, 'Alien::LibreSSL->bin_dir;
 system 'openssl ...';

=head1 DESCRIPTION

This module provides an implementation of SSL.  It will use the system
SSL, if it can be found.  If the system does not provide SSL, this alien
will download and build LibreSSL, a drop in replacement for OpenSSL

=head2 Motiviations

SSL has lots of pitfalls.  SSL on Perl has all of those pitfalls plus some
more.  Once you get L<Net::SSLeay> you are mostly out of the woods.  Getting
L<Net::SSLeay> to install can be problematic on some platforms.  My hope is that
some combination of this module and L<Alien::OpenSSL> will one day make it easier
to install L<Net::SSLeay>.

=head1 CAVEATS

Normally L<Alien::Build> + L<alienfile> use L<Net::SSLeay> (via L<HTTP::Tiny> or
L<LWP::UserAgent>) in order to download C<https> URLs from the internet, but for
this to be a dependency of L<Net::SSLeay> that will obviously not work.  Instead
this alien attempts to bootstrap SSL by downloading via C<wget> or C<curl>, if
they are available.  By default, if they are not available then this Alien will
attempt to download via C<http>.  This obviously might not be desirable for some
so you can set C<ALIEN_OPENSSL_FTP> to C<0> if you want to ensure the trasfer
happens over C<https> (and will die, if it isn't available).

=head1 ENVIRONMENT

=over 4

=item ALIEN_OPENSSL_FTP

Set to C<1> to allow downloads via C<ftp> or C<http> (the default).
Set to C<0> to disallow insecure downloads over C<ftp> or C<http>.

=back

=head1 SEE ALSO

=over 4

=item L<Alien>

=item L<Alien::OpenSSL>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
