package DBIx::RunSQL;
use strict;
use warnings;
use DBI;
use Module::Load 'load';

our $VERSION = '0.22';

=head1 NAME

DBIx::RunSQL - run SQL from a file

=cut

=head1 SYNOPSIS

    #!/usr/bin/perl -w
    use strict;
    use DBIx::RunSQL;

    my $test_dbh = DBIx::RunSQL->create(
        dsn     => 'dbi:SQLite:dbname=:memory:',
        sql     => 'sql/create.sql',
        force   => 1,
        verbose => 1,
        formatter => 'Text::Table',
    );

    # now run your tests with a DB setup fresh from setup.sql

=head1 METHODS

=head2 C<< DBIx::RunSQL->create ARGS >>

=head2 C<< DBIx::RunSQL->run ARGS >>

Runs the SQL commands and returns the database handle.
In list context, it returns the database handle and the
suggested exit code.

=over 4

=item *

C<sql> - name of the file containing the SQL statements

The default is C<sql/create.sql>

If C<sql> is a reference to a glob or a filehandle,
the SQL will be read from that. B<not implemented>

If C<sql> is undefined, the C<$::DATA> or the C<0> filehandle will
be read until exhaustion.  B<not implemented>

This allows one to create SQL-as-programs as follows:

  #!/usr/bin/perl -w -MDBIx::RunSQL -e 'create()'
  create table ...

If you want to run SQL statements from a scalar,
you can simply pass in a reference to a scalar containing the SQL:

    sql => \"update mytable set foo='bar';",

=item *

C<dsn>, C<user>, C<password>, C<options> - DBI parameters for connecting to the DB

=item *

C<dbh> - a premade database handle to be used instead of C<dsn>

=item *

C<force> - continue even if errors are encountered

=item *

C<verbose> - print each SQL statement as it is run

=item *

C<verbose_handler> - callback to call with each SQL statement instead of C<print>

=item *

C<verbose_fh> - filehandle to write to instead of C<STDOUT>

=back

=cut

sub create {
    my ($self,%args) = @_;
    $args{sql} ||= 'sql/create.sql';

    $args{options} ||= {};

    my $dbh = delete $args{ dbh };
    if (! $dbh) {
        $dbh = DBI->connect($args{dsn}, $args{user}, $args{password}, $args{options})
            or die "Couldn't connect to DSN '$args{dsn}' : " . DBI->errstr;
    };

    my $errors = $self->run_sql_file(
        dbh => $dbh,
        %args,
    );
    return wantarray ? ($dbh, $errors) : $dbh;
};
*run = *run = \&create;

=head2 C<< DBIx::RunSQL->run_sql_file ARGS >>

    my $dbh = DBI->connect(...)

    for my $file (sort glob '*.sql') {
        DBIx::RunSQL->run_sql_file(
            verbose => 1,
            dbh     => $dbh,
            sql     => $file,
        );
    };

Runs an SQL file on a prepared database handle.
Returns the number of errors encountered.

If the statement returns rows, these are printed
separated with tabs.

=over 4

=item *

C<dbh> - a premade database handle

=item *

C<sql> - name of the file containing the SQL statements

=item *

C<fh> - filehandle to the file containing the SQL statements

=item *

C<force> - continue even if errors are encountered

=item *

C<verbose> - print each SQL statement as it is run

=item *

C<verbose_handler> - callback to call with each SQL statement instead of
C<print>

=item *

C<verbose_fh> - filehandle to write to instead of C<STDOUT>

=item *

C<output_bool> - whether to exit with a nonzero exit code if any row is found

This makes the function return a nonzero value even if there is no error
but a row was found.

=item *

C<output_string> - whether to output the (one) row and column, without any
headers

=item *

C<formatter> - see the C<<formatter>> option of C<< ->format_results >>

=back

=cut

sub run_sql_file {
    my ($self,%args) = @_;
    my @sql;
    if( ! $args{ fh }) {
        open $args{ fh }, "<", $args{sql}
            or die "Couldn't read '$args{sql}' : $!";
    };
    {
        # potentially this should become C<< $/ = ";\n"; >>
        # and a while loop to handle large SQL files
        local $/;
        $args{ sql }= readline $args{ fh }; # sluuurp
    };
    $self->run_sql(
        %args
    );
}

