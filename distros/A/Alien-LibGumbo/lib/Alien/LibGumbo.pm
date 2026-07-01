package Alien::LibGumbo;

use v5.10;
use strict;
use warnings;

our $VERSION = 0.06;

use parent 'Alien::Base';

=head1 NAME

Alien::LibGumbo - Gumbo parser library

=head1 DESCRIPTION

This distribution installs L<libgumbo|https://codeberg.org/gumbo-parser/gumbo-parser> on your
system for use by perl modules like L<HTML::Gumbo>.

The original L<libgumbo|https://github.com/google/gumbo-parser> by Google was
archived on GitHub with no development since 2016. This distribution now uses
the maintained fork by Grigory Kirillov, whose first release of the fork
(0.11.0) was in July 2023.

B<If you're interested in parsing HTML> then you want L<HTML::Gumbo> module, not this.

=head1 AUTHOR

Ruslan Zakirov E<lt>Ruslan.Zakirov@gmail.comE<gt>

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to: L<bug-Alien-LibGumbo@rt.cpan.org|mailto:bug-Alien-LibGumbo@rt.cpan.org>

Or via the web at: L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=Alien-LibGumbo>.

=head1 LICENSE

Under the same terms as perl itself.

=cut

1;
