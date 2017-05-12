=pod

=encoding utf-8

=head1 PURPOSE

Test that Acme::Futuristic::Perl works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

use_ok('Acme::Futuristic::Perl');
cmp_ok($^V, '>', 6.9, '$^V');
cmp_ok($], '>', 6.9, '$]');
done_testing;
