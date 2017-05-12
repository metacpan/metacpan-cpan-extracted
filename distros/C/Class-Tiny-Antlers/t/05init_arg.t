=pod

=encoding utf-8

=head1 PURPOSE

Test that C<init_arg> I<doesn't> work.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

like(
	exception { package Bad1; use Class::Tiny::Antlers; has xxx => (init_arg => undef) },
	qr{^Class::Tiny does not support init_arg},
	"init_arg => undef",
);

like(
	exception { package Bad2; use Class::Tiny::Antlers; has xxx => (init_arg => 'yyy') },
	qr{^Class::Tiny does not support init_arg},
	"init_arg => 'yyy'",
);

is(
	exception { package Good1; use Class::Tiny::Antlers; has xxx => (init_arg => 'xxx') },
	undef,
	"init_arg => 'xxx'",
);

done_testing;

