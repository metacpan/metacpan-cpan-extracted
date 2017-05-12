=pod

=encoding utf-8

=head1 PURPOSE

Test lazy defaults.

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

{
	package WWW;
	use Class::Tiny::Antlers;
	
	use constant STYLE => 'non-coderef default with explicit lazy => 1';
	
	has aaa => (is => 'ro',  lazy => 1, default => 11);
	has bbb => (is => 'rw',  lazy => 1, default => 12);
	has ccc => (is => 'rwp', lazy => 1, default => 13);
}

{
	package XXX;
	use Class::Tiny::Antlers;

	use constant STYLE => 'coderef default with explicit lazy => 1';

	has aaa => (is => 'ro',  lazy => 1, default => sub { 11 });
	has bbb => (is => 'rw',  lazy => 1, default => sub { 12 });
	has ccc => (is => 'rwp', lazy => 1, default => sub { 13 });
}

{
	package YYY;
	use Class::Tiny::Antlers;
	
	use constant STYLE => 'non-coderef default with implicit lazy => 1';
	
	has aaa => (is => 'ro',  default => 11);
	has bbb => (is => 'rw',  default => 12);
	has ccc => (is => 'rwp', default => 13);
}

{
	package ZZZ;
	use Class::Tiny::Antlers;

	use constant STYLE => 'coderef default with implicit lazy => 1';

	has aaa => (is => 'ro',  default => sub { 11 });
	has bbb => (is => 'rw',  default => sub { 12 });
	has ccc => (is => 'rwp', default => sub { 13 });
}

for my $class (qw/ WWW XXX YYY ZZZ /)
{
	subtest sprintf('Class %s, %s', $class, $class->STYLE), sub {
		
		subtest "A new $class object setting nothing in the constructor" => sub {
			my $obj = new_ok $class;
			
			subtest "ro attribute" => sub {
				is($obj->{aaa}, undef, 'default is lazy');
				is($obj->aaa, 11, 'returns correct value');
				is($obj->{aaa}, 11, 'stores into the hashref');
				done_testing;
			};
			
			subtest "rw attribute" => sub {
				is($obj->{bbb}, undef, 'default is lazy');
				is($obj->bbb, 12, 'returns correct value');
				is($obj->{bbb}, 12, 'stores into the hashref');
				done_testing;
			};
			
			subtest "rw attribute" => sub {
				is($obj->{ccc}, undef, 'default is lazy');
				is($obj->ccc, 13, 'returns correct value');
				is($obj->{ccc}, 13, 'stores into the hashref');
				done_testing;
			};
			
			done_testing;
		};
		
		subtest "A new $class object setting everything in the constructor" => sub {
			my $obj = new_ok $class, [ aaa => 21, bbb => 22, ccc => 23 ];
			
			is($obj->aaa, 21, 'ro attribute; does not return default');
			is($obj->bbb, 22, 'rw attribute; does not return default');
			is($obj->ccc, 23, 'rwp attribute; does not return default');
			
			done_testing;
		};
		
		subtest "A new $class object just setting the read-only attributes" => sub {
			my $obj = new_ok $class, [ aaa => 21 ];
			
			subtest "rw attribute" => sub {
				is($obj->{bbb}, undef, 'attribute was not set in constructor');
				$obj->bbb(22);
				is($obj->bbb, 22, 'writer beats default');
				done_testing;
			};
			
			subtest "rwp attribute" => sub {
				is($obj->{ccc}, undef, 'attribute was not set in constructor');
				$obj->_set_ccc(23);
				is($obj->ccc, 23, 'writer beats default');
				done_testing;
			};
			
			done_testing;
		};
		
		done_testing;
	};
}

for my $d ('non-coderef', sub {})
{
	like(
		exception { package Bad1; use Class::Tiny; use Class::Tiny::Antlers; has xxx => (lazy => 0, default => $d) },
		qr{^Class::Tiny does not support eager defaults},
		"Attempt to use an eager default throws an exception with $d default",
	);
}

done_testing;

