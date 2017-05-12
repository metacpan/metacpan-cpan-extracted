package Acme::Canadian;

use warnings;
use strict;

use Filter::Simple;

=head1 NAME

Acme::Canadian - Canooks in your code, eh?

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Acme::Canadian;

    print "What's this all aboot?", eh?

=head1 DESCRIPTION

What is this module aboot? I'll tell you, eh?  It decanadianizes your code.

All in good fun.  Feel free to write Acme::USA where your code attempts futily
to control all other CPAN modules.

=cut

FILTER {
  s/, eh\?/;/g; s/aboot/about/;
}

=head1 AUTHOR

John Cappiello, C<< <jcap at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-canadian at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Canadian>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Canadian

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Canadian>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Canadian>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Canadian>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Canadian>

=back

=head1 ACKNOWLEDGEMENTS

Cees, Shawn, and David without whom I would have lacked all inspiration, eh?

=head1 COPYRIGHT & LICENSE

Copyright 2006 John Cappiello, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Acme::Canadian
