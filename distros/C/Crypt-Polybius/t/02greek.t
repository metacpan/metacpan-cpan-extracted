=pod

=encoding utf-8

=head1 PURPOSE

Test that Crypt::Polybius::Greek works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use utf8;
use Test::Modern;
use Crypt::Polybius::Greek;

my $o = Crypt::Polybius::Greek->new;

is($o->encipher('ρόπαλο'), '42 35 41 11 31 35', 'encipher');
is($o->decipher('42 35 41 11 31 35'), 'ΡΟΠΑΛΟ', 'decipher');

done_testing;
