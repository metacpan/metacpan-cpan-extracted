package DBIx::DataAudit;
use strict;
use Carp qw(croak carp);
use DBI;
use parent 'Class::Accessor';
use vars '$VERSION';
$VERSION = '0.13';

=head1 NAME

DBIx::DataAudit - summarize column data for a table

=head1 SYNOPSIS

  use DBIx::DataAudit;

  warn "Running audit for table $table";
  my $audit = DBIx::DataAudit->audit( dsn => 'dbi:SQLite:dbname=test.sqlite', table => 'test' );
  print $audit->as_text;

  # or
  print $audit->as_html;

This module provides a summary about the data contained in a table. It provides
the descriptive statistics for every column. It's surprising
how much bad data you find by looking at the minimum and maximum
values of a column alone.

It tries to get the information in one table scan.

=head1 HOW IT WORKS

The module works by constructing an SQL statement that collects the information
about the columns in a single full table scan.

=head1 COLUMN TRAITS

You can specify which information is collected about every column by specifying the traits.
The hierarchy of traits is as follows:

  any < ordered < numeric
                < string

The following traits are collected for every column by default:

=over 4

=item * C<total>

Number of rows in the column

=item * C<values>

Number of distinct values in the column

=item * C<null>

Number of C<NULL> values for the column

=back

For columns that are recognized as ordered, the following additional traits are collected:

=over 4

=item * C<min>

Minimum value for the column

=item * C<max>

Maximum value for the column

=back

For columns that are recognized as numeric, the following additional traits are collected:

=over 4

=item * C<avg>

Average value for the column

=back

For columns that are recognized as string, the following additional traits are collected:

=over 4

=item * C<blank>

Number of values that consist only of blanks (C<chr 32>)

=item * C<empty>

Number of values that consist only of the empty string (C<''>)

=item * C<missing>

Number of values that consist only of the empty string (C<''>),
are blank (C<chr 32>) or are C<NULL>

=back

=cut

=head1 GLOBAL VARIABLES

To customize some default behaviour, the some global variables
are defined. Read the source to find their names.

=cut

use vars qw'@default_traits %trait_type %trait_hierarchy $trait_inapplicable %sql_type_map';

@default_traits = qw[min max count values null avg blank empty missing ];

%trait_type = (
    count    => ['any','count(%s)'],
    values   => ['any','count(distinct %s)'],
    null     => ['any','sum(case when %s is null then 1 else 0 end)'],
    min      => ['ordered','min(%s)'],
    max      => ['ordered','max(%s)'],
    avg      => ['numeric','avg(%s)'],
    #modus   => ['any','sum(1)group by %s'], # find the element that occurs the most
    # Possibly with only a single table scan
    blank    => ['string',"sum(case when trim(%s)='' then 1 else 0 end)"],
    empty    => ['string',"sum(case when %s='' then 1 else 0 end)"],
    missing  => ['string',"sum(case when trim(%s)='' then 1 when %s is null then 1 else 0 end)"],
);

%trait_hierarchy = (
    any => [],
    ordered => ['any'],
    numeric => ['ordered','any'],
    string  => ['ordered','any'],
);

$trait_inapplicable = 'NULL';

%sql_type_map = (
    BIGINT    => 'numeric',
    BOOLEAN   => 'any',
    CHAR      => 'string',
    'CHARACTER VARYING'      => 'string',
    DATETIME  => 'ordered',
    DATE      => 'ordered',
    DECIMAL   => 'numeric',
    ENUM      => 'ordered',
    INET      => 'any',
    INTEGER   => 'numeric',
    INT       => 'numeric',
    NUMERIC   => 'numeric',
    SMALLINT  => 'numeric',
    TEXT      => 'string',
    TIME      => 'ordered',
    'TIMESTAMP WITHOUT TIME ZONE' => 'ordered',
    TIMESTAMP => 'ordered',
    TINYINT   => 'numeric',
    'UNSIGNED BIGINT'    => 'numeric',
    VARCHAR   => 'string',
);

=head1 METHODS

The class implements the following methods:

=cut

__PACKAGE__->mk_accessors(qw(table dbh dsn columns traits results where));

=head2 C<< __PACKAGE__->audit ARGS >>

Performs the data audit. Valid arguments are:

=over 4

=item * C<table>

Name of the table to audit. No default.

=item * C<traits>

Array reference to the traits. Default traits are

  min max count null avg blank empty missing

=item * C<columns>

Names of the columns to audit. Default are all columns of the table.

=item * C<dbh>

Database handle. If missing, hopefully you have specified the C<dsn>.

=item * C<dsn>

DSN to use. Can be omitted if you pass in a valid C<dbh> instead.

=item * C<column_info>

Column information, in the same format as the DBI returns it.
By default, this will be read in via DBI.

=back

=cut

sub audit {
    my ($class, %args) = @_;

    $args{traits} ||= [ @default_traits ];
    if (! @{$args{traits}}) {
        $args{traits} = [ @default_traits ];
    };
    $args{dbh}    ||= DBI->connect( $args{dsn}, undef, undef, {RaiseError => 1});

    my $self = \%args;
    bless $self => $class;
    $self->{columns} ||= [$self->get_columns];
    if (! @{ $self->{columns}}) {
        croak "Couldn't retrieve column information for table '$args{table}'. Does your DBD implement ->column_info?";
    };
    $self->{column_info} ||= $self->collect_column_info;

    $self
};

=head2 C<< $audit->as_text RESULTS >>

Returns a table drawn as text with the results.

=cut

sub as_text {
    my ($self,$results) = @_;

    require Text::Table;
    my $data = $self->template_data($results);
    my $table = Text::Table->new( @{$data->{headings}} );
    $table->load( @{$data->{rows}} );

    "Data analysis for $data->{table}:\n\n" . $table->table;
};

=head2 C<< $audit->as_html RESULTS, TEMPLATE >>

Returns a HTML page with the results.

You can pass in a custom resultset or C<undef> if you want
the module to determine the results.

You can pass in a custom (L<Template|Template Toolkit>) template
if you want fancier rendering.

=cut

sub as_html {
    my ($self,$results,$template) = @_;
    require Template;
    $template ||= <<TEMPLATE;
<html><head><title>Data audit of table '[% table %]'</title></head><body>
<h2>Data audit of table '[% table %]'</h2>
<table width="100%">
<thead>
<tr>[% FOR h IN headings %]<th>[%h%]</th>[%END%]</tr>
</thead>
<tbody>
[% FOR r IN rows %]
<tr>[% FOR v IN r %]<td>[%v FILTER html_entity%]</td>[%END%]</tr>
[% END %]
</tbody>
</table>
</html>
TEMPLATE

    my $t = Template->new();
    my $data = $self->template_data($results);

    $t->process(\$template,$data,\my $result)
        || croak $t->error;
    $result
};

=head2 C<< $audit->template_data >>

Returns a hash with the following three keys, suitable
for using with whatever templating system you have:

=over 4

=item *

C<table> - the name of the table

=item *

C<headings> - the headings of the columns

=item *

C<rows> - the values of the traits of every column

=back

=cut

sub template_data {
    my ($self,$results) = @_;
    $results ||= $self->{results} || $self->run_audit;
    my @results = @{ $results->[0] };

    my @headings = (@{ $self->traits });
    my @rows;
    for my $column (@{ $self->columns }) {
        my @row = $column;
        for my $trait (@headings) {
            my $val = shift @results;
            if (defined $val) {
                if (length($val) > 20) {
                    $val = substr($val,0,20);
                };
                $val =~ s/[\x00-\x1f]/./g;
            };
            push @row, defined $val ? $val : 'n/a';
        };
        push @rows, \@row;
    };

    my $res = {
        table => $self->table,
        headings => ['column',@headings],
        rows => \@rows,
    };
};

=head2 C<< $audit->run_audit >>

Actually runs the SQL in the database.

=cut

sub run_audit {
    my ($self) = @_;

    my $sql = $self->get_sql;
    $self->{results} = $self->dbh->selectall_arrayref($sql,{});
};

=head2 C<< $audit->column_type COLUMN >>

Returns the type for the column. The four valid types are C<any>, C<ordered>, C<numeric> and C<string>.

=cut

sub column_type {
    my ($self,$column) = @_;
    if (! $self->{column_info}) {
        $self->{column_info} = $self->collect_column_info;
    };
    my $info = $self->{column_info};
    map {
        $_->{trait_type};
    } grep { $_->{COLUMN_NAME} eq $column } @$info;
};

=head2 C<< $audit->get_columns TABLE >>

Returns the names of the columns for the table C<TABLE>.
By default, the value of C<TABLE> will be taken from the value
passed to the constructor C<audit>.

=cut

sub get_columns {
    my ($self,$table) = @_;
    $table ||= $self->table;
    if (! $self->{column_info}) {
        $self->{column_info} = $self->collect_column_info;
    };
    my $info = $self->{column_info};
    my @sorted = @$info;

    # Order the columns in the "right" order, if possible
    if (exists $sorted[0]->{ORDINAL_POSITION} && defined $sorted[0]->{ORDINAL_POSITION}) {
        @sorted = sort { $a->{ORDINAL_POSITION} <=> $b->{ORDINAL_POSITION} } @sorted;
    };
    map {
        $_->{COLUMN_NAME};
    } @sorted;
};

=head2 C<< $audit->collect_column_info TABLE >>

Collects the information about the columns for the table C<TABLE>
from the DBI. By default, C<TABLE> will be taken from the
value passed to the constructor C<audit>.

If your database driver does not implement the C<< ->column_info >>
method you are out of luck. A fatal error is raised by this method
if C<< ->column_info >> does not return anything.

This method will raise warnings if it encounters a data type that
it doesn't know yet. You can either patch the
global variable C<%sql_type_map> to add the type or submit a patch
to me to add the type and its interpretation.

=cut

sub collect_column_info {
    my ($self,$table) = @_;
    $table ||= $self->table;
    my $schema;
    if ($table =~ s/^(.*)\.//) {
        $schema = $1;
    };
    my $sth = $self->dbh->column_info(undef,$schema,$table,undef);
    if (! $sth) {
        if( $schema ) {
            $schema= "$schema.";
        } else {
            $schema= '';
        };
        croak "Couldn't collect column information for table '$schema$table'. Does your DBD implement ->column_info?";
    };
    my $info = $sth->fetchall_arrayref({});

    if( !@$info ) {
        croak "'$schema$table' seems to have no columns. Does your DBD implement ->column_info?";
    };

    for my $i (@$info) {
        my $sqltype = uc $i->{TYPE_NAME};

        # Fix for Pg - convert enum types to "ENUM":
        if (exists $i->{pg_enum_values} && defined $i->{pg_enum_values}) {
                $sqltype = 'ENUM';
        };

        if (not exists $sql_type_map{ $sqltype }) {
            warn sprintf q{Unknown SQL data type '%s' for column "%s.%s"; some traits will be unavailable\n},
	        $sqltype, $table, $i->{COLUMN_NAME};
        };
        $i->{trait_type} = $sql_type_map{ $sqltype } || 'any';
    };

    $info
};

=head2 C<< $audit->get_sql TABLE >>

Creates the SQL statement to collect the information.
The default value for C<TABLE> will be the table passed
to the constructor C<audit>.

If you encounter errors from your SQL engine, you may want
to print the result of this method out.

=cut

sub get_sql {
    my ($self,$table) = @_;
    $table ||= $self->table;
    my @columns = @{ $self->columns };
    my @traits = @{$self->traits};

    my @resultset;
    for my $column (@columns) {
        for my $trait (@traits) {
            my $name = "${column}_${trait}";
            $name =~ s/"//g; # unquote quoted columns
            if ($self->trait_applies( $trait, $column )) {
                my $tmpl = $trait_type{$trait}->[1];
                $tmpl =~ s/%s/$column/g;
                push @resultset, "$tmpl as $name";
            } else {
                push @resultset, "NULL as $name";
            };
        };
    };
    my $where = $self->where ? "WHERE " . $self->where : '';
    my $statement = sprintf "SELECT %s FROM %s\n%s", join("\n    ,", @resultset), $table, $where;
    return $statement
};

=head2 C<< $audit->trait_applies TRAIT, COLUMN >>

Checks whether a trait applies to a column.

A trait applies to a column if the trait type is C<any>
or if it is the same type as the column type as returned
by C<get_column_type>.

The method will raise an error if it is passed an unknown
trait name. See the source code for how to add custom
traits.

=cut

sub trait_applies {
    my ($self, $trait, $column) = @_;
    if (not exists $trait_type{$trait}) {
        carp "Unknown trait '$trait'";
    };
    my $trait_type = $trait_type{$trait}->[0] || '';

    return 1 if ($trait_type eq 'any');

    (my $type) = $self->column_type($column);
    my @subtypes = @{ $trait_hierarchy{ $type } };

    return scalar grep { $trait_type eq $_ } ($type,@subtypes);
};

=head1 COMMAND LINE USAGE

You can use this mail from the command line if you need a quick check of data:

  perl -MDBIx::DataAudit=dbi:SQLite:dbname=some/db.sqlite my_table [traits]

This could also incredibly useful if you want a breakdown of a csv-file:

  perl -MDBIx::DataAudit=dbi:AnyData:dbname=some/db.sqlite my_table [traits]

Unfortunately, that does not work yet, as I haven't found a convenient
oneliner way to make a CSV file appear as database.

=cut

sub import {
    my ($class, $dsn) = @_;
    (my $target) = caller;
    if ($target eq 'main' and $dsn) {
        my ($table,@traits) = @ARGV;
        my @tables = split /,/,$table;
        if (! @traits) {
            @traits = @default_traits;
        };
        for my $table (@tables) {
            my $self = $class->audit(dsn => $dsn, table => $table, traits => \@traits);
            print "Data audit for table '$table'\n\n";
            print $self->as_text;
        };
    };
};

1;

__END__

=head1 PLANNED FEATURES

=over 4

=item *

Show the value distribution per column. This will mean
running an SQL statement per column that does another full
table scan, or at least a full index scan, unless somebody
tells me how to do such without a C<GROUP BY> clause.

=item *

Fancy HTML bar charts showing the value distribution

=back

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2008-2009 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.
