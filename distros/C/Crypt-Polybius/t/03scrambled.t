=pod

=encoding utf-8

=head1 PURPOSE

Test that Crypt::Role::ScrambledAlphabet works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use Crypt::Polybius;

my $o = Crypt::Polybius->new_with_traits(
	traits   => ['Crypt::Role::ScrambledAlphabet'],
	password => 'FISHING',
);

is_deeply(
	$o->square,
	[
		[qw( F I S H N )],
		[qw( G A B C D )],
		[qw( E K L M O )],
		[qw( P Q R T U )],
		[qw( V W X Y Z )],
	],
	'scrambled square',
);

is($o->encipher('Bat!'), '23 22 44', 'encipher');
is($o->decipher('23 22 44'), 'BAT', 'decipher');

done_testing;
