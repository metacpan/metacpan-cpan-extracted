package DBIx::DoMore;

use warnings;
use strict;

use Moose;

use SQL::Tokenizer 'tokenize_sql';

our $VERSION = '0.01003';
$VERSION = eval $VERSION;

has 'dbh' => (
    is       => 'rw',
    isa      => 'DBI::db',
    required => 1
);

has 'rollback' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1
);

sub do {
    my ($self, $code) = @_;
    
    my @statements = $self->split($code);
    my $dbh = $self->dbh;
    my @results;

    if ( $self->rollback ) {
        local $dbh->{AutoCommit} = 0;
        local $dbh->{RaiseError} = 1;
        eval {
            @results = $self->_do_statements(\@statements);
            $dbh->commit;
            1
        } or eval { $dbh->rollback }
    } else {
        @results = $self->_do_statements(\@statements)
    }
    
    return @results if wantarray;
    # Scalar context and failure.
    return unless @results == @statements;
    # Scalar context and success.
    return 1
}

sub _do_statements {
    my ($self, $statements) = @_;
    
    my @results;
    for my $statement ( @{ $statements } ) {
        my $result = $self->dbh->do($statement);
        last unless $result;
        push @results, $result
    }
    
    return @results
}

sub split {
    my ($self, $code) = @_;
    
    my @tokens = tokenize_sql($code);
    my @statements;
    my $statement = '';
    foreach ( @tokens ) {
        $statement .= $_;
        next if /^BEGIN$/i .. /^END$/i or $_ ne ';';
        push @statements, $statement;
        $statement = ''
    }
    push @statements, $statement if $statement =~ /\S+/;
    return @statements
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

DBIx::DoMore - (**DEPRECATED** use DBIx::MultiStatementDo instead) Multiple SQL statements in a single do() call with any DBI driver

=head1 VERSION

Version 0.01003

=head1 SYNOPSIS

    use DBI;
    use DBIx::DoMore;
    
    my $create = <<'SQL';
    CREATE TABLE parent(a, b, c   , d    );
    CREATE TABLE child (x, y, "w;", "z;z");
    CREATE TRIGGER "check;delete;parent;" BEFORE DELETE ON parent WHEN
        EXISTS (SELECT 1 FROM child WHERE old.a = x AND old.b = y)
    BEGIN
        SELECT RAISE(ABORT, 'constraint failed;');
    END;
    INSERT INTO parent (a, b, c, d) VALUES ('pippo;', 'pluto;', NULL, NULL)
    SQL
    
    my $dbh = DBI->connect( 'dbi:SQLite:dbname=my.db', '', '' );
    
    my $batch = DBIx::DoMore->new( dbh => $dbh );
    
    # Multiple SQL statements in a single call
    my @results = $batch->do( $create );
    
    print scalar(@results) . ' statements successfully executed!';
    # 4 statements successfully executed!

=head1 WARNING

This module has been DEPRECATED.
For new development, please use L<DBIx::MultiStatementDo> instead.

=head1 DESCRIPTION

Some DBI drivers don't support the execution of multiple statements in a single
C<do()> call.
This module tries to overcome such limitation, letting you execute any number of
SQL statements (of any kind, not only DDL statements) in a single batch,
with any DBI driver.

Here is how DBIx::DoMore works: behind the scenes it parses the SQL code,
splits it into the atomic statements it is composed of and executes
them one by one.
The logic used to split the SQL code is more sophisticated than a raw
C<split> on the C<;> (semicolon) character, so that DBIx::DoMore is
able to correctly handle the presence of the semicolon inside identifiers,
values or C<BEGIN..END> blocks, as shown in the synopsis above.

Automatic transactions support is offered by default, so that you'll
have the I<all-or-nothing> behaviour you would probably expect; if you prefer,
you can anyway disable it and manage the transactions yourself.

=head1 METHODS

=head2 C<new>

=over 4

=item * C<< DBIx::DoMore->new( %options ) >>

=item * C<< DBIx::DoMore->new( \%options ) >>

=back

It creates and returns a new DBIx::DoMore object.
It accepts its options either as an hash or an hashref.

The following options are recognized:

=over 4

=item * C<dbh>

The database handle object as returned by
L<DBI::connect()|DBI/connect>.
This option B<is required>.

=item * C<rollback>

A boolean option which enables (when true) or disables (when false)
automatic transactions. It is set to a true value by default.

=back

=head2 C<do>

=over 4

=item * C<< $batch->do( $sql_string ) >>

=back

This is the method which actually executes the SQL statements against your db.
It takes a string containing one or more SQL statements and executes them
one by one, in the same order they appear in the given SQL string.

In list context, it returns a list containing the values returned by the DBI
C<do> call on each single atomic statement.

If the C<rollback> option has been set (and therefore automatic transactions
are enabled), in case one of the atomic statements fails, all of the other
succeeding statements executed so far, if any exists, are rolled back and the
method (immediately) returns an empty list (since no statement has been actually
committed).

If the C<rollback> option is set to a false value (and therefore automatic
transactions are disabled), the method immediately returns at the first failing
statement as above, but it does not roll back any prior succeeding statement,
and therefore a list containing the values returned by the statement executed
so far is returned (and these statements are actually committed to the db, if 
C<< $dbh->{AutoCommit} >> is set).

In scalar context it returns, regardless of the value of the C<rollback> option,
C<undef> if any of the atomic statements fails, or a true value if all
of the atomic statements succeed.

Note that to activate the automatic transactions you don't have to do anything
other than setting the C<rollback> option to a true value
(or simply do nothing, as it is the default):
DBIx::DoMore will automatically (and temporarily, via C<local>) set
C<< $dbh->{AutoCommit} >> and  C<< $dbh->{RaiseError} >> as needed.
No other database handle attribute is touched, so that you can for example
set C<< $dbh->{PrintError} >> and enjoy its effect in case of a failing
statement.

If you want to disable automatic transactions and manage them by yourself,
you can do something along this:

    my $batch = DBIx::DoMore->new(
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
    } or eval { $batch->dbh->rollback };

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

=head2 C<split>

=over 4

=item * C<< DBIx::DoMore->split( $sql_string ) >>

=back

This is the method used internally to split the given SQL string into its
atomic statements.

It returns a list of strings containing the code of each atomic statement,
in the same order they appear in the given SQL string.

You shouldn't care about it, unless you want to bypass all the other
functionality offered by this module and do it by yourself, in which case
you can use it as a class method, like this:

    $dbh->do($_) foreach DBIx::DoMore->split( $sql_string );

=head1 DEPENDENCIES

DBIx::DoMore depends on the following modules:

=over 4

=item * L<SQL::Tokenizer>

=item * L<Moose>

=back

=head1 AUTHOR

Emanuele Zeppieri, C<< <emazep@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-domore at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-DoMore>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::DoMore

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-DoMore>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-DoMore>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-DoMore>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-DoMore/>

=back

=head1 ACKNOWLEDGEMENTS

Igor Sutton for his excellent L<SQL::Tokenizer>, which made writing
this module a joke.

=head1 SEE ALSO

=over 4

=item * L<DBI>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Emanuele Zeppieri.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation, or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
