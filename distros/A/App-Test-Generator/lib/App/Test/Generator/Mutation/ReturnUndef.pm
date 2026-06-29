package App::Test::Generator::Mutation::ReturnUndef;

use strict;
use warnings;
use parent 'App::Test::Generator::Mutation::Base';
use App::Test::Generator::Mutant;
use PPI;

our $VERSION = '0.41';

=head1 NAME

App::Test::Generator::Mutation::ReturnUndef - Replace return expressions
with undef to expose missing undef-return checks in the test suite

=head1 VERSION

Version 0.41

=head1 METHODS

=head2 applies_to

Return true if the given document contains at least one return
statement this mutation strategy could mutate. Used by
L<App::Test::Generator::Mutator> to pre-filter strategies before
calling C<mutate>, so a document with nothing to mutate skips the
walk entirely.

    my $applies = $mutation->applies_to($doc);

=head3 Arguments

=over 4

=item * C<$doc>

A L<PPI::Document> object to inspect.

=back

=head3 Returns

True if the document contains a C<return> statement (PPI::Statement::Break
whose first token is C<return>), false otherwise.

=head3 API specification

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::Mutation::ReturnUndef' },
        doc  => { type => OBJECT, isa => 'PPI::Document' },
    }

=head4 output

    { type => SCALAR }

=cut

sub applies_to {
	my ($self, $doc) = @_;

	# PPI >= 1.270 classifies return as PPI::Statement::Break rather
	# than the dedicated PPI::Statement::Return class -- scan the whole
	# document for at least one qualifying return statement. This must
	# match the document-level pre-filter contract used by
	# Mutator::generate_mutants (and documented in Mutation::Base) rather
	# than testing a single node, otherwise every call from
	# generate_mutants would see $doc itself, which is never a
	# PPI::Statement::Break, and mutate() would never run.
	my $returns = $doc->find(sub {
		my $node = $_[1];
		return 0 unless $node->isa('PPI::Statement::Break');
		my $first = $node->schild(0) or return 0;
		return $first->content eq 'return';
	}) || [];

	return @{$returns} ? 1 : 0;
}

=head2 mutate

Walk a PPI document and generate one mutant for each non-bare return
statement, replacing its expression with C<undef>. For example,
C<return $result> becomes C<return undef>.

Bare C<return;> statements are skipped because they already return
undef - mutating them would produce a redundant mutant that can never
be killed.

    my $mutation = App::Test::Generator::Mutation::ReturnUndef->new;
    my $doc      = PPI::Document->new(\$source);
    my @mutants  = $mutation->mutate($doc);

    for my $m (@mutants) {
        print $m->id, ': ', $m->description, "\n";
    }

=head3 Arguments

=over 4

=item * C<$self>

An instance of C<App::Test::Generator::Mutation::ReturnUndef>.

=item * C<$doc>

A L<PPI::Document> object representing the parsed source to mutate.
The document is not modified by this method.

=back

=head3 Returns

A list of L<App::Test::Generator::Mutant> objects, one per qualifying
return statement found in the document. Returns an empty list if no
non-bare return statements are found.

Each mutant carries a C<transform> closure that when called with a
fresh L<PPI::Document> copy will replace the targeted return expression
with the literal C<undef>.

=head3 Notes

Mutant IDs include both line and column number to ensure uniqueness
when multiple return statements appear in the same source file.

Only return statements with an expression child are mutated - bare
C<return;> statements are skipped as they already return undef.

Each mutant's optional C<context> field is set to C<conditional> if
the return statement sits inside (or is itself the keyword of) an
C<if>/C<unless>/C<while>/C<until> compound statement, or C<statement>
otherwise; its C<line_content> field holds the raw source text of the
mutated line. Both are consumed by
L<App::Test::Generator::Mutator>'s fast-mode dedup.

=head3 API specification

=head4 input

    {
        self => {
            type => OBJECT,
            isa  => 'App::Test::Generator::Mutation::ReturnUndef',
        },
        doc => {
            type => OBJECT,
            isa  => 'PPI::Document',
        },
    }

=head4 output

    {
        type     => ARRAYREF,
        elements => {
            type => OBJECT,
            isa  => 'App::Test::Generator::Mutant',
        },
    }

=cut

