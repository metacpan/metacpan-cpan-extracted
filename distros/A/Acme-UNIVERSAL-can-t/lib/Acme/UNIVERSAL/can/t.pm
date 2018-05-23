use 5.008003;
use strict;
use warnings;

package Acme::UNIVERSAL::can::t;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

sub can't { not shift->can(@_) }

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Acme::UNIVERSAL::can::t - the opposite of UNIVERSAL::can

=head1 SYNOPSIS

 use strict;
 use warnings;
 use Test::More;
 
  {
    package Foo;
    sub bar { ... }
 }
 
 use_ok("Acme::UNIVERSAL::can't");
 ok(Foo->can("bar"));
 ok(Foo->can't("baz"));
 done_testing;

=head1 DESCRIPTION

This module will tell you what methods I<can't> be called on an object or
class. The opposite of C<UNIVERSAL::can>.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Acme-UNIVERSAL-can-t>.

=head1 SEE ALSO

L<UNIVERSAL>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
