## no critic
package DBIx::MultiStatementDo;
BEGIN {
  $DBIx::MultiStatementDo::VERSION = '1.00009';
}
## use critic

use Moose;
use Carp qw(croak);

use SQL::SplitStatement 1.00009;

has 'dbh' => (
    is       => 'rw',
    isa      => 'DBI::db',
    required => 1
);

has 'splitter_options' => (
    is      => 'rw',
    isa     => 'Maybe[HashRef[Bool]]',
    trigger => \&_set_splitter,
    default => undef
);

sub _set_splitter {
     my ($self, $new_options) = @_;
     $self->_splitter( SQL::SplitStatement->new($new_options) )
}

has '_splitter' => (
    is      => 'rw',
    isa     => 'SQL::SplitStatement',
    handles => [ qw(split split_with_placeholders) ],
    lazy    => 1,
    default => sub { SQL::SplitStatement->new }
);

has 'rollback' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1
);

sub do {
    my ($self, $code, $attr, @bind_values) = @_;
    
    my ( $statements, $placeholders )
        = ! ref($code)
        ? $self->split_with_placeholders($code)
        : ref( $code->[0] ) eq 'ARRAY'
        ? @$code
        : ( $code, undef );
    
    my @compound_bind_values;
    if ( @bind_values >= 1 ) {
        if ( ! ref $bind_values[0] ) {
            # @bind_values was a FLAT LIST
            ref($placeholders) ne 'ARRAY' and croak(
q[Bind values as a flat list require the placeholder numbers listref to be passed as well]
            );
            push @compound_bind_values, [ splice @bind_values, 0, $_ ]
                foreach @$placeholders
        } else {
            @compound_bind_values = @{ $bind_values[0] }
        }
    }
    
    
    my $dbh = $self->dbh;
    my @results;
    
    if ( $self->rollback ) {
        local $dbh->{AutoCommit} = 0;
        local $dbh->{RaiseError} = 1;
        eval {
            @results = $self->_do_statements(
                $statements, $attr, \@compound_bind_values
            );
            $dbh->commit;
            1
        } or eval {
            $dbh->rollback
        }
    } else {
        @results = $self->_do_statements(
            $statements, $attr, \@compound_bind_values
        )
    }
    
    return @results if wantarray;         # List context.
    return 1 if @results == @$statements; # Scalar context and success.
    return                                # Scalar context and failure.
}

