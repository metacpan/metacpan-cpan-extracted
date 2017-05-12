package Alien::Web::HalBrowser;
use parent 'Alien::Web';

use strict;
use warnings;

# ABSTRACT: Perl distribution for hal-browser sources
our $VERSION = 1.0;

1;

__END__

=pod

=head1 NAME

Alien::Web::HalBrowser - Perl distribution for hal-browser sources

=head1 VERSION

Source code from github.com/mikekelly/hal-browser as of Oct 9, 2014 (commit 407296022)

=head1 SYNOPSIS

  use Alien::Web::HalBrowser;
  
  my $dir = Alien::Web::HalBrowser->dir;
  print "hal-browser sources are installed in: $dir\n";

=head1 DESCRIPTION

This module contains the hal-browser sources from github.com/mikekelly/hal-browser packaged 
for distribution on CPAN. Upon installation, the source directory is installed into the system 
share dir (see L<File::ShareDir>) and made available via class method C<dir>. This is useful 
for web apps that use the hal-browser sources.

=head1 METHODS

This module extends L<Alien::Web> which is where the following methods are defined.

=head2 dir

Returns the hal-browser source directory as a L<Path::Class::Dir> object.

=head2 path

Returns the raw hal-browser source directory.

=head1 SEE ALSO

=over 4

=item * L<Alien::Web>

=item * L<github.com/mikekelly/hal-browser|https://github.com/mikekelly/hal-browser>

=item * L<stateless.co/hal_specification.html|http://stateless.co/hal_specification.html>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by IntelliTree Solutions llc. 

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The hal-browser is copyright (c) 2012 Mike Kelly, http://stateless.co/

See L<github.com/mikekelly/hal-browser/blob/master/MIT-LICENSE.txt|https://github.com/mikekelly/hal-browser/blob/master/MIT-LICENSE.txt>

=cut

