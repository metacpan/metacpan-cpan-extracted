use v5.36;

package DBIx::Squirrel::Iterator;

use experimental qw(builtin);

use builtin qw(weaken);

use Ref::Util qw(is_plain_arrayref);

use DBIx::Squirrel::Context  qw();
use DBIx::Squirrel::Errors   qw(at_caller croakf);
use DBIx::Squirrel::Pipeline qw();
use DBIx::Squirrel::Util     qw(iterator_going split_stages);

use namespace::clean;

# Croak at the line that called DBIx::Squirrel.
our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;

# How many rows are fetched at a time.
my $BATCH_SIZE = 100;

# Return a new iterator over the rows of a statement handle, executed with
# the bind values given, and run through the stages given after them.
sub new ($class, $sth, @args) {
    croakf 'Expected a statement handle'
        unless $sth isa 'DBIx::Squirrel::st';
    my @stages = split_stages(\@args);
    return bless {
        sth                 => $sth,
        bind_values_initial => \@args,
        stages_initial      => \@stages,
    }, $class;
}

# Return the next result, or nothing when there are no more, executing the
# statement first if it hasn't been.
sub next ($self) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    _executed($self);
    return _take($self);
}

# Return the results not yet fetched, or, in scalar context, how many
# there were.
sub all ($self) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    _executed($self);
    my @results;
    DBIx::Squirrel::Context::within($self, sub { _drain($self, \@results) })
        unless $self->{done};
    $self->{count} += @results;
    _finish($self);
    return @results;
}

# Execute the statement again, and return its one result, or nothing if
# it has none, croaking if it has more than one.
sub single ($self) {
    $self->reset;
    my($result) = _take($self) or return;
    my @more = _take($self);
    _finish($self);
    croakf 'Expected one result, not more' if @more;
    return $result;
}

# Execute the statement again, ready to iterate from its first row, and
# return the iterator. Bind values given replace those given before;
# stages given are added to those given to new. Both are kept until
# others are given. A statement with list placeholders is prepared again,
# on a new statement handle, if a list has a different number of values.
sub reset ($self, @args) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my $sth   = $self->{sth};
    my $state = $sth->{private_ekorn};
    my $other = iterator_going($sth);
    croakf "Expected the statement handle's other iterator to be finished"
        if $other && $other != $self;

    my @stages = split_stages(\@args);
    $self->{stages}        = [@{ $self->{stages_initial} }, @stages] if @stages;
    $self->{stages}      //= [@{ $self->{stages_initial} }];
    $self->{bind_values}   = \@args if @args;
    $self->{bind_values} //= [@{ $self->{bind_values_initial} }];

    $sth->finish if $sth->{Active};
    if ($state->{Lists}) {
        my $again = DBIx::Squirrel::db::_prepare_again(    ## no critic (Subroutines::ProtectPrivateSubs)
            $sth->{Database}, $sth, @{ $self->{bind_values} },
        );
        if ($again != $sth) {
            delete $state->{Iterator};
            ($sth, $state) = ($self->{sth} = $again, $again->{private_ekorn});
        }
    }
    $state->{Iterator} = $self;
    weaken $state->{Iterator};
    # An empty array slice fetches every column, as no slice does, but the
    # DBI takes its slower way given one, so it's given none.
    my $slice = $self->_slice;
    $slice = undef if is_plain_arrayref($slice) && !@$slice;
    my %fresh = (
        executed     => 1,
        done         => 0,
        buffer       => [],
        count        => 0,
        produced     => 0,
        original     => undef,
        column_names => [],
        slice        => $slice,
    );
    @$self{keys %fresh} = values %fresh;
    $self->{done} = 1
        unless defined $sth->execute(@{ $self->{bind_values} });
    # The names are read now, before a row is fetched: once the last row
    # is, DBD::mysql gives none, unless they were read before.
    unless ($self->{done}) {
        my $key = $sth->{FetchHashKeyName} || 'NAME';
        $self->{column_names}
            = at_caller { $sth->{NUM_OF_FIELDS} ? [@{ $sth->{$key} }] : [] };
    }
    # Without stages, the rows are the results, straight from the source.
    my $source = _source($self);
    $self->{next}
        = @{ $self->{stages} }
        ? DBIx::Squirrel::Pipeline->new(@{ $self->{stages} })->iterator($source)
        : $source;
    return $self;
}

# Return the number of results fetched so far.
sub count ($self) {
    return $self->{count} // 0;
}

