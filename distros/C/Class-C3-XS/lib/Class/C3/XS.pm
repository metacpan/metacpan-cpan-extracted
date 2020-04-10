package Class::C3::XS; # git description: v0.14-7-gf53d46e
# ABSTRACT: XS speedups for Class::C3

use 5.006_000;
use strict;
use warnings;

our $VERSION = '0.15';

#pod =pod
#pod
#pod =head1 SYNOPSIS
#pod
#pod   use Class::C3; # Automatically loads Class::C3::XS
#pod                  #  if it's installed locally
#pod
#pod =head1 DESCRIPTION
#pod
#pod This contains XS performance enhancers for L<Class::C3> version
#pod 0.16 and higher.  The main L<Class::C3> package will use this
#pod package automatically if it can find it.  Do not use this
#pod package directly, use L<Class::C3> instead.
#pod
#pod The test suite here is not complete, although it does verify
#pod a few basic things.  The best testing comes from running the
#pod L<Class::C3> test suite *after* this module is installed.
#pod
#pod This module won't do anything for you if you're running a
#pod version of L<Class::C3> older than 0.16.  (It's not a
#pod dependency because it would be circular with the optional
#pod dependency from that package to this one).
#pod
#pod =cut

require XSLoader;
XSLoader::load('Class::C3::XS', $VERSION);

package # hide me from PAUSE
    next;

sub can { Class::C3::XS::_nextcan($_[0], 0) }

sub method {
    my $method = Class::C3::XS::_nextcan($_[0], 1);
    goto &$method;
}

package # hide me from PAUSE
    maybe::next;

sub method {
    my $method = Class::C3::XS::_nextcan($_[0], 0);
    goto &$method if defined $method;
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::C3::XS - XS speedups for Class::C3

=head1 VERSION

version 0.15

=head1 SYNOPSIS

  use Class::C3; # Automatically loads Class::C3::XS
                 #  if it's installed locally

=head1 DESCRIPTION

This contains XS performance enhancers for L<Class::C3> version
0.16 and higher.  The main L<Class::C3> package will use this
package automatically if it can find it.  Do not use this
package directly, use L<Class::C3> instead.

The test suite here is not complete, although it does verify
a few basic things.  The best testing comes from running the
L<Class::C3> test suite *after* this module is installed.

This module won't do anything for you if you're running a
version of L<Class::C3> older than 0.16.  (It's not a
dependency because it would be circular with the optional
dependency from that package to this one).

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Class-C3-XS>
(or L<bug-Class-C3-XS@rt.cpan.org|mailto:bug-Class-C3-XS@rt.cpan.org>).

=head1 AUTHOR

Brandon L. Black <blblack@gmail.com>

=head1 CONTRIBUTORS

=for stopwords Florian Ragwitz Karen Etheridge Graham Knop Yuval Kogman

=over 4

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Graham Knop <haarg@haarg.org>

=item *

Yuval Kogman <nothingmuch@woobling.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by Brandon L. Black.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
