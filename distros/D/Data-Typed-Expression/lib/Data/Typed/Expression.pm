package Data::Typed::Expression;

use Parse::RecDescent;
use Carp 'croak';

use warnings;
use strict;

=head1 NAME

Data::Typed::Expression - Parsing typed expressions

=head1 VERSION

Version 0.005

=cut

our $VERSION = '0.005';

=head1 SYNOPSIS

  use Data::Typed::Expression;
  use Data::Typed::Expression::Env;
  
  my $env = Data::Typed::Expression::Env->new({
      vertex => {
          id  => 'int',
          lon => 'double',
          lat => 'double'
      },
      arc => {
          from => 'vertex',
          to   => 'vertex',
          cost => 'double'
      },
      graph => {
          arcs     => 'arc[]',
          vertices => 'vertex[]'
      },
      'int' => undef, 'double' => undef
  }, {
      G => 'graph',
      i => 'int'
  });
  my $expr = Data::Typed::Expression->new('G.arcs[G.v[i]+1]');
  
  $env->validate($expr);
                                                                    
=head1 DESCRIPTION

When I was writing a LaTeX paper on mathematical model of an optimization
problem, I was in a need to use C-like expressions to illustrate ideas I was
writing about. I felt really uncomfortable beacuse I couldn't easily validate
the expressions I was using. Hence this module.

The module can parse standard C expressions (or rather a small subset of them)
and validate them in the context of some types. Validation step checks if the
types of values on which artihmetics is performed are numeric, whether array
indices are of C<int> type and if compund types (C<struct>-s) have components
referenced by the expression.

The idea was born on this Perlmonks thread: L<http://perlmonks.org/?node_id=807424>.

=head1 METHODS

=cut


=head2 new

Creates a new expression object. The only argument is a string containing
expression to be parsed.

The method dies if the expression can't be parsed (i.e. is invalid or to
complicated).

Usefulness of an object itself is limited. Pass the object to e.g.
L<Data::Typed::Expression::Env> to check type correctness of the expression.

=cut

sub new {
	my ($class, $str) = @_;
	my $ast = _make_ast($str);
	my $self = {
		ast => $ast
	};
	return bless $self, $class;
}

sub _make_ast {
	my ($expr) = @_;
	my $grammar = <<'EOT';

{
sub _op {
	if (@_ == 1) {
		return { op => $_[0] };
	} elsif (@_ == 2) {
		return { op => $_[0], arg => $_[1] };
	} else {
		return { op => $_[0], arg => [ @_[1..$#_] ] };
	}
}
sub _make_dot_ast {
	my @it = @_;
	my $tr = shift @it;
	
	for my $e (@it) {
		my $op = $e->{op};
		if ($op =~ /^[VID]$/) {
			$tr = _op '.', $tr, $e;
		} elsif ($op eq '[]') {
			my $tr2 = _op '.', $tr, $e->{arg}[0];
			$e->{arg}[0] = $tr2;
			$tr = $e;
		} else {
			die "Unknown op: $op";
		}
	}
	
	$tr;
}
}

expression: full_expr /\z/ { $item[-2] }

full_expr:
	  expr_part expr_sep full_expr { _op $item[-2], $item[-3], $item[-1] }
	| expr_part

expr_part:
	expr_noadd(s /\./) { _make_dot_ast(@{$item[1]}) }

expr_noadd:
	  '(' full_expr ')' { $item[-2] }
	| indexed_expr
	| var_name
	| const

expr_sep: m{[-+*/]}

indexed_expr: var_name indices { _op '[]', $item[-2], @{$item[-1]} }

indices: index(s)

index: '[' full_expr ']' { $item[-2] }

var_name: /[a-zA-Z_][a-zA-Z_0-9]*/ { _op 'V', $item[-1] }

const: int | double

int: /(\+|-)?\d+(?![\.0-9])/ { _op 'I', $item[-1] }

double: /(\+|-)?\d+(\.\d+)?/ { _op 'D', $item[-1] }

EOT

	my $parser = Parse::RecDescent->new($grammar) or croak "Bad grammar: $!";
	my $ast = $parser->expression($expr);
	defined $ast or croak "Unparseable text: $expr\n";
	$ast;
}

1;

