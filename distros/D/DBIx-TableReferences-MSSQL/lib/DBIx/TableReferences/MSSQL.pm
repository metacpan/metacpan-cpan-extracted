
package DBIx::TableReferences::MSSQL;

use strict;
use warnings;
use Carp;
use DBI;

our ($VERSION) = '0.04';

sub new {
    my ($class,$dbh) = @_;
    
    carp "Can't instantiate $class without database handle" unless $dbh;

    my $self = {
        dbh => $dbh, 
        refs => _tablereferences($dbh)
    };
    
    bless $self, $class;
}

sub reftables { references (@_) }

sub references    { 
    my ($self,$tablename) = @_;

    my $owner ='dbo';
    if ($tablename =~ /(\w+)\.\w+$/) { 
        $owner = lc $1; 
        $tablename =~ s/\w+\.(\w+)$/$1/; 
    }
    
    my @refs = grep {
        (lc($_->{owner}) eq lc($owner))
        and 
        (lc($_->{table}) eq lc($tablename))
    } @{$self->{refs}};
    
    wantarray ? 
        # return table names if called in list context
        map {"$_->{refowner}.$_->{reftable}"} @refs 
        : 
        \@refs; 
    
}

sub _tablereferences {

    # Gets information about FK->PK table relationships

    my ($dbh,$table) = @_;
    
    my $sql =qq{
        select 
            object_name(r.constid)  as [constraint_name],
            object_name(r.fkeyid)   as [fk_tablename], 
            user_name(ofk.uid)      as [fk_tableowner],
            object_name(r.rkeyid)   as [pk_tablename], 
            user_name(opk.uid)      as [pk_tableowner],
            ObjectProperty(r.constid, 'CnstIsDeleteCascade') 
                                    as [OnDeleteCascade],
            ObjectProperty(r.constid, 'CnstIsUpdateCascade') 
                                    as [OnUpdateCascade],
            ObjectProperty(r.constid, 'CnstIsNotRepl') 
                                    as [NotForReplication]
    };
    
    $sql .= ", col_name(r.fkeyid,r.fkey$_) as [fkeycol$_]\n" for 1..16;

    $sql .= ", col_name(r.rkeyid,r.rkey$_) as [pkeycol$_]\n" for 1..16;

    $sql .=qq{
        from sysreferences r
        
        inner join sysobjects opk
            on r.rkeyid = opk.id
            
        inner join sysobjects ofk
            on r.fkeyid = ofk.id
    };

    my @relationships;

    for my $ref (@{$dbh->selectall_arrayref($sql)}) {

        my ($constraint, $table, $owner, $reftable, $refowner) = @{$ref}[0..4];
        
        my $del_casc    = $ref->[5] ? ' ON DELETE CASCADE'   : '';
        my $upd_casc    = $ref->[6] ? ' ON UPDATE CASCADE'   : '';
        my $not_for_rep = $ref->[7] ? ' NOT FOR REPLICATION' : '';
        
        my @cols        = grep {defined} @{$ref}[8..23];
        my @refcols     = grep {defined} @{$ref}[24..39];
        
        push @relationships, {
            constraint  => $constraint, # Constraint name
            table       => $table,      # FK table (this table)
            owner       => $owner,      # owner of FK table
            reftable    => $reftable,   # PK table
            refowner    => $refowner,   # owner of PK table
            cols        => [@cols],     # FK cols
            refcols     => [@refcols],  # PK cols
            sql_add     => "ALTER TABLE [$owner].[$table]\n"
                        . "ADD CONSTRAINT [$constraint] FOREIGN KEY (\n\t" 
                        . join(',', map {"[$_]"} @cols) . "\n)\n"
                        . "REFERENCES [$refowner].[$reftable] (\n\t" 
                        . join(',', map {"[$_]"} @refcols) . "\n)"
                        . $del_casc . $upd_casc . $not_for_rep ,
            sql_drop    => "ALTER TABLE [$owner].[$table] DROP CONSTRAINT [$constraint]"

        }    
    }

    \@relationships;
       
}

1;

__END__

=pod

=head1 NAME

DBIx::TableReferences::MSSQL -- Perl extension for getting information about declared referential constraints in MS SQL Server 2000 databases.

=head1 SYNOPSIS

    use DBIx::TableReferences::MSSQL;

    $tr = DBIx::TableReferences::MSSQL->new( $dbh );

    my $table = 'sales';

    @reftables = $tr->reftables($table);

    print "'$table' references these tables: @reftables\n";

Output (assuming C<$dbh> is connected to the C<pubs> database)

    'sales' references these tables: dbo.stores dbo.titles

Want more information?

    $refdetails = $tr->references('sales');

    for $ref (@{$refdetails}) {
        
        # The owner.name of the referenced table
        print "$ref->{refowner}.$ref->{reftable}\n";
        
        # columns in the referential constraint
        @fkeys = @{$ref->{cols}};    # FK
        @rkeys = @{$ref->{refcols}}; # PK

        while ($fkey = shift @fkeys, $rkey = shift @rkeys) {
            print "\t$fkey -> $rkey\n"
        }
    }

