=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<Data::ZPath::_Lexer>.

=cut

use Test2::V0 -target => 'Data::ZPath::_Lexer';
use Test2::Tools::Spec;

describe "class `$CLASS`" => sub {

	tests 'method `new`' => sub {
		my $lx = Data::ZPath::_Lexer->new('foo/bar');
		ok( $lx->isa('Data::ZPath::_Lexer'), 'constructed lexer object' );
	};

	tests 'method `expect`' => sub {
		my $lx_ok = Data::ZPath::_Lexer->new('foo');
		is( $lx_ok->expect('NAME')->{v}, 'foo', 'expect returns matching token' );

		my $lx_bad = Data::ZPath::_Lexer->new('foo');
		like(
			dies { $lx_bad->expect('NUMBER') },
			qr/Expected NUMBER, got NAME/,
			'expect croaks on wrong token kind',
		);
	};

	tests 'method `next_tok`' => sub {
		my $lx = Data::ZPath::_Lexer->new('foo');
		my $tok = $lx->next_tok;
		is( $tok->{k}, 'NAME', 'next_tok returns token kind' );
		is( $tok->{v}, 'foo', 'next_tok returns token value' );
	};

	tests 'method `peek_kind`' => sub {
		my $lx = Data::ZPath::_Lexer->new('foo/bar');
		is( $lx->peek_kind, 'NAME', 'peek_kind reads current token kind' );
	};

	tests 'method `peek_kind_n`' => sub {
		my $lx = Data::ZPath::_Lexer->new('foo/bar');
		is( $lx->peek_kind_n(1), 'SLASH_PATH',
			'peek_kind_n reads lookahead token kind' );
	};
};

done_testing;