=head2 C<< DBIx::RunSQL->run_sql ARGS >>

    my $dbh = DBI->connect(...)

    DBIx::RunSQL->run_sql(
        verbose => 1,
        dbh     => $dbh,
        sql     => \@sql_statements,
    );

Runs an SQL string on a prepared database handle.
Returns the number of errors encountered.

If the statement returns rows, these are printed
separated with tabs, but see the C<output_bool> and C<output_string> options.

=over 4

=item *

C<dbh> - a premade database handle

=item *

C<sql> - string or array reference containing the SQL statements

=item *

C<force> - continue even if errors are encountered

=item *

C<verbose> - print each SQL statement as it is run

=item *

C<verbose_handler> - callback to call with each SQL statement instead of C<print>

=item *

C<verbose_fh> - filehandle to write to instead of C<STDOUT>

=item *

C<output_bool> - whether to exit with a nonzero exit code if any row is found

This makes the function return a nonzero value even if there is no error
but a row was found.

=item *

C<output_string> - whether to output the (one) row and column, without any headers

=item *

C<formatter> - see the C<<formatter>> option of C<< ->format_results >>

=back

=cut

sub run_sql {
    my ($self,%args) = @_;
    my $errors = 0;
    my @sql= 'ARRAY' eq ref $args{ sql }
             ? @{ $args{ sql }}
             : $args{ sql };

    $args{ verbose_handler } ||= sub {
        $args{ verbose_fh } ||= \*main::STDOUT;
        print { $args{ verbose_fh } } "$_[0]\n";
    };
    my $status = delete $args{ verbose_handler };

    # Because we blindly split above on /;\n/
    # we need to reconstruct multi-line CREATE TRIGGER statements here again
    my $trigger;
    for my $statement ($self->split_sql( $args{ sql })) {
        # skip "statements" that consist only of comments
        next unless $statement =~ /^\s*[A-Z][A-Z]/mi;
        $status->($statement) if $args{verbose};

        my $sth = $args{dbh}->prepare($statement);
        if(! $sth) {
            if (!$args{force}) {
                die "[SQL ERROR]: $statement\n";
            } else {
                warn "[SQL ERROR]: $statement\n";
            };
        } else {
            my $status= $sth->execute();
            if(! $status) {
                if (!$args{force}) {
                    die "[SQL ERROR]: $statement\n";
                } else {
                    warn "[SQL ERROR]: $statement\n";
                };
            } elsif( defined $sth->{NUM_OF_FIELDS} and 0 < $sth->{NUM_OF_FIELDS} ) {
                # SELECT statement, output results
                if( $args{ output_bool }) {
                    my $res = $self->format_results(
                        sth => $sth,
                        no_header_when_empty => 1,
                        %args
                    );
                    print $res;
                    # Set the exit code depending on the length of $res because
                    # we lost the information on how many rows the result
                    # set had ...
                    $errors = length $res > 0;

                } elsif( $args{ output_string }) {
                    local $args{formatter} = 'tab';
                    print $self->format_results(
                        sth => $sth,
                        no_header_when_empty => 1,
                        %args
                    );

                } else {
                    print $self->format_results( sth => $sth, %args );
                };
            };
        };
    };
    $errors
}

=head2 C<< DBIx::RunSQL->format_results %options >>

  my $sth= $dbh->prepare( 'select * from foo' );
  $sth->execute();
  print DBIx::RunSQL->format_results( sth => $sth );

Executes C<< $sth->fetchall_arrayref >> and returns
the results either as tab separated string
or formatted using L<Text::Table> if the module is available.

If you find yourself using this often to create reports,
you may really want to look at L<Querylet> instead.

=over 4

=item *

C<sth> - the executed statement handle

=item *

C<formatter> - if you want to force C<tab> or C<Text::Table>
usage, you can do it through that parameter.
In fact, the module will use anything other than C<tab>
as the class name and assume that the interface is compatible
to C<Text::Table>.

=back

Note that the query results are returned as one large string,
so you really do not want to run this for large(r) result
sets.

=cut

