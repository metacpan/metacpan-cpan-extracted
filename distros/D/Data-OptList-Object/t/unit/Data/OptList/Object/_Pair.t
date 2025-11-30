=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<Data::OptList::Object::_Pair>.

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
my $CLASS = 'Data::OptList::Object::_Pair';

describe "class `$CLASS`" => sub {

	tests 'method `key`' => sub {
		my $o = bless [ foo =>  42 ], $CLASS;
		is( $o->key, 'foo' );
	};

	tests 'method `value`' => sub {
		my $o = bless [ foo =>  42 ], $CLASS;
		is( $o->value, 42 );
		
		$o = bless [ foo =>  undef ], $CLASS;
		is( $o->value, undef );
	};

	tests 'method `exists`' => sub {
		my $o = bless [ foo =>  42 ], $CLASS;
		ok( $o->exists );
		
		$o = bless [ foo =>  undef ], $CLASS;
		ok( $o->exists );
	};

	tests 'method `kind`' => sub {
		my $o = bless [ foo =>  [] ], $CLASS;
		is( $o->kind, 'ARRAY' );
		
		$o = bless [ foo => undef ], $CLASS;
		is( $o->kind, 'undef' );
	};

	tests 'index 0' => sub {
		my $o = bless [ foo =>  42 ], $CLASS;
		is( $o->[0], 'foo' );
	};

	tests 'index 1' => sub {
		my $o = bless [ foo =>  42 ], $CLASS;
		is( $o->[1], 42 );
	};

	tests 'overload `bool`' => sub {
		my $o = bless [ foo => () ], $CLASS;
		ok( $o );
	};

	tests 'overload `""`' => sub {
		my $o = bless [ foo => () ], $CLASS;
		is( "$o", "foo" );
	};
};

done_testing;