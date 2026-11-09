use v5.36;

package DBIx::Squirrel::Context;

use Exporter qw(import);

use DBIx::Squirrel::Errors qw();
use Ekorn::Pipeline        qw();

our @EXPORT_OK = qw(iterator result_number result_original);

# Croak at the line that called DBIx::Squirrel.
our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;

# The iterator running the stages, set by the iterator while they run.
# What a stage can ask is read from the iterator when it asks, as the
# iterator counts its results and keeps the row it fetched last.
my %context;

# The iterator running the stage.
sub iterator : prototype() () {
    return $context{iterator};
}

# The number of the result being made, from 1.
sub result_number : prototype() () {
    my $iterator = $context{iterator};
    return $iterator && $iterator->{produced} + 1;
}

# The row the result is being made from, as it was fetched; undef for a
# result an end function is making, which comes from every row.
sub result_original : prototype() () {
    my $iterator = $context{iterator};
    return $iterator && !Ekorn::Pipeline::ending()
        ? $iterator->{original}
        : undef;
}

# For DBIx::Squirrel's iterators: run code with the iterator given as the
# one running, and return what it returns.
sub within ($iterator, $code) {
    local $context{iterator} = $iterator;
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

Inside a stage run by a L<DBIx::Squirrel::Iterator>, these functions
return what the stage might want to know about the result it's making,
which it can't work out from the value it's given. Outside a stage,
they return C<undef>. None is exported by default.

=head1 FUNCTIONS

=head2 iterator

The iterator running the stage. Its C<sth> is the statement handle,
and the statement handle's C<Database>, the database handle.

=head2 result_number

The number of the result being made, from 1. It counts results, not
rows: while a stage drops rows, the number stays the same, and each
value a stage returns in place of one row is a result of its own. In an
end function of a stage made with L<DBIx::Squirrel::Gather>, it's the
number of the first value the end returns.

=head2 result_original

The row the result is being made from, as it was fetched, before any
stage changed it. In an end function of a stage made with
L<DBIx::Squirrel::Gather>, and the stages after it, it's C<undef>, as
what an end gives comes from every row.

=head2 within

For DBIx::Squirrel's iterators, which set the context while their
stages run; not for use elsewhere.

=head1 SEE ALSO

L<DBIx::Squirrel::Iterator>, L<DBIx::Squirrel::Pipeline>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