sub format_results {
    my( $self, %options )= @_;
    my $sth= delete $options{ sth };

    if( ! $options{ formatter }) {
        if( eval { require "Text/Table.pm" }) {
            $options{ formatter }= 'Text::Table';
        } else {
            $options{ formatter }= 'tab';
        };
    };

    my @columns= @{ $sth->{NAME} };
    my $no_header_when_empty = $options{ no_header_when_empty };
    my $print_header = not exists $options{ header } || $options{ header };
    my $res= $sth->fetchall_arrayref();
    my $result='';
    if( @columns ) {
        # Output as print statement
        if( $no_header_when_empty and ! @$res ) {
            # Nothing to do

        } elsif( 'tab' eq $options{ formatter } ) {
            $result = join "\n",
                          $print_header ? join( "\t", @columns ) : (),
                          map { join( "\t", @$_ ) } @$res
                      ;

        } else {
            my $class = $options{ formatter };

            if( !( $class->can('table') || $class->can('new'))) {
                # Try to load the module, just in case it isn't present in
                # memory already

                eval { load $class; };
            };

            # Now dispatch according to the apparent type
            if( !$class->isa('Text::Table') and my $table = $class->can('table') ) {
                # Text::Table::Any interface
                $result = $table->( header_row => 1,
                    rows => [\@columns, @$res ],
                );
            } else {;
                # Text::Table interface
                my $t= $options{formatter}->new(@columns);
                $t->load( @$res );
                $result= $t;
            };
        };
    };
    "$result"; # Yes, sorry - we stringify everything
}

=head2 C<< DBIx::RunSQL->split_sql ARGS >>

  my @statements= DBIx::RunSQL->split_sql( <<'SQL');
      create table foo (name varchar(64));
      create trigger foo_insert on foo before insert;
          new.name= 'foo-'||old.name;
      end;
      insert into foo name values ('bar');
  SQL
  # Returns three elements

This is a helper subroutine to split a sequence of (semicolon-newline-delimited)
SQL statements into separate statements. It is documented because
it is not a very smart subroutine and you might want to
override or replace it. It might also be useful outside the context
of L<DBIx::RunSQL> if you need to split up a large blob
of SQL statements into smaller pieces.

The subroutine needs the whole sequence of SQL statements in memory.
If you are attempting to restore a large SQL dump backup into your
database, this approach might not be suitable.

=cut

sub split_sql {
    my( $self, $sql )= @_;
    my @sql = split /;[ \t]*\r?\n/, $sql;

    # Because we blindly split above on /;\n/
    # we need to reconstruct multi-line CREATE TRIGGER statements here again
    my @res;
    my $trigger;
    for my $statement (@sql) {
        next unless $statement =~ /\S/;
        if( $statement =~ /^\s*CREATE\s+TRIGGER\b/i ) {
            $trigger = $statement;
            next
                if( $statement !~ /END$/i );
            $statement = $trigger;
            undef $trigger;
        } elsif( $trigger ) {
            $trigger .= ";\n$statement";
            next
                if( $statement !~ /END$/i );
            $statement = $trigger;
            undef $trigger;
        };
        push @res, $statement;
    };

    @res
}

1;

=head2 C<< DBIx::RunSQL->parse_command_line >>

    my $options = DBIx::RunSQL->parse_command_line( 'my_application', \@ARGV );

Helper function to turn a command line array into options for DBIx::RunSQL
invocations. The array of command line items is modified in-place.

If the reference to the array of command line items is missing, C<@ARGV>
will be modified instead.

=cut

sub parse_command_line {
    my ($package,$appname,$argv) =  @_;
    require Getopt::Long; Getopt::Long->import('GetOptionsFromArray');

    if (! $argv) { $argv = \@ARGV };

    if (GetOptionsFromArray( $argv,
        'user:s'     => \my $user,
        'password:s' => \my $password,
        'dsn:s'      => \my $dsn,
        'verbose'    => \my $verbose,
        'force|f'    => \my $force,
        'sql:s'      => \my $sql,
        'bool'       => \my $output_bool,
        'string'     => \my $output_string,
        'quiet'      => \my $no_header_when_empty,
        'format:s'   => \my $formatter_class,
        'help|h'     => \my $help,
        'man'        => \my $man,
    )) {
        no warnings 'newline';
        $sql ||= join " ", @$argv;
        if( $sql and ! -f $sql ) {
            $sql = \"$sql",
        };
        my $fh;
        if( ! $sql and not @$argv) {
            # Assume we'll read the SQL from stdin
            $fh = \*STDIN;
        };
        return {
        user                 => $user,
        password             => $password,
        dsn                  => $dsn,
        verbose              => $verbose,
        force                => $force,
        sql                  => $sql,
        fh                   => $fh,
        no_header_when_empty => $no_header_when_empty,
        output_bool          => $output_bool,
        output_string        => $output_string,
        formatter            => $formatter_class,
        help                 => $help,
        man                  => $man,
        };
    } else {
        return undef;
    };
}

