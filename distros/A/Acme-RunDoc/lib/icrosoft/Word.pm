package icrosoft::Word;
BEGIN {
	$icrosoft::Word::AUTHORITY = 'cpan:TOBYINK';
	$icrosoft::Word::VERSION   = '0.002';
}
package main;
use strict;
use Acme::RunDoc;
if ([caller(0)]->[3] > 0)
{
	Carp::croak("Usage:  perl -Microsoft::Word somefile.doc");
}
exit( Acme::RunDoc->do($0) );
__FILE__
__END__

=head1 NAME

icrosoft::Word - (sic) syntactic sugar for Acme::RunDoc.

=head2 SYNOPSIS

 perl -Microsoft::Word helloworld.doc

=head1 SEE ALSO

L<Acme::RunDoc>, L<Text::Extract::Word>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

