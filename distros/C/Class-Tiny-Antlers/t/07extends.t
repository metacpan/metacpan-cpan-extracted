=pod

=encoding utf-8

=head1 PURPOSE

Test that C<extends> works.

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

{
	package WWW;
	use Class::Tiny::Antlers;
}

{
	package XXX;
	use Class::Tiny::Antlers;
	extends qw( WWW );
}

{
	package YYY;
	use Class::Tiny::Antlers;
}

{
	package ZZZ;
	use Class::Tiny::Antlers;
	extends qw( XXX YYY );
}

isa_ok('WWW'->new, $_) for qw( Class::Tiny::Object WWW );
isa_ok('XXX'->new, $_) for qw( Class::Tiny::Object WWW XXX );
isa_ok('YYY'->new, $_) for qw( Class::Tiny::Object YYY );
isa_ok('ZZZ'->new, $_) for qw( Class::Tiny::Object WWW XXX YYY ZZZ );

done_testing;
