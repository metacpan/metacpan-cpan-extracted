=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<Data::OptList::Object::_NoValue>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Test2::Tools::Spec;
use Data::Dumper;

use Data::OptList::Object;
my $CLASS = 'Data::OptList::Object::_NoValue';

describe "class `$CLASS`" => sub {

	tests '@ISA' => sub {
		ok $CLASS->isa('Data::OptList::Object::_Pair');
	};

	tests 'method `key`' => sub {
		my $o = bless [ foo => () ], $CLASS;
		is( $o->key, 'foo' );
	};

	tests 'method `value`' => sub {
		my $o = bless [ foo => () ], $CLASS;
		is( $o->value, undef );
	};

	tests 'method `exists`' => sub {
		my $o = bless [ foo => () ], $CLASS;
		ok( !$o->exists );
	};

	tests 'method `kind`' => sub {
		my $o = bless [ foo => () ], $CLASS;
		is( $o->kind, '' );
	};

	tests 'overload `bool`' => sub {
		my $o = bless [ foo => () ], $CLASS;
		ok( !$o );
	};

	tests 'overload `""`' => sub {
		my $o = bless [ foo => () ], $CLASS;
		ok( "$o", "foo" );

		$o = bless [()], $CLASS;
		is( "$o", "" );
	};
};

done_testing;