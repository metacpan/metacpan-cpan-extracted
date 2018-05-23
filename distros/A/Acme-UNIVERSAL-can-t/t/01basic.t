=pod

=encoding utf-8

=head1 PURPOSE

Test that Acme::UNIVERSAL::can::t compiles.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

{
	package Foo;
	sub bar { "bar" }
};

use_ok("Acme::UNIVERSAL::can't");
ok(Foo->can("bar"));
ok(Foo->can't("baz"));
done_testing;