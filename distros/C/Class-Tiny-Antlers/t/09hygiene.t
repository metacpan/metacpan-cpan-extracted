=pod

=encoding utf-8

=head1 PURPOSE

Test namespace cleanliness.

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
	use Class::Tiny::Antlers -all;
	
	has aaa => (is => 'ro',  lazy => 1, default => 11);
	has bbb => (is => 'rw',  lazy => 1, default => 12);
	has ccc => (is => 'rwp', lazy => 1, default => 13);
	
	no Class::Tiny::Antlers;
}

ok( 'WWW'->can($_), "WWW can $_") for qw( aaa bbb ccc );
ok(!'WWW'->can($_), "WWW cannot $_") for qw( confess has extends with );

done_testing;
