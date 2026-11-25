use v5.36;

package DBIx::Squirrel::Context;

use Exporter  qw(import);
use Ref::Util qw(is_plain_hashref);

use DBIx::Squirrel::Errors   qw();
use Ekorn::Pipeline          qw();
use Ekorn::Pipeline::Context qw();

use namespace::clean -except => 'import';

our @EXPORT_OK = qw(iterator result_number result_original);

# Croak at the line that called DBIx::Squirrel.
our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;

# The iterator running the stages, set by the iterator while they run; a
# package variable, so the iterator's next can localise it itself,
# without a call for each row.
our $ITERATOR;

# The iterator running the stage.
sub iterator : prototype() () {
    return $ITERATOR;
}

# The number of the result being made, from 1: Ekorn's own sub, under our
# name, as every run counts its results (roadmap 2026-0032, D1), so a
# stage reading it pays for one call, not two. Ekorn's has an empty
# prototype from v0.3.12, as ours always had, so result_number + 1 adds
# one.
*result_number = \&Ekorn::Pipeline::Context::result_number;

# The row the result is being made from, as it was fetched; undef for a
# result a flush is making, which comes from every row: Ekorn's own sub,
# under our name, as our statement source gives Ekorn the row as its
# original part, which Ekorn passes through chains (roadmap 2026-0046).
# Outside a run reading a statement, it's the value the run's source
# gave (roadmap 2026-0032, D2).
*result_original = \&Ekorn::Pipeline::Context::result_original;

# For DBIx::Squirrel's stages: the context of the run, if its source is a
# statement, with its columns and the row it gave last; otherwise undef.
sub statement_context : prototype() () {
    my $run = Ekorn::Pipeline::run_context();
    return is_plain_hashref($run)
        && $run->{statement} isa 'DBIx::Squirrel::st'
        ? $run
        : undef;
}

# For DBIx::Squirrel's iterators: run code with the iterator given as the
# one running, and return what it returns.
sub within ($iterator, $code) {
    local $ITERATOR = $iterator;
    return $code->();
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Context - what a stage can ask about the result it's making

=head1 SYNOPSIS

    use DBIx::Squirrel::Context qw(result_number result_original);

    my $it = $dbh->iterate(
        'SELECT name FROM artist ORDER BY name',
        sub ($row) { "@{[ result_number ]}. $row->[0]" },
    );

=head1 DESCRIPTION

Inside a stage, these functions tell the stage about the result it's
making: things it can't work out from the value it's given.
L</result_number> works in any run: Ekorn::Pipeline counts every run's
results, and these are its numbers. L</result_original> gives a
statement's row in any run reading one: an iterator's own stages, and
those of a chain made with C<|>, or of a pipeline of yours, reading
one; in any other run, the value its source gave, or that was pushed,
as L<Ekorn::Pipeline::Context> has it. L</iterator> works only in an
iterator's own stages, run by its C<next>, C<all>, C<first> or
C<single>, and gives C<undef> elsewhere; outside a run, all three
do. None is exported by default.

=head1 FUNCTIONS

=head2 iterator

The iterator running the stage, in its own stages. Its C<sth> is the
statement handle, and the statement handle's C<Database> is the
database handle.

=head2 result_number

The number of the result being made, from 1. It counts results, not
rows. While a stage drops rows, the number stays the same. Each value
a stage returns in place of one row is a result of its own. In a flush
of a stage made with L<DBIx::Squirrel::Gather>, it's the number of the
first value the flush returns. A sink's step sees the number of the
value it's given. Every run counts its own results, so a pipeline run
inside a stage counts from 1, and leaves the count of the run around
it as it was. It's L<Ekorn::Pipeline::Context>'s, with an empty
prototype, so C<result_number + 1> adds one.

=head2 result_original

The row the result is being made from, as it was fetched, before any
stage changed it. In a flush of a stage made with
L<DBIx::Squirrel::Gather>, and the stages after it, it's C<undef>.
What a flush gives comes from every row, not one. It's
L<Ekorn::Pipeline::Context>'s, with an empty prototype: the
statement's source gives Ekorn the row as its original, and Ekorn
passes it through chains, so it's there wherever a statement is read.
In a run that reads no statement, it's the value the run's source
gave, or that was pushed.

=head2 statement_context

For DBIx::Squirrel's stages, which read a statement's columns from the
run they're in. It's not for use elsewhere.

=head2 within

For DBIx::Squirrel's iterators, which set the context while their
stages run. It's not for use elsewhere.

=head1 SEE ALSO

L<DBIx::Squirrel::Iterator>, L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Context>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
