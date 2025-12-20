=pod

=encoding utf-8

=head1 PURPOSE

Check C<weak_ref> support.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

BEGIN {
	package Local::Thing;
	use Class::XSConstructor
		blah => {},
		bleh => { weak_ref => 1 };
};

my $x = [];
my $y = [];

my $thing = Local::Thing->new( blah => $x, bleh => $y );

ok defined $thing->{blah};
ok defined $thing->{bleh};

undef $x;
undef $y;

ok defined $thing->{blah};
ok !defined $thing->{bleh};

done_testing;

