=pod

=encoding utf-8

=head1 PURPOSE

Test that Crypt::Polybius works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use Crypt::Polybius;

my $o = Crypt::Polybius->new;

is($o->encipher('Bat!'), '12 11 44', 'encipher');
is($o->decipher('12 11 44'), 'BAT', 'decipher');

is($o->encipher("JIji\x{0130}\x{0131}"), '24 24 24 24 24 24', 'encipher - tricky bits');

done_testing;
