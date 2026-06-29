package App::Test::Generator::Mutation::BooleanNegation;

use strict;
use warnings;

use parent 'App::Test::Generator::Mutation::Base';
use App::Test::Generator::Mutant;
use PPI;

our $VERSION = '0.41';

=head1 NAME

App::Test::Generator::Mutation::BooleanNegation - Negate boolean return
expressions to expose missing assertion coverage

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
        self => { type => OBJECT, isa => 'App::Test::Generator::Mutation::BooleanNegation' },
        doc  => { type => OBJECT, isa => 'PPI::Document' },
    }

=head4 output

    { type => SCALAR }

=cut

sub applies_to {
	my ($self, $doc) = @_;

	# PPI >= 1.270 classifies return as PPI::Statement::Break rather
	# than PPI::Statement::Return -- scan the whole document for at
	# least one qualifying return statement. This must match the
	# document-level pre-filter contract used by Mutator::generate_mutants
	# (and documented in Mutation::Base) rather than testing a single node,
	# otherwise every call from generate_mutants would see $doc itself,
	# which is never a PPI::Statement::Break, and mutate() would never run.
	my $returns = $doc->find(sub {
		my $node = $_[1];
		return 0 unless $node->isa('PPI::Statement::Break');
		my $first = $node->schild(0) or return 0;
		return $first->content eq 'return';
	}) || [];

	return @{$returns} ? 1 : 0;
}

=head2 mutate

Walk a PPI document and generate one mutant for each return statement
whose expression can be negated. For example, C<return $ok> becomes
C<return !($ok)>.

    my $mutation = App::Test::Generator::Mutation::BooleanNegation->new;
    my $doc      = PPI::Document->new(\$source);
    my @mutants  = $mutation->mutate($doc);

    for my $m (@mutants) {
        print $m->id, ': ', $m->description, "\n";
    }

=head3 Arguments

=over 4

=item * C<$self>

An instance of C<App::Test::Generator::Mutation::BooleanNegation>.

=item * C<$doc>

A L<PPI::Document> object representing the parsed source to mutate.
The document is not modified by this method.

=back

=head3 Returns

A list of L<App::Test::Generator::Mutant> objects, one per qualifying
return statement found in the document. Returns an empty list if no
return statements with expressions are found.

Each mutant carries a C<transform> closure that when called with a
fresh L<PPI::Document> copy will wrap the targeted return expression
in C<!( )>, negating its boolean value.

=head3 Notes

Mutant IDs include both line and column number to ensure uniqueness
when multiple return statements appear on different lines of the same
source file.

Only return statements that have an expression child (i.e. not bare
C<return;> statements) are mutated.

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
            isa  => 'App::Test::Generator::Mutation::BooleanNegation',
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
	# (alongside last/next/redo) rather than PPI::Statement::Return.
	# Use a custom predicate to match only 'return' Break nodes.
	my $returns = $doc->find(sub {
		my $node = $_[1];
		# Must be a Break statement -- the parent class for return in
		# newer PPI versions
		return 0 unless $node->isa('PPI::Statement::Break');
		# Distinguish return from last/next/redo by checking the
		# first significant child token
		my $first = $node->schild(0) or return 0;
		return $first->content eq 'return';
	}) || [];

	my @mutants;

	for my $ret (@{$returns}) {
		# Skip bare return statements with no expression to negate,
		# and bare returns with only a postfix conditional/loop
		# modifier (return if $cond; has nothing to negate)
		my @expr = _return_expr_span($ret);
		next unless @expr;

		# Skip a lone structure node (e.g. return ($x, $y) gives a
		# single PPI::Structure::List child) — wrapping it is not
		# useful and there is nothing simple to splice around
		next if @expr == 1 && !$expr[0]->isa('PPI::Token');

		# Capture location so the transform closure targets the
		# exact statement rather than the first match on that line
		my $line = $ret->location->[0];
		my $col  = $ret->location->[1];

		# Build a unique ID from line and column so multiple return
		# statements in the same file never collide
		my $id = "BOOL_NEGATE_${line}_${col}";

		my $mutant = eval {
			App::Test::Generator::Mutant->new(
				id           => $id,
				group        => "BOOL_NEGATE:$line",
				description  => 'Negate boolean return expression',
				original     => $ret->content,
				line         => $line,
				type         => 'boolean',
				context      => $self->_in_conditional($ret) ? 'conditional' : 'statement',
				line_content => $self->_line_content($doc, $line),

				# The transform closure captures line and col so it
				# targets precisely the right return statement in the
				# document copy it receives at test time
				transform => sub {
					my $doc  = $_[0];

					# Locate all return statements in the fresh document copy using
					# the same PPI::Statement::Break predicate as the outer find --
					# PPI >= 1.270 no longer uses PPI::Statement::Return
					my $rets = $doc->find(sub {
						my $node = $_[1];
						# Match Break nodes only -- covers return/last/next/redo
						return 0 unless $node->isa('PPI::Statement::Break');
						# Filter to return specifically by inspecting the first token
						my $first = $node->schild(0) or return 0;
						return $first->content eq 'return';
					}) || [];

					for my $ret (@{$rets}) {
						# Match by line and column to avoid mutating
						# the wrong return statement
						next unless $ret->line_number   == $line;
						next unless $ret->column_number == $col;

						# Skip bare returns with no expression
						my @expr = _return_expr_span($ret);
						last unless @expr;

						# Skip a lone structure node
						last if @expr == 1 && !$expr[0]->isa('PPI::Token');

						# Wrap the whole expression span in !(...) rather
						# than just its first token -- $self->{x} is three
						# significant children (Symbol, Operator, Structure)
						# and wrapping only the leading $self produced the
						# broken mutant 'return !($self)->{x};'
						$expr[0]->insert_before(PPI::Token::Operator->new('!'));
						$expr[0]->insert_before(PPI::Token::Structure->new('('));
						$expr[-1]->insert_after(PPI::Token::Structure->new(')'));
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

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational,
Government) must apply in writing for a licence for use from Nigel Horne
at the above e-mail.

=back

=cut

1;
