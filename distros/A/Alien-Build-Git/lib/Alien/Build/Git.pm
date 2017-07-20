package Alien::Build::Git;

use strict;
use warnings;
use 5.008001;

# ABSTRACT: Alien::Build tools for interacting with git
our $VERSION = '0.01'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Git - Alien::Build tools for interacting with git

=head1 VERSION

version 0.01

=head1 SYNOPSIS

Using helper from L<Alien::git>:

 use alienfile;
 
 share {
 
   download [
     [ '%{git}', 'clone', 'http://example.com/project-foo.git' ],
   ];
   
   ...
 
 };

Using plugin L<Alien::Build::Plugin::Download::Git>:

 use alienfile;
 
 meta->prop->{start_url} = 'http://example.com/project-foo.git';
 plugin 'Download::Git' =>(
   version => qr/^v([0-9\.]+)$/,
 );

=head1 DESCRIPTION

This module is documentation only for how to use C<git> as a download source
from L<alienfile> + L<Alien::Build>.  Depending on the project source that you
are using and the way your L<alienfile> is structured, you will want to use
one of three modules that come with the distribution C<Alien-Build-Git>.
See the synopsis above and the modules in the SEE ALSO section below.  To decide
which you need.

Also please carefully consider NOT using one of these modules.  If you can,
using http or ftp to download your target project will probably require fewer
and less error-prone dependencies.

=head1 SEE ALSO

=over 4

=item L<Alien::git>

=item L<Alien::Build::Plugin::Download::Git>

=item L<Alien::Build::Plugin::Fetch::Git>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
