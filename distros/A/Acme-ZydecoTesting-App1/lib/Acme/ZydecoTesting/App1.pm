use v5.14;
use strict;
use warnings;

package Acme::ZydecoTesting::App1;

BEGIN {
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
};

use Zydeco;

role Quux {
	has quuux ( type => Int );
}

include Classes;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Acme::ZydecoTesting::App1 - test packaging a Zydeco app

=head1 SYNOPSIS

  use Acme::ZydecoTesting::App1;
  use Test::More;
  
  my $foo = Acme::ZydecoTesting::App1->new_foo( quuux => 42 );
  is( $foo->quuux, 42 );
  
  done_testing;

=head1 DESCRIPTION

Just a test for L<Zydeco> and how easy to package it is.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Acme-ZydecoTesting-App1>.

=head1 SEE ALSO

L<Zydeco>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