Output (showing the columns involved in the referential constraints)

    dbo.stores
            stor_id -> stor_id
    dbo.titles
            title_id -> title_id

=head1 DESCRIPTION

DBIx::TableReferences::MSSQL aims to provide information about declared table relationships, aka table references, in MS SQL Server 2000 databases.

To say that I<table A references table B> is a shortcut for saying I<table A has a foreign key that exists as a primary key in table B>.

=head1 METHODS

=head2 new

    $tr = DBIx::TableReferences::MSSQL->new($dbh);

Instantiates and returns the object. Retrieves all table reference information from the database and stores it internally, ready for querying via C<tablerefs> or C<references>.

You must pass this method a valid DBI connection to a MS SQL Server 2000 database, shown here as C<$dbh>.

=head2 tablerefs

    @tables = $tr->tablerefs('titles');
    print $_,"\n" for @tables;

Returns a list of tables that are referenced by the table 'dbo.titles'. If you do not specify the owner of the table, 'dbo' is assumed.

C<tablerefs> is just a wrapper method that calls C<references> in list context.

=head2 references

    @tables = $tr->references('titles'); # list context

Returns a list of table names exactly as though you had called $tr->tablerefs('titles').

    $refs = $tr->references('titles'); # scalar context

Returns a reference to an array of hashes with the following structure -     

    $refs = [
                {
                    'owner'      => 'dbo',
                    'table'      => 'titles',
                    'cols'       => [
                                      'pub_id'
                                    ],
                    'refowner'   => 'dbo',
                    'reftable'   => 'publishers',
                    'refcols'    => [
                                      'pub_id'
                                    ],
                    'sql_add'    => 'ALTER TABLE [dbo].[titles] ADD CONSTRAINT ...',
                    'sql_drop'   => 'ALTER TABLE [dbo].[titles] DROP CONSTRAINT ...',
                    'constraint' => 'FK__titles__pub_id__619B8048'
                } 
            ];


=over

=item * C<owner>

The owner of the table in question. Often 'dbo', since that is the default owner.

=item * C<table>

The name of the table in question.

=item * cols

A list of columns in C<table> that participate in the referential constraint.  There is often just one column, but there can be up to sixteen.  These columns constitute a B<foreign key> in C<table>.

=item * C<refowner>

The owner of the related table.

=item * C<reftable>

The name of the related table.

=item * refcols

A list of columns in C<reftable> that participate in the referential constraint.  There is often just one column but there can be up to sixteen. These columns constitute the B<primary key> in C<reftable>.

=item * sql_add

A runnable SQL statement that will add (create) the referential constraint.

Examples - 

    ALTER TABLE [dbo].[titles]
    ADD CONSTRAINT [FK__titles__pub_id__619B8048] FOREIGN KEY (
        [pub_id]
    )
    REFERENCES [dbo].[publishers] (
        [pub_id]
    )

Two columns in this relationship -

    ALTER TABLE [dbo].[titles]
    ADD CONSTRAINT [FK__titles__contrived] FOREIGN KEY (
        [pub_id], [title_id]
    )
    REFERENCES [dbo].[contrived_table] (
        [pub_id], [title_id]
    )

=item * sql_drop

A runnable SQL statement that will drop the referential constraint.

Example - 

    ALTER TABLE [dbo].[titles] 
    DROP CONSTRAINT [FK__titles__pub_id__619B8048]

=item * constraint

The name of the foreign key constraint. If a name was not supplied to MSSQL when the constraint was first created, it will tend to look a bit random, like this: C<FK__titles__pub_id__619B8048>.

=back

=head1 EXAMPLES

This example prints all the referential constraints as DROP statements and then as ALTER statements.

    use strict;
    use warnings;
    use DBIx::TableReferences::MSSQL;
    use DBC; # my custom database connector

    my $dbh = DBC->connect({database => 'pubs'});

    my $tr = DBIx::TableReferences::MSSQL->new( $dbh );

    my $sql = "select user_name(uid), name from sysobjects where xtype='U'";
    my @tables = map {"$_->[0].$_->[1]"} @{$dbh->selectall_arrayref($sql)};

    for my $table (@tables) {

        my $r = $tr->references('titles');

        for my $ref (@{$tr->references($table)}) {
            print $ref->{sql_drop},"\n";
        }
    }

    for my $table (@tables) {
        for my $ref (@{$tr->references($table)}) {
            print $ref->{sql_add},"\n";
        }
    }

=head1 AUTHOR

Edward Guiness <EdwardG@cpan.org>

=head1 DEPENDENCIES

The structure of the MS SQL 2000 sysreferences table.  

=head1 EXPORTS

None by default.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Edward Guiness

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
