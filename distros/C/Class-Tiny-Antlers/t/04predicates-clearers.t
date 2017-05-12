=pod

=encoding utf-8

=head1 PURPOSE

Test predicates and clearers.

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
	package XXX;
	use Class::Tiny::Antlers;
	has aaa  => (predicate => 1, clearer => 1);
	has _bbb => (predicate => 1, clearer => 1);
	has ccc  => (predicate => 'HasCCC', clearer => 'ClearCCC');
}

my %subtests = (                                      #      reader writer predicate  clearer       #
	"predicates and clearers for public attribute"  => [qw/   aaa    aaa    has_aaa    clear_aaa    /],
	"predicates and clearers for private attribute" => [qw/   _bbb   _bbb   _has_bbb   _clear_bbb   /],
	"custom predicates and clearers"                => [qw/   ccc    ccc    HasCCC     ClearCCC     /],
);

for my $subtest (sort keys %subtests)
{
	my (undef, $writer, $predicate, $clearer) = @{ $subtests{$subtest} };
	
	subtest $subtest => sub {
		my $obj = new_ok 'XXX';
		
		ok(! $obj->$predicate, 'value not set in constructor; predicate returns false');
		$obj->$writer(1);
		ok($obj->$predicate, 'value set by accessor; predicate returns true');
		$obj->$clearer;
		ok(!$obj->$predicate, 'value wiped by clearer; predicate returns false');
		$obj->$writer(undef);
		ok($obj->$predicate, 'value set by accessor; predicate returns true, even though value is undef');
		
		my $obj2 = new_ok 'XXX', [ $writer => 42 ];
		ok($obj->$predicate, 'value set in constructor; predicate returns true');
		
		done_testing;
	};
}

done_testing;

