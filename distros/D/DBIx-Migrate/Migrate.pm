package DBIx::Migrate;

use strict;
use Carp;
use vars qw( $VERSION );
use DBI;
use Data::Dumper;
                                                                                
$VERSION=0.01;

my $data_types = { 
qw!
1 char
2 numeric
3 decimal
4 integer
5 smallint
6 float
7 real
8 double
9 date
10 time
11 timestamp
12 varchar
-1 text
-2 binary
-3 varbinary
-4 blob
-5 bigint
-6 tinyint
-7 bit
-8 wchar
-9 wvarchar
-10 wlongvarchar
! };

# Constructor
sub new {
    my($class, %parm) = @_;
    croak 'Expecting a class' if ref $class;

## don't overwrite target table if it already exists
    my $self = { CLOBBER => 0, 
                 TYPE_TRANSLATE => $data_types 
               }; 

## the lazy method
    while(my($k, $v) = each(%parm)) { $self->{$k} = $v};

## retrieve all tables in source database
    unless(%{ $self->{SOURCE_TABLES} } = map { $_ => 1 } $self->{SOURCE}->tables) {
      croak('no tables in source database'); 
    }

#  croak if requested source table doesn't exist
    for (@{ $self->{TABLES} }) {
        croak("source table: $_ not found")
          unless exists($self->{SOURCE_TABLES}{$_});
    }

## retrieve all tables in target database
    if( $self->{TARGET}->tables ) { 
        %{ $self->{TARGET_TABLES} } = map { $_ => 1 } $self->{TARGET}->tables;
    }

## check CLOBBER and croak if table already exists target database
    my @common = ();
    for (keys %{ $self->{SOURCE_TABLES} } ) {
        push(@common, $_) if exists $self->{TARGET_TABLES}{$_};
    }
    if( @common && !($self->{CLOBBER}) ) {
        croak("@common target table(s) already exist; set CLOBBER to overwrite");
    }
    bless $self, $class;
    return $self;
}

sub migrate {
    my ($self, %parm) = @_;
    my ($source, $target, $tbl_count);
## the lazy method
    while(my($k, $v) = each(%parm)) { $self->{$k} = $v };
    for my $table (@{ $self->{TABLES} })
    {
        $source = $self->{SOURCE}->prepare("SELECT * from $table");
        $source->execute();
                                                                                     
## Guess data types and precision of source table
        my $create = "CREATE TABLE $table (\n";
        for( my $i=0; $i <= $source->{NUM_OF_FIELDS}; $i++) {
            next unless( $source->{NAME}->[$i] && 
                         $source->{TYPE}->[$i] && 
                         $source->{PRECISION}->[$i]
                       );
            $create .= "$source->{NAME}->[$i] $self->{TYPE_TRANSLATE}{$source->{TYPE}->[$i]}";
            $create .= "($source->{PRECISION}->[$i])" unless($source->{TYPE}->[$i] == 9);

            $create .= " NOT NULL" unless($source->{NULLABLE}->[$i]);
            if ( $source->{NAME}->[$i+1] && 
                 $source->{TYPE}->[$i+1] && 
                 $source->{PRECISION}->[$i+1]
               )
            {
                $create .= ",\n";
            }
        }
        $create .= "\n)";

## Create target table using approximate data types and precision
## WARNING: TARGET TABLE IS DROPPED IF IT ALREADY EXISTS!
        $self->{TARGET}->do("DROP TABLE $table") 
          if(exists($self->{TARGET_TABLES}{$table}));
        $self->{TARGET}->do($create);
                                                                                     
## Create insertion fields
        my $fields = join(',', @{ $source->{NAME} });
        my $qmarks = join(',', (map { '?' } @{ $source->{NAME} }));
        $source->finish();
                                                                                     
my $select = qq!
SELECT $fields
FROM $table
!;
                                                                                     
my $insert = qq!
INSERT INTO $table ($fields)
VALUES ($qmarks)
!;
                                                                                     
        $source = $self->{SOURCE}->prepare($select);
        $target = $self->{TARGET}->prepare($insert);
                                                                                     
        $source->execute();
                                                                                     
        while (my $rows = $source->fetchrow_arrayref) {
            $target->execute(@{$rows});
        }
        $source->finish();
        $target->finish();
        $tbl_count++;
    }
    return $tbl_count;
}

1;
__END__

=head1 NAME

DBIx::Migrate - DBI extension for 'batch-mode' table migration 

=head1 SYNOPSIS

  use DBI;
  use DBIx::Migrate;

$source = DBI->connect('dbi:Oracle:dbase1', ...);

$target = DBI->connect('dbi:mysql:dbase2', ...);

$migration = 
    DBIx::Migrate->new(SOURCE => $source,
                       TARGET => $target,
    # optional         CLOBBER => 1,  
                       TABLES => [ qw(tbl1 tb12 ..etc..) ]
    # optional         TYPE_TRANSLATE => $hash_ref 
                      );

$tables_copied = $migration->migrate;  

=head1 DESCRIPTION

DBIx::Migrate is a DBI extension for 'batch-mode' table migration.  
Let's suppose you want to create a MySQL mirror of several related tables in an Oracle database.  
DBIx::Migrate will do just that.  
If the target MySQL table does not exist, an attempt is made to create a MySQL version of the original Oracle table structure.  
The big problem here is that not all databases use universal data types.  
So depending on the driver, you'll probably need to alter the TYPE_TRANSLATE parameter.  
By default, the TYPE_TRANSLATE parameter looks like this: 

TYPE_TRANSLATE = {
qw!
1 char
2 numeric
3 decimal
4 integer
5 smallint
6 float
7 real
8 double
9 date
10 time
11 timestamp
12 varchar
-1 text
-2 binary
-3 varbinary
-4 blob
-5 bigint
-6 tinyint
-7 bit
-8 wchar
-9 wvarchar
-10 wlongvarchar
! };

Please note that DBIx::Migrate does not create indexes on target tables.  You'll have to do that by hand.  

Also, a fatal error will result if you attempt to create a table that already exists in the target database.  If you want to override this behavior, set the CLOBBER parameter to true.  

=head1 SEE ALSO

http://www.gnusto.net is the official home page for DBIx::Migrate.

=head1 AUTHOR

Nathaniel Graham, E<lt>nate@gnusto.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Nathaniel Graham

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
