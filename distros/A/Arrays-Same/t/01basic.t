=pod

=encoding utf-8

=head1 PURPOSE

Test that Arrays::Same compiles and works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Arrays::Same -all;

ok !arrays_same_i([1,2,3], [0,2,3]);
ok !arrays_same_i([1,2,3], [1,2,4]);
ok !arrays_same_i([1,2,3], [1,2,3,4]);
ok !arrays_same_i([1,2,3], [1,2]);
ok arrays_same_i([1,2,3], [1,2,3]);

ok !arrays_same_s([1,2,3], [0,2,3]);
ok !arrays_same_s([1,2,3], [1,2,4]);
ok !arrays_same_s([1,2,3], [1,2,3,4]);
ok !arrays_same_s([1,2,3], [1,2]);
ok arrays_same_s([1,2,3], [1,2,3]);

ok !arrays_same_s(["foo"], ["bar"]);
ok arrays_same_i(["foo"], ["bar"]);

ok arrays_same_s([], []);
ok arrays_same_i([], []);

done_testing;