sub mutate {
	my ($self, $doc) = @_;

	# PPI >= 1.270 classifies return statements as PPI::Statement::Break
	# rather than PPI::Statement::Return -- use a custom predicate
	my $returns = $doc->find(sub {
		my $node = $_[1];
		# Match Break nodes that are specifically return statements
		return 0 unless $node->isa('PPI::Statement::Break');
		my $first = $node->schild(0) or return 0;
		return $first->content eq 'return';
	}) || [];

	my @mutants;

	for my $ret (@{$returns}) {
		# Skip bare return statements — they already return undef
		# so mutating them would produce a redundant mutant that
		# can never be killed by any meaningful test. Also skips
		# bare returns with only a postfix conditional/loop modifier.
		my @expr = _return_expr_span($ret);
		next unless @expr;

		# Skip a lone structure node (e.g. return ($x, $y) gives a
		# single PPI::Structure::List child) — nothing simple to splice
		next if @expr == 1 && !$expr[0]->isa('PPI::Token');

		# Capture location so the transform closure targets the
		# exact statement rather than the first match on that line
		my $line = $ret->location->[0];
		my $col  = $ret->location->[1];

		# Build a unique ID from line and column so multiple return
		# statements in the same file never collide
		my $id = "RETURN_UNDEF_${line}_${col}";

		my $mutant = eval {
			App::Test::Generator::Mutant->new(
				id           => $id,
				group        => "RETURN_UNDEF:$line",
				description  => 'Replace return expression with undef',
				original     => $ret->content(),
				line         => $line,
				type         => 'return',
				context      => $self->_in_conditional($ret) ? 'conditional' : 'statement',
				line_content => $self->_line_content($doc, $line),

				# The transform closure captures line and col so it
				# targets precisely the right return statement in the
				# document copy it receives at test time
				transform => sub {
					my $doc  = $_[0];
					# PPI >= 1.270 uses PPI::Statement::Break for return
					my $rets = $doc->find(sub {
						my $node = $_[1];
						return 0 unless $node->isa('PPI::Statement::Break');
						my $first = $node->schild(0) or return 0;
						return $first->content eq 'return';
						}) || [];
					for my $ret (@{$rets}) {
						next unless $ret->line_number   == $line;
						next unless $ret->column_number == $col;

						my @expr = _return_expr_span($ret);
						last unless @expr;
						last if @expr == 1 && !$expr[0]->isa('PPI::Token');

						# Replace the whole expression span with a single
						# 'undef' token rather than just its first token --
						# $self->{x} is three significant children (Symbol,
						# Operator, Structure) and replacing only the
						# leading $self produced the broken mutant
						# 'return undef->{x};'
						$expr[0]->insert_before(PPI::Token::Word->new('undef'));
						$_->remove for @expr;
						last;
					}
				},
			);
		};

		# If the Mutant construction fails, report clearly rather than
		# silently dropping the mutant from the results
		if($@ || !$mutant) {
			warn "Failed to construct mutant $id: $@" if $@;
			next;
		}

		push @mutants, $mutant;
	}

	return @mutants;
}

# --------------------------------------------------
# Purpose: identify the PPI elements making up the expression
#          being returned by a 'return' statement, excluding
#          the leading 'return' keyword, the trailing statement
#          terminator, and any postfix conditional/loop modifier
#          (if/unless/while/until/for/foreach) and its condition.
# Entry:   a PPI::Statement::Break node already confirmed to be
#          a 'return' statement.
# Exit:    a list of the significant child elements making up
#          the return expression, or an empty list for a bare
#          return (with or without a postfix modifier).
# Side effects: none.
# --------------------------------------------------
sub _return_expr_span {
	my ($ret) = @_;

	my @children = $ret->schildren;
	shift @children;

	if(@children && $children[-1]->isa('PPI::Token::Structure') && $children[-1]->content eq ';') {
		pop @children;
	}

	for my $i (0 .. $#children) {
		my $child = $children[$i];
		next unless $child->isa('PPI::Token::Word');
		next unless $child->content =~ /^(?:if|unless|while|until|for|foreach)$/;
		@children = @children[0 .. $i - 1];
		last;
	}

	return @children;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the terms of GPL2.
If you use it,
please let me know.

=cut

1;
