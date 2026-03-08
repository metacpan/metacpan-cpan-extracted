use strict;
use warnings;

package Data::ZPath::_Lexer;

use Carp qw(croak);

our $VERSION = '0.001000';

sub new {
	my ( $class, $src ) = @_;
	my $self = bless {
		src   => $src,
		i     => 0,
		toks  => [],
		pos   => 0,
	}, $class;

	$self->{toks} = $self->_tokenize($src);
	return $self;
}

sub peek_kind   { $_[0]->{toks}->[$_[0]->{pos}]->{k} }
sub peek_kind_n { $_[0]->{toks}->[$_[0]->{pos} + $_[1]]->{k} }

sub next_tok {
	my ( $self ) = @_;
	return $self->{toks}->[$self->{pos}++];
}

sub expect {
	my ( $self, $k ) = @_;
	my $t = $self->next_tok;
	croak "Expected $k, got $t->{k}" unless $t->{k} eq $k;
	return $t;
}

sub _is_ws {
	my ( $c ) = @_;
	return defined $c && $c =~ /\s/;
}

sub _tokenize {
	my ( $self, $src ) = @_;
	my @t;

	my @c = split //, $src;
	my $n = @c;
	my $i = 0;

	my $push = sub { push @t, @_ };
	my $prev_sig = sub {
		my ( $idx ) = @_;
		for ( my $j = $idx - 1; $j >= 0; $j-- ) {
			next if $c[$j] =~ /\s/;
			return $c[$j];
		}
		return undef;
	};
	my $next_sig = sub {
		my ( $idx ) = @_;
		for ( my $j = $idx + 1; $j < $n; $j++ ) {
			next if $c[$j] =~ /\s/;
			return $c[$j];
		}
		return undef;
	};
	my $ws_on_both = sub {
		my ( $left, $right ) = @_;
		return ( _is_ws($left) and _is_ws($right) );
	};

	while ( $i < $n ) {
		my $ch = $c[$i];

		if ( $ch =~ /\s/ ) {
			$i++;
			next;
		}

		my $prev = $i > 0 ? $c[$i - 1] : undef;
		my $next = $i + 1 < $n ? $c[$i + 1] : undef;
		my $pair = $i + 1 < $n ? $ch . $c[$i + 1] : '';

		my %two_char = (
			'&&' => 'ANDAND',
			'||' => 'OROR',
			'==' => 'EQEQ',
			'!=' => 'NEQ',
			'>=' => 'GE',
			'<=' => 'LE',
		);
		if ( exists $two_char{$pair} ) {
			$push->({ k => $two_char{$pair}, v => $pair });
			$i += 2;
			next;
		}

		my %one_char = (
			'+' => 'PLUS',
			'-' => 'MINUS',
			'%' => 'PCT',
			'^' => 'BXOR',
			'&' => 'BAND',
			'|' => 'BOR',
			'>' => 'GT',
			'<' => 'LT',
		);
		if ( exists $one_char{$ch} ) {
			# Keep arithmetic operators strict to avoid ambiguity with path syntax.
			if ( $ch eq '+' || $ch eq '-' || $ch eq '%' ) {
				if ( $ws_on_both->( $prev, $next ) ) {
					$push->({ k => $one_char{$ch}, v => $ch });
					$i++;
					next;
				}
				croak "Binary operator '$ch' requires whitespace around it";
			}

			$push->({ k => $one_char{$ch}, v => $ch });
			$i++;
			next;
		}

		my $prev_nonws = $prev_sig->($i);
		my $next_nonws = $next_sig->($i);

		if (  $ch eq '/' and $ws_on_both->( $prev, $next )
			and defined $prev_nonws and defined $next_nonws
			and $prev_nonws !~ m{[\[\(,:?/]}
			and $next_nonws !~ m{[\]\),:?/]} ) {
			$push->({ k => 'SLASH', v => '/' });
			$i++;
			next;
		}

		if (  $ch eq '/' and ( _is_ws($prev) xor _is_ws($next) )
			and defined $prev_nonws and defined $next_nonws
			and $prev_nonws !~ m{[\[\(,:?/]}
			and $next_nonws !~ m{[\]\),:?/]} ) {
			croak "Binary operator '/' requires whitespace around it";
		}

		if ( $ch eq '/' ) { $push->({ k => 'SLASH_PATH', v => '/' }); $i++; next; }
		if (  $ch eq '(' ) { $push->({ k => 'LPAREN', v => '(' }); $i++; next; }
		if ( $ch eq ')' ) { $push->({ k => 'RPAREN', v => ')' }); $i++; next; }
		if ( $ch eq '[' ) { $push->({ k => 'LBRACK', v => '[' }); $i++; next; }
		if ( $ch eq ']' ) { $push->({ k => 'RBRACK', v => ']' }); $i++; next; }
		if ( $ch eq ',' ) { $push->({ k => 'COMMA', v => ',' }); $i++; next; }

		if ( $ch eq '.' ) {
			if ( $i + 2 < $n and $c[$i + 1] eq '.' and $c[$i + 2] eq '*' ) {
				$push->({ k => 'DOTDOTSTAR', v => '..*' });
				$i += 3;
				next;
			}
			if ( $i + 1 < $n and $c[$i + 1] eq '.' ) {
				$push->({ k => 'DOTDOT', v => '..' });
				$i += 2;
				next;
			}
			$push->({ k => 'DOT', v => '.' });
			$i++;
			next;
		}

		if ( $ch eq '*' and $ws_on_both->( $prev, $next ) ) {
			$push->({ k => 'STAR', v => '*' });
			$i++;
			next;
		}

		if ( $ch eq '*' ) {
			if ( $i + 1 < $n and $c[$i + 1] eq '*' ) {
				$push->({ k => 'STARSTAR', v => '**' });
				$i += 2;
				next;
			}
			$push->({ k => 'STAR_PATH', v => '*' });
			$i++;
			next;
		}

		if ( $ch eq '!' ) { $push->({ k => 'NOT', v => '!' }); $i++; next; }
		if ( $ch eq '~' ) { $push->({ k => 'BNOT', v => '~' }); $i++; next; }

		if ( $ch eq '?' || $ch eq ':' ) {
			if ( $ws_on_both->( $prev, $next ) ) {
				$push->({ k => ( $ch eq '?' ) ? 'QMARK' : 'COLON', v => $ch });
				$i++;
				next;
			}
			croak "Ternary operator '$ch' requires whitespace around it";
		}

		if ( $ch eq '"' || $ch eq "'" ) {
			my $quote = $ch;
			$i++;
			my $s = '';
			my $esc = 0;
			while ( $i < $n ) {
				my $cc = $c[$i++];
				if ( $esc ) {
					$s .= _unescape_char($cc);
					$esc = 0;
					next;
				}
				if ( $cc eq '\\' ) { $esc = 1; next; }
				last if $cc eq $quote;
				$s .= $cc;
			}
			$push->({ k => 'STRING', v => $s });
			next;
		}

		if ( $ch eq '#' ) {
			my $j = $i + 1;
			croak "Invalid index '#'" unless $j < $n and $c[$j] =~ /\d/;
			my $num = '';
			while ( $j < $n and $c[$j] =~ /\d/ ) { $num .= $c[$j++]; }
			$push->({ k => 'INDEX', v => 0 + $num });
			$i = $j;
			next;
		}

		if ( $ch =~ /[0-9]/ ) {
			my $j = $i;
			my $num = '';
			while ( $j < $n and $c[$j] =~ /[0-9.]/ ) { $num .= $c[$j++]; }
			$push->({ k => 'NUMBER', v => 0 + $num });
			$i = $j;
			next;
		}

		my $name = _read_name( \@c, $i );
		if ( defined $name->{v} and length $name->{v} ) {
			$push->({ k => 'NAME', v => $name->{v} });
			$i = $name->{i};
			next;
		}

		croak "Unexpected character '$ch' at position $i";
	}

	push @t, { k => 'EOF', v => '' };
	return \@t;
}

sub _unescape_char {
	my ( $c ) = @_;
	return "\n" if $c eq 'n';
	return "\r" if $c eq 'r';
	return "\t" if $c eq 't';
	return $c;
}

sub _read_name {
	my ( $chars, $i ) = @_;
	my $n = @$chars;

	my %delim = map { $_ => 1 } split //, "\n\r\t()[]/,=&|!<># ";
	my $buf = '';
	my $esc = 0;

	my $start = $i;
	while ( $i < $n ) {
		my $c = $chars->[$i];

		if ( $esc ) {
			$buf .= $c;
			$esc = 0;
			$i++;
			next;
		}

		if ( $c eq '\\' ) {
			$esc = 1;
			$i++;
			next;
		}

		last if $delim{$c};
		last if $c =~ /\s/;
		$buf .= $c;
		$i++;
	}

	return { v => '', i => $start } unless length $buf;
	return { v => $buf, i => $i };
}

1;