sub _do_statements {
    my ($self, $statements, $attr, $compound_bind_values) = @_;
    
    my @results;
    my $dbh = $self->dbh;
    
    for my $statement ( @$statements ) {
        my $result = $dbh->do(
            $statement, $attr, @{ shift(@$compound_bind_values) || [] }
        );
        last unless $result;
        push @results, $result
    }
    
    return @results
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

DBIx::MultiStatementDo - Multiple SQL statements in a single do() call with any DBI driver

=head1 VERSION

version 1.00009

=head1 SYNOPSIS

    use DBI;
    use DBIx::MultiStatementDo;
    
    # Multiple SQL statements in a single string
    my $sql_code = <<'SQL';
    CREATE TABLE parent (a, b, c   , d    );
    CREATE TABLE child (x, y, "w;", "z;z");
    /* C-style comment; */
    CREATE TRIGGER "check;delete;parent;" BEFORE DELETE ON parent WHEN
        EXISTS (SELECT 1 FROM child WHERE old.a = x AND old.b = y)
    BEGIN
        SELECT RAISE(ABORT, 'constraint failed;'); -- Inlined SQL comment
    END;
    -- Standalone SQL; comment; w/ semicolons;
    INSERT INTO parent (a, b, c, d) VALUES ('pippo;', 'pluto;', NULL, NULL);
    SQL
    
    my $dbh = DBI->connect( 'dbi:SQLite:dbname=my.db', '', '' );
    
    my $batch = DBIx::MultiStatementDo->new( dbh => $dbh );
    
    # Multiple SQL statements in a single call
    my @results = $batch->do( $sql_code )
        or die $batch->dbh->errstr;
    
    print scalar(@results) . ' statements successfully executed!';
    # 4 statements successfully executed!

=head1 DESCRIPTION

Some DBI drivers don't support the execution of multiple statements in a single
C<do()> call. This module tries to overcome such limitation, letting you execute
any number of SQL statements (of any kind, not only DDL statements) in a single
batch, with any DBI driver.

Here is how DBIx::MultiStatementDo works: behind the scenes it parses the SQL
code, splits it into the atomic statements it is composed of and executes them
one by one. To split the SQL code L<SQL::SplitStatement> is used, which uses a
more sophisticated logic than a raw C<split> on the C<;> (semicolon) character:
first, various different statement terminator I<tokens> are recognized, then
L<SQL::SplitStatement> is able to correctly handle the presence of said tokens
inside identifiers, values, comments, C<BEGIN ... END> blocks (even nested),
I<dollar-quoted> strings, MySQL custom C<DELIMITER>s, procedural code etc.,
as (partially) exemplified in the L</SYNOPSIS> above.

Automatic transactions support is offered by default, so that you'll have the
I<all-or-nothing> behaviour you would probably expect; if you prefer, you can
anyway disable it and manage the transactions yourself.

=head1 METHODS

=head2 C<new>

=over 4

=item * C<< DBIx::MultiStatementDo->new( %options ) >>

=item * C<< DBIx::MultiStatementDo->new( \%options ) >>

=back

It creates and returns a new DBIx::MultiStatementDo object. It accepts its
options either as an hash or an hashref.

The following options are recognized:

=over 4

=item * C<dbh>

The database handle object as returned by L<DBI::connect()|DBI/connect>. This
option B<is required>.

=item * C<rollback>

A Boolean option which enables (when true) or disables (when false) automatic
transactions. It is set to a true value by default.

=item * C<splitter_options>

This is the options hashref which is passed unaltered to C<<
SQL::SplitStatement->new() >> to build the I<splitter object>, which is then
internally used by DBIx::MultiStatementDo to split the given SQL string.

It defaults to C<undef>, which should be the best value if the given SQL string
contains only standard SQL. If it contains contains also procedural code, you
may need to fine tune this option.

Please refer to L<< SQL::SplitStatement::new()|SQL::SplitStatement/new >> to see
the options it takes.

=back

=head2 C<do>

=over 4

=item * C<< $batch->do( $sql_string | \@sql_statements ) >>

=item * C<< $batch->do( $sql_string | \@sql_statements , \%attr ) >>

=item * C<< $batch->do( $sql_string | \@sql_statements , \%attr, \@bind_values | @bind_values ) >>

=back

This is the method which actually executes the SQL statements against your db.
As its first (mandatory) argument, it takes an SQL string containing one or more
SQL statements. The SQL string is split into its atomic statements, which are
then executed one-by-one, in the same order they appear in the given string.

The first argument can also be a reference to a list of (already split)
statements, in which case no split is performed and the statements are executed
as they appear in the list. The list can also be a two-elements list, where the
first element is the statements listref as above, and the second is the
I<placeholder numbers> listref, exactly as returned by the
L<< SQL::SplitStatement::split_with_placeholders()|SQL::SplitStatement/split_with_placeholders >>
method.

Analogously to DBI's C<do()>, it optionally also takes an hashref of attributes
(which is passed unaltered to C<< $batch->dbh->do() >> for each atomic
statement), and the I<bind values>, either as a listref or a flat list (see
below for the difference).

In list context, C<do> returns a list containing the values returned by the
C<< $batch->dbh->do() >> call on each single atomic statement.

If the C<rollback> option has been set (and therefore automatic transactions are
enabled), in case one of the atomic statements fails, all the other succeeding
statements executed so far, if any, are rolled back and the method (immediately)
returns an empty list (since no statements have actually been committed).

If the C<rollback> option is set to a false value (and therefore automatic
transactions are disabled), the method immediately returns at the first failing
statement as above, but it does not roll back any prior succeeding statement,
and therefore a list containing the values returned by the statements
(successfully) executed so far is returned (and these statements are actually
committed to the db, if C<< $dbh->{AutoCommit} >> is set).

In scalar context it returns, regardless of the value of the C<rollback> option,
C<undef> if any of the atomic statements failed, or a true value if all of the
atomic statements succeeded.

Note that to activate the automatic transactions you don't have to do anything
more than setting the C<rollback> option to a true value (or simply do nothing,
as it is the default): DBIx::MultiStatementDo will automatically (and
temporarily, via C<local>) set C<< $dbh->{AutoCommit} >> and
C<< $dbh->{RaiseError} >> as needed.
No other DBI db handle attribute is ever touched, so that you can for example
set C<< $dbh->{PrintError} >> and enjoy its effects in case of a failing
statement.

If you want to disable the automatic transactions and manage them by yourself,
you can do something along this:

    my $batch = DBIx::MultiStatementDo->new(
        dbh      => $dbh,
        rollback => 0
    );
    
    my @results;
    
    $batch->dbh->{AutoCommit} = 0;
    $batch->dbh->{RaiseError} = 1;
    eval {
        @results = $batch->do( $sql_string );
        $batch->dbh->commit;
        1
    } or eval {
        $batch->dbh->rollback
    };

=head3 Bind Values as a List Reference

The bind values can be passed as a reference to a list of listrefs, each of
which contains the bind values for the atomic statement it corresponds to. The
bind values I<inner> lists must match the corresponding atomic statements as
returned by the internal I<splitter object>, with C<undef> (or empty listref)
elements where the corresponding atomic statements have no I<placeholders>.

Here is an example:

    # 7 statements (SQLite valid SQL)
    my $sql_code = <<'SQL';
    CREATE TABLE state (id, name);
    INSERT INTO  state (id, name) VALUES (?, ?);
    CREATE TABLE city (id, name, state_id);
    INSERT INTO  city (id, name, state_id) VALUES (?, ?, ?);
    INSERT INTO  city (id, name, state_id) VALUES (?, ?, ?);
    DROP TABLE city;
    DROP TABLE state
    SQL
    
    # Only 5 elements are required in the bind values list
    my $bind_values = [
        undef                  , # or []
        [ 1, 'Nevada' ]        ,
        []                     , # or undef
        [ 1, 'Las Vegas'  , 1 ],
        [ 2, 'Carson City', 1 ]
    ];
    
    my $batch = DBIx::MultiStatementDo->new( dbh => $dbh );
    
    my @results = $batch->do( $sql_code, undef, $bind_values )
        or die $batch->dbh->errstr;

If the last statements have no placeholders, the corresponding C<undef>s don't
need to be present in the bind values list, as shown above.
The bind values list can also have more elements than the number of the atomic
statements, in which case the excess elements will simply be ignored.

=head3 Bind Values as a Flat List

This is a much more powerful feature of C<do>: when it gets the bind values as a
flat list, it automatically assigns them to the corresponding placeholders (no
I<interleaving> C<undef>s are necessary in this case).

In other words, you can regard the given SQL code as a single big statement and
pass the bind values exactly as you would do with the ordinary DBI C<do> method.

For example, given C<$sql_code> from the example above, you could simply do:

    my @bind_values = ( 1, 'Nevada', 1, 'Las Vegas', 1, 2, 'Carson City', 1 );
    
    my @results = $batch->do( $sql_code, undef, @bind_values )
        or die $batch->dbh->errstr;

and get exactly the same result.

=head3 Difference between Bind Values as a List Reference and as a Flat List

If you want to pass the bind values as a flat list as described above, you must
pass the first parameter to C<do> either as a string (so that the internal
splitting is performed) or, if you want to disable the internal splitting, as a
reference to the two-elements list containing both the statements and the
placeholder numbers listrefs (as described above in L<do>).

In other words, you can't pass the bind values as a flat list and pass at the
same time the (already split) statements without the placeholder numbers
listref. To do so, you need to pass the bind values as a list reference instead,
otherwise C<do> throws an exception.

To summarize, bind values as a flat list is easier to use but it suffers from
this subtle limitation, while bind values as a list reference is a little bit
more cumbersome to use, but it has no limitations and can therefore always be
used.

=head3 Recognized Placeholders

The recognized placeholders are:

=over 4

=item * I<question mark> placeholders, represented by the C<?> character;

=item * I<dollar sign numbered> placeholders, represented by the
C<$1, $2, ..., $n> strings;

=item * I<named parameters>, such as C<:foo>, C<:bar>, C<:baz> etc.

=back

=head2 C<dbh>

=over 4

=item * C<< $batch->dbh >>

=item * C<< $batch->dbh( $new_dbh ) >>

Getter/setter method for the C<dbh> option explained above.

=back

=head2 C<rollback>

=over 4

=item * C<< $batch->rollback >>

=item * C<< $batch->rollback( $boolean ) >>

Getter/setter method for the C<rollback> option explained above.

=back

=head2 C<splitter_options>

=over 4

=item * C<< $batch->splitter_options >>

=item * C<< $batch->splitter_options( \%options ) >>

Getter/setter method for the C<splitter_options> option explained above.

=back

=head2 C<split> and C<split_with_placeholders>

=over 4

=item * C<< $batch->split( $sql_code ) >>

=item * C<< $batch->split_with_placeholders( $sql_code ) >>

=back

These are the methods used internally to split the given SQL code.
They call respectively C<split> and C<split_with_placeholders> on a
SQL::SplitStatement instance built with the C<splitter_options>
described above.

Normally they shouldn't be used directly, but they could be useful if
you want to see how your SQL code has been split.

If you want instead to see how your SQL code I<will be> split, that is
before executing C<do>, you can use SQL::SplitStatement by yourself:

    use SQL::SplitStatement;
    my $splitter = SQL::SplitStatement->new( \%splitter_options );
    my @statements = $splitter->split( $sql_code );
    # Now you can check @statements if you want...

and then you can execute your statements preventing C<do> from performing
the splitting again, by passing C<\@statements> to it:

    my $batch = DBIx::MultiStatementDo->new( dbh => $dbh );
    my @results = $batch->do( \@statements ); # This does not perform the splitting again.

B<Warning!> In previous versions, the C<split_with_placeholders> (public) method
documented above did not work, so there is the possibility that someone
used the (private, undocumented) C<_split_with_placeholders> method instead
(which worked correctly).
In this case, please start using the public method (which now works as
advertised), since the private method will be removed in future versions.

=head1 LIMITATIONS

Please look at: L<< SQL::SplitStatement LIMITATIONS|SQL::SplitStatement/LIMITATIONS >>

=head1 DEPENDENCIES

DBIx::MultiStatementDo depends on the following modules:

=over 4

=item * L<SQL::SplitStatement> 0.10000 or newer

=item * L<Moose>

=back

=head1 AUTHOR

Emanuele Zeppieri, C<< <emazep@cpan.org> >>

=head1 BUGS

No known bugs so far.

Please report any bugs or feature requests to
C<bug-dbix-MultiStatementDo at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-MultiStatementDo>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::MultiStatementDo

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-MultiStatementDo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-MultiStatementDo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-MultiStatementDo>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-MultiStatementDo/>

=back

=head1 ACKNOWLEDGEMENTS

Matt S Trout, for having suggested a much more suitable name
for this module.

=head1 SEE ALSO

=over 4

=item * L<SQL::SplitStatement>

=item * L<DBI>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Emanuele Zeppieri.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation, or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut