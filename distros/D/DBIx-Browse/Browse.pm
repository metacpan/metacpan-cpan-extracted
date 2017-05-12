#
# $Id: Browse.pm,v 2.9 2002/12/10 09:17:20 evilio Exp $
#
package DBIx::Browse;

use strict;
use diagnostics;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use Carp;
use DBI;

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(
);
#
# Keep Revision from CVS and Perl version in paralel.
#
$VERSION = do { my @r=(q$Revision: 2.9 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

#
# new
#
sub new {
    my $this   = shift;
    my $class  = ref($this) || $this;
    my $self   = {};
    bless $self, $class;
    $self->init( @_ );
    return $self;
}

#
# init
#
sub init {
    my $self  = shift;
    my $param = shift;
    my ($dbh, $table, $pkey, $pfields, $lfields , $ltables, $lvalues,
	$lrefs, $lalias, $debug);

    $dbh        = $param->{dbh};
    croak 'No database handler.'
	unless (   UNIVERSAL::isa($dbh, 'DBI::db') );

    $table      = $param->{table} or croak 'No table to browse.';
    $pkey       = $param->{primary_key} || 'id';

    $pfields    = $param->{proper_fields};
    $lfields    = $param->{linked_fields};
    $ltables    = $param->{linked_tables};
    $lvalues    = $param->{linked_values};
    $lrefs      = $param->{linked_refs};
    $lalias     = $param->{aliases};
    $debug      = $param->{debug};

    

    # try to set autocommit to 0
    $self->{dbh}   = $dbh;    
    eval { $self->{dbh}->{AutoCommit} = 0; };
    $self->die() if ($dbh->{AutoCommit}); 
    $self->{dbh}->{PrintError} = 0;
    $self->set_syntax();

    $self->{table} = lc("$table");
    $self->{primary_key} = $pkey;

    $self->{debug}       = $debug;

    $self->{single} = 0;

    if ( ! $lfields ) {
	$self->{single} = 1;
    }

    $self->{linked_fields} = [map {lc($_)} @$lfields];

    my @fields = $self->fields;

    if ( $pfields ) {
	$self->{non_linked} = [map {lc($_)} @$pfields];
    }
    else {
	$self->{non_linked} = [];
	foreach my $f ( @fields ) {
	    my $lnk = grep (/$f/i,  @{$self->{linked_fields}});
	    if ( ! $lnk ) {
		push @{$self->{non_linked}}, lc($f);
	    }
	}
    }

    #
    # croak if mismatched parameters present
    #
    my $croak_txt = sub { my ($par,$par_ref) = @_; return "Parameter $par (if present) must have the same numbers of elements than $par_ref"; };

    # linked_tables
    if ( ! $ltables ) {
	$ltables = $self->{linked_fields};
    }
    elsif ( $self->{single} ||
	    scalar(@$ltables) != scalar(@{$self->{linked_fields}})
	    ) {
	croak $croak_txt->('linked_tables','linked_fields');
    }
    $self->{linked_tables} = [map {lc($_)} @$ltables];

    # nuber of linked tables.
    my $n_ltables = 0;
    if ( $ltables ) {
	$n_ltables = scalar(@$ltables);
    }

    # linked_values
    if ( ! $lvalues && $n_ltables ) {
	my $names = 'name,' x $n_ltables;
	my @lvalues =  split(/,/, $names, $n_ltables);
	$lvalues[$n_ltables-1] =~ s/,$//;
	$lvalues = \@lvalues;
    }
    elsif ( $lvalues       && (
	    $self->{single} ||
	    scalar(@$lvalues) != scalar(@{$self->{linked_fields}}))
	    ) {
	croak $croak_txt->('linked_values','linked_fields');
    }
    $self->{linked_values} = [map {lc($_)} @$lvalues];

    # linked_refs
    if ( ! $lrefs && $n_ltables ) {
	my $ids =  'id,' x $n_ltables;
	my @lrefs = split( /,/, $ids, $n_ltables);
	$lrefs[$n_ltables-1] =~ s/,$//;
	$lrefs = \@lrefs;
    }
    elsif ( $lrefs && (
	    $self->{single} || 
	    scalar(@$lrefs) != scalar(@{$self->{linked_fields}}))
	   ) {
	croak($croak_txt->('linked_refs','linked_fields'));
    }
    $self->{linked_refs} = [map {lc($_)} @$lrefs];

    # aliases (fields)
    if ( ! $lalias) {
	$lalias = [@{$self->{non_linked}}, @{$self->{linked_tables}} ]
    }
    elsif ( scalar(@$lalias) != $n_ltables+1) {
	croak $croak_txt->('linked_refs','linked_fields plus one');
    }
    $self->{aliases} = [map {lc($_)} @$lalias];


    #
    # table aliases: we need them to assure that the same table can be included
    # two or more times.
    #
    my $table_alias = 'AAA';
    $self->{table_aliases} = [ "$table_alias" ];
    foreach my $t ( @{$self->{linked_tables}} ) {
	$table_alias++; # How nice is perl
	push(@{$self->{table_aliases}}, $table_alias);
    }
}

#
# query_fields: fields to be SELECTed by the prepare
#
sub query_fields {
    my $self = shift;

    my $query = "";
    my $nproper = scalar(@{$self->{non_linked}});

    for (my $f = 0; $f < $nproper; $f++) {
	$query .= ', '.$self->{table_aliases}->[0].".".$self->{non_linked}->[$f].
	    ' AS '.$self->{aliases}->[$f];
    }
    unless ( $self->{single}) {
	for (my $lf = 0; $lf <  scalar(@{$self->{linked_fields}}); $lf++) {
	    $query .= ", ".$self->{table_aliases}->[$lf+1].".".
		$self->{linked_values}->[$lf].
		    ' AS '.$self->{aliases}->[$nproper+$lf];
	}
    }

    # Include pkey always
    $query .= 
	', '.$self->{table_aliases}->[0].".".$self->{primary_key}.
	    ' AS '.$self->pkey_name.' ';
    # remove trailing ', '
    $query =~ s/^, //;

    return $query;
}

#
# query_tables: FROM clase in prepare
#
sub query_tables {
    my $self = shift;

    my $query = '';

    # tables list
    $query .= "\n FROM ".$self->{table}." ".$self->{table_aliases}->[0]." ";
    unless ( $self->{single} ) {
	my $i = 1;
	foreach my $lt ( @{$self->{linked_tables}} ) {
	    $query .= ", ".$lt." ".$self->{table_aliases}->[$i];
	    $i++;
	}

    # join condition
    $query .= "\n WHERE ";
    for(my $lf = 0; $lf <  scalar(@{$self->{linked_fields}}); $lf++)  {
	unless ($self->{linked_fields}->[$lf] =~ m/.+\..+/ ) {
	    $query .= 
		$self->{table_aliases}->[0].".";
	}
	$query .=
	    $self->{linked_fields}->[$lf] . " = ".
	    $self->{table_aliases}->[$lf+1].".".
	    $self->{linked_refs}->[$lf]. " AND ";
    }

    # Erase trailing AND 
    $query =~ s/AND $//;
    }

    return $query;
}

#
# query: minimal query for prepare
#
sub query {
    my $self = shift;

    my $query = "SELECT ";

    $query .= $self->query_fields;

    $query .= $self->query_tables;

    return $query;
}


#
# count: count fields (with prepare)
#
sub count {
    my $self   = shift;
    my $params = shift;

    $params->{fields} = ' count(*) ';

    my $counth = $self->prepare($params);

    $counth->execute;

    my ($count) = $counth->fetchrow_array;

    return $count;
}

#
# prepare: prepare a query with the fields, FROM clause and WHERE prebuilt
#
sub prepare {
    my $self  = shift;
    my $param = shift;
    my %syntax = %{$self->{syntax}};
    my %order  = %{$self->{syntax_order}};

    if ( $self->{single} ) {
	$syntax{where} = ' WHERE ';
    }

    # always use offset
    unless ($param->{offset} or not $param->{limit} ) {
	$param->{offset} = '0 ';
    }
    
    my $query = '';

    foreach my $num ( sort keys %order ) {
	my $p = $order{$num};
	if ( $param->{$p} ) {
	    $param->{$p} = $self->unalias_fields($param->{$p});
	    $query .= "\n".$syntax{$p}.$param->{$p};
	    if ( ref($param->{$p}) eq 'HASH') {
		print 
		    "Par: ",$p,
		    ", Keys: ",join(':', keys   %{ $param->{$p} } ),
		    ", Vals: ",join(':', values %{ $param->{$p} } );
	    }
	}
    }

    if ( $param->{fields} ) {
	$query  = 'SELECT '.$param->{fields}.' '.$self->query_tables();
    }
    else  {
	$query = $self->query().' '.$query;
    }

    $self->debug("Prepare: ".$query."\n");

    return $self->{dbh}->prepare($query)
	or $self->die();
}

#
# unalias_fields: used to specify a field as table_alias.fieldname instead of
# field alias, i.e.: AAB.name instead of 'department' or 'department.name'.
#
sub unalias_fields {
    my $self   = shift;
    my $phrase = shift; 
    my $type   = shift;

    my $nprop  = scalar (@{$self->{non_linked}});

    $self->debug("Alias:\t$phrase");
    my ( $field, $table, $column);

    for (my $f = 0; $f < scalar(@{$self->{aliases}}); $f++) {
	$field  = $self->{aliases}->[$f];

	$table  = ($f >= $nprop) ? 
	        $self->{table_aliases}->[$f-$nprop+1] :
		$self->{table_aliases}->[0];
	
	$column = ($f >= $nprop) ?
	    $self->{linked_values}->[$f-$nprop] :
	    $self->{non_linked}->[$f];
        # change all occurrences of SQL
        # word "$field" by
        # the correct $table.$column
	$phrase =~
	    s/(\A|[^0-9a-z_.]+)($field)([^0-9a-z_.]+)/$1.$table.".".$column.$3/egi;
	                            
    };
    # unalias primary key
    $field = $self->pkey_name; 
    $table = $self->{table_aliases}->[0];
    $column = $self->{primary_key};
    $phrase =~
	s/(\A|[^0-9a-z_.]+)($field)([^0-9a-z_.]+)/$1.$table.".".$column.$3/egi;

    $self->debug("Unalias:\t$phrase");
    return $phrase;
}

#
# demap: translate linked_tables.linked_values to 
#  table.linked_fields (linked_refs).
#  used by add() and update().
#
sub demap {
    my $self = shift;
    my $rec  = shift;

    my $nprop = scalar(@{$self->{non_linked}});

    unless ( $self->{single} ) {
	#for my $test ( keys %{$rec} ) {
	#    $self->debug("\t".$test.' => '.$rec->{$test})
	#}
	for(my $f = 0; $f <  scalar( @{$self->{linked_fields}} ); $f++) {
	    my $fname = $self->{aliases}->[$f+$nprop];
	    my $lnk = grep( /$fname/i, keys %$rec );
	    next unless $lnk;
	    my $qfield = 
		"SELECT ".$self->{linked_refs}->[$f].
		"  FROM ".$self->{linked_tables}->[$f].
		" WHERE ".$self->{linked_values}->[$f].
		"    = ?";
	    $self->debug('Demap: '.$qfield);
	    my $stf = $self->{dbh}->prepare($qfield)
		or $self->die();
	    $stf->execute($rec->{$fname})
		or $self->die();
	    my ($ref_value) = $stf->fetchrow_array;
	    delete $rec->{$fname};
	    $rec->{$self->{linked_fields}->[$f]} = $ref_value;
	}
    }
}

#
# insert: insert a record into the main table.
#
sub insert {
    my $self = shift;
    my $rec  = shift;

    my $query = 'INSERT INTO '.$self->{table}.'(';
    my $qval  = ' VALUES(';

    my @fields = $self->fields;

    $self->demap($rec);

    foreach my $f ( keys %$rec ) {
	my $fok = grep (/$f/i,  @fields );
	$query .= $f.',';
	$qval  .= $self->{dbh}->quote($rec->{$f}).",";
	next if $fok;
	$self->debug("Field not found: $f => ".$rec->{$f});
    }
    chop($query);
    chop($qval);
    $query .= ') '.$qval.')';
    $self->debug("Insert: ".$query);
    my $ok = $self->{dbh}->do($query) or $self->die();
    $self->{dbh}->commit() or $self->die();
    return $ok;
}

#
# update: update a row in the main table.
#
sub update {
    my $self  = shift;
    my $rec   = shift;
    my $where = shift;
    my @fields = $self->fields;

    my $query = 'UPDATE  '.$self->{table}.' SET ';

    $self->demap($rec);

    foreach my $f ( keys %$rec ) {
	my $fok = grep (/$f/i,  @fields );
	$query .= $f.' = ';
	$query .= $self->{dbh}->quote($rec->{$f}).",";
	next if $fok;
	croak "Field not found: $f => ".$rec->{$f};
    }
    chop($query);

    
    $query .= ' WHERE '.$where if ($where);

    $self->debug("Update: ".$query);
    my $ok = $self->{dbh}->do($query) or $self->die();
    $self->{dbh}->commit() or $self->die();
    return $ok;
}

#
# delete: delete a record in the main table).
#
sub delete {
    my $self  = shift;
    my $pkey  = shift;
    my $qdel  = 
	"DELETE FROM ".$self->{table}.
	" WHERE ".$self->{primary_key}." = ?";

    $self->debug("Delete: ".$qdel. ' [ ? = '.$pkey.']');
    my $sdel  = $self->{dbh}->prepare($qdel) or $self->die();
    my $rdel  = $sdel->execute($pkey) or $self->die();
    $self->{dbh}->commit() or $self->die();
    return $rdel;
}

#
# fields: list of fields (aliases)
#
sub fields {
    my $self   = shift;
    my $single = "SELECT * FROM ".$self->{table}." LIMIT 1";
    my $sth    = $self->{dbh}->prepare($single)  or $self->die();
    my $rh     = $sth->execute  or $self->die();
#    my $hrow   = $sth->fetchrow_hashref;
    my @fields = @{ $sth->{NAME_lc} };
#   sort keys %$hrow;
    return @fields;
}

#
# field_values: obtain a list of possible field values for a linked field.
#
sub field_values {
    my $self  = shift;
    my $field = shift;
    my ($fname, $table, $id);
    if ( $field < scalar @{$self->{non_linked}}  ) {
	$fname = $self->{non_linked}->[$field];
	$id    = $self->{primary_key};
	$table = $self->{table};
    }
    else {
	$field -= scalar @{$self->{non_linked}};
	$fname = $self->{linked_values}->[$field];
	$id    = $self->{linked_refs}->[$field];
	$table = $self->{linked_tables}->[$field];
    }

    my $q = 'SELECT  DISTINCT '.$fname.' FROM '.$table.' ORDER BY '.$fname.';';

    #$self->debug('Field Values:'.$q);

    my $sth = $self->{dbh}->prepare($q) or $self->die();
    $sth->execute() or $self->die();

    my $rv = [];
    while (my @line = $sth->fetchrow_array()){
	push @{ $rv }, $line[0]; 
    }
    return $rv;
}

#
# pkey_name: primary key field name
#
sub pkey_name {
    my $self = shift;
    return $self->{table}.'_primary_key';
}

#
# set_syntax: set some syntax specific to some drivers. This include,
# clause order, clause construction (LIMIT and OFFSET), ILIKE
# construction and globbing character.
#
sub set_syntax {

    my $self = shift;

    # generic  clause order
    $self->{syntax_order} = {
	1 => 'where',
	2 => 'group',
	3 => 'having',
	4 => 'order',
	5 => 'limit',
	6 => 'offset'
	};

    # generic syntax 
    $self->{syntax} = {
	'where'  => ' AND ',
	'group'  => ' GROUP BY ',
	'having' => ' HAVING ',
	'order'  => ' ORDER BY ',
	'limit'  => ' LIMIT ',
	'offset' => ' OFFSET ',
	'ilike'  => ' ~*  ',
	'glob'   => '%'
	};

    #
    # Standards? Ha!
    #
    # mysql: the LIMIT OFFSET clauses are LIMIT [offset],limit; the LIKE
    # is an ILIKE.
    #
    if ( $self->{dbh}->{Driver}->{Name} =~ m/mysql/i ) {
	$self->{syntax}->{limit}  = ',';
	$self->{syntax}->{offset} = ' LIMIT ';
	$self->{syntax}->{ilike}  = ' LIKE ';
	$self->{syntax_order}->{5} = 'offset';
	$self->{syntax_order}->{6} = 'limit';
    } # postgres: (I)LIKE uses regular expression operator
    elsif ( $self->{dbh}->{Driver}->{Name} =~ m/pg/i ) {
	$self->{syntax}->{ilike} = ' ~* ';
	$self->{syntax}->{glob}   = '';
    }
    # put yours here...
}

#
# debug: print debug.
#
sub debug {
    my $self = shift;
    return (0) unless $self->{debug};
    my $txt  = shift;
    print ref($self),' : ', $txt,"\n"
	if ($txt);
    return 1;
}

#
# sprint: dump the internal structure.
#
sub sprint {
    my $self = shift;
    my $s    = ref($self)."\n";
    foreach my $tag ( sort keys %$self ) {
	$s .= "\t".$tag."\n";
	my $type = ref($self->{$tag});
	if ( $type eq 'HASH') {
	    foreach my $k ( sort keys %{$self->{$tag}} ) {
		$s .= "\t\t".$k."\t=> ".$self->{$tag}->{$k}."\n";
	    }
	}
	elsif ($type eq 'ARRAY') {
	    $s .= "\t\t(".join(",", @{$self->{$tag}}).")\n";
	}
	else {
	    $s .= "\t\t".$self->{$tag}."\n";
	}
    }
    return("$s");
}

#
# die: die from database errors printing the error.
#
sub die {
    my $self = shift;
    my $dbh  = $self->{dbh};
    my $err  = $dbh->errstr || 'Unknown DBI error';
    my @caller = caller;

    $self->print_error(
		       'Error from database: '.$err."\n".
		       'At '.$caller[0].', '.$caller[1].' line '.$caller[2].'.'
		       );

    $dbh->rollback();
    exit();
}

#
# print_error: print an error.
#
sub print_error {
    my $self  = shift;
    my $error = shift;

    warn($error);
}

#########################################################################
1;
#
#
#
__END__

=head1 NAME

DBIx::Browse - Perl extension to browse tables.

=head1 SYNOPSIS

  use DBIx::Browse;
  my ($dbh, $dbb, $q);
  $dbh = DBI->connect("DBI:Pg:dbname=enterprise")
    or croak "Can't connect to database: $@";
 $dbixbr = new  DBIx::Browse({
    dbh => $dbh, 
    table => 'employee', 
    proper_fields => [ qw ( name fname ) ],
    linked_fields => [ qw ( department category office ) ], 
    linked_tables => [ qw ( department category office ) ], 
    linked_values => [ qw ( name       name     phone  ) ], 
    linked_refs   => [ qw ( id         id       ide    ) ],
    aliases       => [ qw ( name fname department category phone )],
    primary_key   => 'id'
});

    ## Insert a record
    $dbixbr->insert({
	name       => 'John',
        department => 'Sales',
        category   => 'Sales Representant',
	phone      => '1114'
    });

    ## Update a record
    $dbixbr->update({
	record => { phone => '1113', category => 'Sales Manager' }
	where  => 'id = 123 ' 
    });

...etc

=head1 DESCRIPTION

The purpose of DBIx::Browse is to handle the browsing of relational
tables.

DBIx::Browse transparently translates SELECTs, UPDATEs, DELETEs and INSERTs
from the desired "human view" to the values needed for the table. This is the
case when you have related tables (1 to n) where the detail table
has a reference (FOREIGN KEY) to a generic table (i.e. Customers and
Bills) with some index (tipically an integer).

=head1 METHODS

=over 4

=item B<new>

Creates a new DBIx::Browse object. The parameters are passed
through a hash with the following keys:

=over 4

=item I<dbh>

A DBI database handle already opened that will be used for all
database interaction.

=item I<table>

The main (detail) table to browse.

=item I<primary_key>

The primary key of the main I<table> (default: I<'id'>).

=item I<proper_fields>

An array ref of field names of the main table that are not related
to any other table.

=item I<linked_fields>

An array reference of field names of the main table that are related
to other tables.

=item I<linked_tables>

An array reference of related table names corresponding to each
element of the I<linked_fields> parameter (defaults to the
corresponding name in I<linked_fields>).

=item I<linked_values>

The "human" values of each I<linked_fields> (a field name of the
corresponding I<linked_tables> element, default: 'name').

=item I<linked_refs>

The foreign key field name that relates the values of the
I<linked_fields> with the I<linked_tables> (default: 'id').

If present, I<linked_tables>, I<linked_values> and I<linked_refs> must
have the same number of elements than I<linked_fields>.

=item I<aliases>

An array ref containing the field aliases (names that will be
displayed) of the table. This must include all, proper and linked
fields.

=item I<debug>

If set, it will output a lot of debug information.

=back

=item B<prepare>

It will create a statement handle (see DBI manpage) suited so that the
caller does not need to explicitly set the "WHERE" clause to reflect
the main table structure and relations, just add the interesting
part. For example, using an already initialized DBIx::Browse object,
you can "prepare" like this:

    my $dbixbr = new DBIx::Browse({
	table         => 'employee',
        proper_fields => 'name',
        linked_fields => ['departament','category']
    })

 (...)

    $my $sth = $dbixbr->prepare({
	where => "departament = 'Adminitstration' AND age < 35",
        order => "name ASC, departament ASC"
	}

instead of:

     $my $sth = $dbh->prepare(
 "SELECT employee.name AS name, 
        departament.name AS departament, 
        category.name AS category
  FROM employee, departament, category
  WHERE departament.id   = employee.departament AND
        category.id      = employee.category    AND
        departament.name = 'Administration'     AND
        employee.age     < 35
  ORDER BY employee.name ASC, departament.name ASC"
			      );

All parameters are passed in a hash reference containig the following
fields (all optional):

=over 4

=item I<where>

The WHERE clause to be I<added> to the query (after the join conditions).

=item I<group>

The "GROUP BY" clause.

=item I<having>

The "HAVING" clause.

=item I<order>

The "ORDER BY" clause.

=item I<limit>

The "LIMIT" clause.

=item I<offset>

The "OFFSET" clause.

=back

The last column will always be the declared primary key for the main
table. The column name will be generated with the B<pkey_name> method.

=item B<pkey_name>

It returns the primary key field name that will be the last field in a
prepared statement.

=item B<count>

It will return the number of rows in a query. The hash reference
parameter is the same than the B<prepare> method.

=item B<insert>

This method inserts a new row into the main table. The input parameter
is a hash reference containing the field names (keys) and values of
the record to be inserted. The field names must correspond to those
declared when calling the B<new> method in the aliases parameter. Not
all the field names and values must be passed as far as the table has
no restriction on the missing fields (like "NOT NULL" or "UNIQUE").

=item B<update>

This method updates rows of the main table. It takes two parmeters:

=over 4

=item I<record>

A hash reference containing the field names as keys with the
corresponding values.

=item I<where>

The "WHERE" clause of the "UPDATE".

=back

=item B<delete>

This method deletes a row in the main table. It takes one parameter:
I<pkey>, the value of the primary key of the row to delete. Multiple
deletes are not allowed and should be addressed directly to the DBI
driver.

=item B<field_values>

This method returns an array reference with the list of possible field
values for a given field in the main table. It takes one parameter:

I<field_number>: An index indicating the field number (as declared in
the B<new> method). If the field is a linked field (related to other
table) it will return the values of the related table (as described by
I<linked_table>, and I<linked_values> in the B<new> method).

=back

=head1 RESTRICTIONS

The DBI driver to use MUST allow to set I<AutoCommit> to zero.

The syntax construction of queries have only been tested against
PostgreSQL and MySQL (DBD::mysql version 2.0416 onwards).

Not all the clauses are supported by all DBI drivers. In particular,
the "LIMIT" and "OFFSET" ones are non SQL-standard and have been only
tested in PostgresSQL and MySQL (in this later case, no especific
OFFSET clause exists but the DBIx::Browse simulates it by setting
accordingly the "LIMIT" clause).

=head1 BUGS

This is beta software. Please, send any comments or bug reports to the author
or visit http://sourceforge.net/projects/dbix-browse/

=head1 AUTHOR

Evilio José del Río Silván, edelrio@icm.csic.es

=head1 SEE ALSO

perl(1), DBI(3).

=cut