sub handle_command_line {
    my ($package,$appname,$argv) =  @_;
    require Pod::Usage; Pod::Usage->import();

    my $opts = $package->parse_command_line($appname,$argv)
        or pod2usage(2);
    pod2usage(1) if $opts->{help};
    pod2usage(-verbose => 2) if $opts->{man};

    $opts->{dsn} ||= sprintf 'dbi:SQLite:dbname=db/%s.sqlite', $appname;
    my( $dbh, $exitcode) = $package->create(
        %$opts
    );
    return $exitcode
}

=head2 C<< DBIx::RunSQL->handle_command_line >>

    DBIx::RunSQL->handle_command_line( 'my_application', \@ARGV );

Helper function to run the module functionality from the command line. See below
how to use this function in a good self-contained script.
This function
passes the following command line arguments and options to C<< ->create >>:

  --user
  --password
  --dsn
  --sql
  --quiet
  --format
  --force
  --verbose
  --bool
  --string

In addition, it handles the following switches through L<Pod::Usage>:

  --help
  --man

If no SQL is given, this function will read the SQL from STDIN.

If no dsn is given, this function will use
C< dbi:SQLite:dbname=db/$appname.sqlite >
as the default database.

See also the section PROGRAMMER USAGE for a sample program to set
up a database from an SQL file.

=head1 PROGRAMMER USAGE

This module abstracts away the "run these SQL statements to set up
your database" into a module. In some situations you want to give the
setup SQL to a database admin, but in other situations, for example testing,
you want to run the SQL statements against an in-memory database. This
module abstracts away the reading of SQL from a file and allows for various
command line parameters to be passed in. A skeleton C<create-db.sql>
looks like this:

    #!/usr/bin/perl -w
    use strict;
    use DBIx::RunSQL;

    my $exitcode = DBIx::RunSQL->handle_command_line('myapp', \@ARGV);
    exit $exitcode;

    =head1 NAME

    create-db.pl - Create the database

    =head1 SYNOPSIS

      create-db.pl "select * from mytable where 1=0"

    =head1 ABSTRACT

    This sets up the database. The following
    options are recognized:

    =head1 OPTIONS

    =over 4

    =item C<--user> USERNAME

    =item C<--password> PASSWORD

    =item C<--dsn> DSN

    The DBI DSN to use for connecting to
    the database

    =item C<--sql> SQLFILE

    The alternative SQL file to use
    instead of C<sql/create.sql>.

    =item C<--quiet>

    Output no headers for empty SELECT resultsets

    =item C<--bool>

    Set the exit code to 1 if at least one result row was found

    =item C<--string>

    Output the (single) column that the query returns as a string without
    any headers

    =item C<--format> formatter

    Use a different formatter for table output. Supported formatters are

      tab - output results as tab delimited columns

      Text::Table - output results as ASCII table

    =item C<--force>

    Don't stop on errors

    =item C<--help>

    Show this message.

    =back

    =cut

=head1 NOTES

=head2 COMMENT FILTERING

The module tries to keep the SQL as much verbatim as possible. It
filters all lines that end in semicolons but contain only SQL comments. All
other comments are passed through to the database with the next statement.

=head2 TRIGGER HANDLING

This module uses a very simplicistic approach to recognize triggers.
Triggers are problematic because they consist of multiple SQL statements
and this module does not implement a full SQL parser. An trigger is
recognized by the following sequence of lines

    CREATE TRIGGER
        ...
    END;

If your SQL dialect uses a different syntax, it might still work to put
the whole trigger on a single line in the input file.

=head2 OTHER APPROACHES

If you find yourself wanting to write SELECT statements,
consider looking at L<Querylet> instead, which is geared towards that
and even has an interface for Excel or HTML output.

If you find yourself wanting to write parametrized queries as
C<.sql> files, consider looking at L<Data::Phrasebook::SQL>
or potentially L<DBIx::SQLHandler>.

=head1 SEE ALSO

L<ORLite::Migrate>

L<Test::SQLite> - SQLite setup/teardown for tests, mostly geared towards
testing, not general database setup

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/DBIx--RunSQL>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-RunSQL>
or via mail to L<bug-dbix-runsql@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2009-2021 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