# Return the names of the statement's columns, as fetchrow_hashref keys
# them, executing the statement first if it hasn't been.
sub column_names ($self) {
    _executed($self);
    return @{ $self->{column_names} // [] };
}


sub sth ($self) {
    return $self->{sth};
}

# Execute the statement, unless it's been executed.
sub _executed ($self) {
    $self->reset unless $self->{executed};
    return;
}

# Run the stages until the next result comes out of them, and return it
# as a list of one, or an empty list when there are no more.
sub _take ($self) {
    return if $self->{done};
    my @result = DBIx::Squirrel::Context::within($self, $self->{next});
    unless (@result) {
        _finish($self);
        return;
    }
    $self->{produced}++;
    $self->{count}++;
    return $result[0];
}

# Run the stages until no more results come out of them, adding each to
# the results given, and counting it as it's made, for
# DBIx::Squirrel::Context.
sub _drain ($self, $results) {
    return _rest($self, $results) unless @{ $self->{stages} };
    my $next = $self->{next};
    while (my($result) = $next->()) {
        push @$results, $result;
        $self->{produced}++;
    }
    return;
}

# Without stages, the rows are the results: add what's left of the batch
# fetched last, and the rest of the rows, fetched at once, to the results
# given, rather than one at a time from the source. A subclass's _row
# makes something of each, as the source does.
sub _rest ($self, $results) {
    my $sth   = $self->{sth};
    my $first = @$results;
    push @$results, splice @{ $self->{buffer} };
    my $rows = at_caller {
        $sth->{Active} && $sth->{NUM_OF_FIELDS}
            ? $sth->fetchall_arrayref($self->{slice})
            : undef;
    };
    push @$results, @$rows if $rows;
    return if @$results == $first;
    if (my $row = $self->can('_row')) {
        $_ = $self->$row($_) for @$results[$first .. $#$results];
    }
    $self->{produced} += @$results - $first;
    $self->{original}  = $results->[-1];
    return;
}

# Stop iterating, and finish the statement.
sub _finish ($self) {
    @$self{qw(done buffer)} = (1, []);
    $self->{sth}->finish if $self->{sth}{Active};
    return;
}

# Return a source for the pipeline: a closure returning the statement's
# next row, fetched a batch at a time, or nothing. It keeps the row as
# the original, for DBIx::Squirrel::Context. A subclass can make
# something else of each row, before the stages see it, with a _row
# method of its own, as DBIx::Squirrel::Results does.
sub _source ($self) {
    my $row = $self->can('_row');
    weaken $self;
    return sub () {
        my $buffer = $self->{buffer};
        unless (@$buffer) {
            my $sth  = $self->{sth};
            my $rows = at_caller {
                $sth->{Active} && $sth->{NUM_OF_FIELDS}
                    ? $sth->fetchall_arrayref($self->{slice}, $BATCH_SIZE)
                    : undef;
            };
            return unless $rows && @$rows;
            $self->{buffer} = $buffer = $rows;
        }
        my $original = shift @$buffer;
        $original = $self->$row($original) if $row;
        return $self->{original} = $original;
    };
}

# Return the slice rows are fetched as: the ekorn_slice attribute, or
# arrays; a subclass can choose its own.
sub _slice ($self) {
    return $self->{sth}{private_ekorn}{Options}{ekorn_slice} // [];
}

1;
__END__

=encoding utf8

=for stopwords sth

=head1 NAME

DBIx::Squirrel::Iterator - an iterator over a statement's results

=head1 SYNOPSIS

    my $it = $dbh->iterate(
        'SELECT id, name FROM artist WHERE name LIKE :pattern',
        pattern => 'A%',
        sub ($row) { $row->[1] },
    );
    while (my($name) = $it->next) {
        say $name;
    }

    # A stage can leave its signature out, and use $_
    my @names = $dbh->iterate('SELECT id, name FROM artist', sub { $_->[1] })->all;

    my $sth = $dbh->prepare(
        'SELECT * FROM artist WHERE id = $1',
        {ekorn_slice => {}},
    );
    my $artist = $sth->iterate(42)->single;

=head1 DESCRIPTION

An iterator executes a statement and hands out its rows one at a time,
each run through a pipeline of stages, as L<DBIx::Squirrel::Pipeline>
runs them: a stage can change a row, drop it, return several values in
its place, or stop the iteration with L<DBIx::Squirrel::Stop>. A result
is whatever comes out of the stages; with none, it's the row. A stage
can ask about the result it's making with L<DBIx::Squirrel::Context>.

An iterator is made by L<DBIx::Squirrel::db/iterate> or
L<DBIx::Squirrel::st/iterate>. It executes the statement when its first
result is asked for, and finishes the statement when the results run
out.

Rows are fetched 100 at a time, with L<DBI/fetchall_arrayref>, or, by
L</all> without stages, all at once; each as an array, or, with the
C<ekorn_slice> attribute, in the shape it gives:

    $dbh = DBIx::Squirrel->connect($dsn, $user, $pass, {ekorn_slice => {}});
    $sth = $dbh->prepare($statement, {ekorn_slice => {}});

C<ekorn_slice> is a slice as L<DBI/fetchall_arrayref> takes it: an
array reference, for rows as arrays, or a hash reference, for rows as
hashes. Given to C<connect>, it's the default for each statement the
handle prepares; given to C<prepare>, it's for that statement.

One statement handle can have one iterator going through its results
at a time.

=head1 METHODS

=head2 new

    $it = DBIx::Squirrel::Iterator->new($sth, @bind_values, @stages);

Returns an iterator over the rows of C<$sth>, a L<DBIx::Squirrel::st>,
executed with C<@bind_values>, in any form L<DBIx::Squirrel::st/execute>
takes, and run through C<@stages>, the code references at the end of the
arguments. It doesn't execute the statement.

=head2 next

    while (my($result) = $it->next) { ... }

Returns the next result, or an empty list when there are no more. A
stage can return C<undef> as a result, so read C<next> in list context,
as above, rather than testing whether what it returns is defined.

Once a stage dies, the iterator has ended: C<next> returns an empty
list on every call after, C<all> nothing, and the statement is
finished. L</reset> runs it again, from the start.

=head2 all

    @results = $it->all;
    $count   = $it->all;

Returns the results not yet fetched, or, in scalar context, how many
there were. Either way, they're fetched, and C<next> returns nothing
after.

Without stages, the rows are the results, so C<all> takes what's left
of the batch fetched last, and fetches the rest with one
C<fetchall_arrayref>, nearly as quickly as the DBI's own
C<selectall_arrayref>. With stages, each row goes through them in turn,
which costs a little for each row. So to change every row of a large
result, when nothing needs to stop early, C<map> over C<all> is
quicker than a stage:

    my @names = map { $_->[0] } $dbh->iterate('SELECT name FROM artist')->all;

Stages are for when the rows should come one at a time, from C<next>,
or may stop early, or should go with the statement, as in a Sugar
statement.

=head2 single

    $result = $it->single;

Executes the statement again, and returns its one result, or nothing if
it has none. It croaks if there's more than one. Either way, it's done:
C<next> returns nothing after.

=head2 reset

    $it = $it->reset;
    $it = $it->reset(@bind_values, @stages);

Executes the statement again, ready to iterate from its first row,
finishing it first if it's still active, and returns the iterator. Bind
values given replace those given before. Stages given are added to those
given to L</new>. Both are kept until others are given.

A statement taking a list, as L<DBIx::Squirrel::st/Lists> describes, is
prepared again, on a new statement handle, if a list given has a
different number of values from the one before; L</sth> then returns
the new handle.

=head2 count

    $n = $it->count;

Returns the number of results fetched so far.

=head2 column_names

    @names = $it->column_names;

Returns the names of the statement's columns, as C<fetchrow_hashref>
would key them, following the C<FetchHashKeyName> attribute, executing
the statement first if it hasn't been. They're read when it's executed,
as some drivers, such as DBD::mysql, give none once the last row is
fetched. A statement without columns has none, as does one that
couldn't be executed. A stage can ask for them through
L<DBIx::Squirrel::Context/iterator>.

=head2 sth

    $sth = $it->sth;

Returns the statement handle, which changes if L</reset> prepares a
statement taking a list again.

=head1 DIAGNOSTICS

=over

=item Expected a statement handle

L</new> wasn't given a L<DBIx::Squirrel::st>.

=item Expected one result, not more

L</single> found a second result.

=item Expected the statement handle's other iterator to be finished

The iterator's statement handle has another iterator, which has
results left to hand out. Read that one to the end, or let it go out of
scope, before executing this one.

=back

=head1 SEE ALSO

L<DBIx::Squirrel>, L<DBIx::Squirrel::Context>,
L<DBIx::Squirrel::Pipeline>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
