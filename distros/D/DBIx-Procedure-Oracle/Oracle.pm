package DBIx::Procedure::Oracle;

$VERSION = 0.2;

use DBI qw( :sql_types );
# sql_types are needed for binding dates and numbers
# ORA_NUMBER and ORA_DATE don't work but SQL_NUMERIC etc. do
use DBD::Oracle qw( :ora_types );
# but we do need ora_types so that we can bind cursors as ORA_RSET

sub new {
    my ($self,$dbh,%resolve) = @_;
    my $class = ref $self || $self;
    my $usage = <<'EOF';
Usage: $proc = DBIx::Procedure::Oracle->new($dbh
                                           ,[ owner => 'oracle_user' ]
                                           ,[ package_name => 'oracle_package' ]
                                           ,object_name => 'oracle_procedure'
                                           );
EOF

    unless( UNIVERSAL::isa($dbh,'DBI::db') && $dbh->{Driver}->{Name} =~ /^Oracle$/i ){
        die "$class - First argument must be a valid DBI handle for Oracle";
    }
    die "$class - No procedure name provided.\n$usage" unless exists $resolve{object_name};
    my $this = bless {}, $class;
    $this->{-args} = resolve_procedure( $dbh, \%resolve );
    my $sql = generate_sql( \%resolve, $this->{-args} );
    $this->{-sth} = $dbh->prepare($sql);
    $this->{-sql} = $sql;
    return $this;
}

sub DESTROY { $_[0]->{-sth}->finish if exists $_[0]->{-sth} }

sub resolve_procedure ($\%) {
    my ($dbh,$resolve) = @_;
    # if we don't provide a user we'll assume that its the current oracle user
    # if we don't provide a package we'll assume that the procedure isn't in one
    # In future: allow named argument syntax as well as positional arguments
    my $sql =<<'EOF';
select argument_name, position, sequence, data_type, in_out
from all_arguments
where ( owner = :1 or ( :1 is null and owner = user ) )
and   ( package_name = :2 or ( :2 is null and package_name is null ) )
and   object_name = :3
order by position
EOF
    my $sth = $dbh->prepare($sql);
    $sth->bind_param(1, uc $resolve->{owner}        );
    $sth->bind_param(2, uc $resolve->{package_name} );
    $sth->bind_param(3, uc $resolve->{object_name}  );
    $sth->execute;
    my @rows;
    while( my $row = $sth->fetchrow_hashref ){
        if( $row->{DATA_TYPE} =~ /VARCHAR/ ){ # not CHAR
            $row->{SQL_TYPE} = { sql_type => SQL_VARCHAR() };
        }elsif( $row->{DATA_TYPE} =~ /NUMBER/ ){ # should handle all numbers
            $row->{SQL_TYPE} = { sql_type => SQL_NUMERIC() };
        }elsif( $row->{DATA_TYPE} =~ /CURSOR/ ){
            $row->{SQL_TYPE} = { ora_type => ORA_RSET() }; # oracle cursors
        }elsif( $row->{DATA_TYPE} =~ /CHAR/ ){ # but not VARCHAR (see above)
            $row->{SQL_TYPE} = { sql_type => SQL_CHAR() };
        }elsif(    $row->{DATA_TYPE} =~ /DATE/
                || $row->{DATA_TYPE} =~ /TIME/
                || $row->{DATA_TYPE} =~ /INTERVAL/ ){
            $row->{SQL_TYPE} = { sql_type => SQL_DATE() }; # types i have seen
        }else{ # don't know. Try our best.
            $row->{SQL_TYPE} = { sql_type => SQL_UNKNOWN_TYPE() }; # catch all
        }
        push @rows, $row;
    }
    $sth->finish;
    return \@rows;
}

sub generate_sql (\%\@) {
    my($resolve, $args) = @_;
    my $sql = "begin\n\t" ; # nicely formatted anonymous pl/sql block
    my $start = 0;
    if( @$args && $args->[0]->{POSITION} == 0 ){ # is a function!
        $sql .= ':1 := ';
        $start = 1;
    }
    $sql .= "$resolve->{owner}."          if exists $resolve->{owner};
    $sql .= "$resolve->{package_name}."   if exists $resolve->{package_name};
    $sql .= $resolve->{object_name};
    if( @$args ){
        $sql .= '('; # brackets only necessary when there are arguments
        for( my $i = $start; $i < @$args; $i++ ){
            $sql .= ":$args->[$i]->{SEQUENCE},";
        }
        $sql =~ s/,$//;
        $sql .= ')';
    }
    $sql .= ";\nend;";
    return $sql;
}

sub execute {
    my $this = $_[0];
    my $sth = $this->{-sth};
    my $retval;
    my $start = 0;
    my @args = @{ $this->{-args} };
    if( $args[0]->{POSITION} == 0 ){ # function
        $sth->bind_param_inout(1, \$retval, $args[0]->{SQL_TYPE} );
        $start = 1;
    }
    for( my $i = $start; $i < @args; $i++ ){
        if ( $args[$i]->{IN_OUT} eq 'IN' ){
            $sth->bind_param( $args[$i]->{SEQUENCE}
                             ,$_[ $args[$i]->{POSITION} ]
                             ,$args[$i]->{SQL_TYPE}
                            );
        }else{
            $sth->bind_param_inout( $args[$i]->{SEQUENCE}
                                   ,\$_[ $args[$i]->{POSITION} ]
                                   ,$args[$i]->{SQL_TYPE}
                                  );
        }
    }
    $sth->execute;
    return $retval; # because its undef it hasn't been used
}

1;

__END__

=head1 NAME

DBIx::Procedure::Oracle - Call PL/SQL stored procedures and functions without
writing SQL or needing to know about data types or bindings.


=head1 SYNOPSIS

 my $dbh = DBI->connect( 'DBI:Oracle:ORCL', 'scott', 'tiger'
                        ,{ PrintError => 0, RaiseError => 1 }
                       );

 $dbh->do( q{ CREATE FUNCTION test(days IN NUMBER) RETURN DATE AS
                  tmp_date DATE;
              BEGIN
                  SELECT sysdate - days INTO tmp_date FROM dual;
                  RETURN tmp_date;
              END;
           }
         );

 my $proc = DBIx::Procedure::Oracle->new( $dbh, object_name => 'test' );

 $date = $proc->execute(7); # 7 days ago

=head1 DESCRIPTION

This module allows the calling of Oracle PL/SQL functions and procedures
without writing SQL statements to reference them. It queries the Oracle system
table ALL_ARGUMENTS to resolve the procedure and determine the correct data
types and bindings ( IN, OUT or INOUT ) of the procedure parameters. From this
information an anonymous PL/SQL block is built and a database statement handle
constructed. At present only positional binding of parameters is supported
( as opposed to named parameters ).

=head1 CONSTRUCTOR

B<new>

$proc = DBIx::Procedure::Oracle->new(
             $dbh
            , [ owner        => 'owner'     ]
            , [ package_name => 'package'   ]
            ,   object_name  => 'procedure'
        );

Creates a new wrapped Oracle stored procedure. The first argument is a valid
database handle. The other arguments are a flattened hash with flags that help
to resolve the procedure. The keys are named directly after their column name
counterparts in the Oracle system table ALL_ARGUMENTS. The owner and
package_name flags are optional. If an owner is not provided then the logged on
Oracle user is assumed. If a package_name is not provided then it is assumed
that the function or procedure does not have a package. The object_name flag
must be present since it gives the name of the function or procedure.

Future work might allow full PL/SQL name resolution, for example;

owner.package.procedure

owner.procedure

See http://download-west.oracle.com/otndoc/oracle9i/901_doc/appdev.901/a89856/d_names.htm

=head1 METHODS

B<execute>

my $return_value = $proc->execute( [ PARAMS ] );

Executes the stored procedure. If it is a function then it will return a value
and this is returned from the perl subroutine. If it is a procedure then this
will not happen and as a default the execute method returns undef.

INOUT or OUT bound arguments to the execute method will have their values
returned by reference.

To test for the successful execution of the procedure, either check DBI->err
for the latest Oracle error, or set the DBI RaiseError flag to true and wrap
the execute call in an eval block.

=head1 BUGS

Please report them!

=head1 ACKNOWLEDGEMENT

Special thanks to Andrew Theaker ( andrew.j.theaker@gsk.com ) for providing me with the
rationalle behind this module back in the days when we used to work together!

=head1 AUTHOR

Mark Southern (mark_southern@merck.com)

=head1 COPYRIGHT

Copyright (c) 2002, Merck & Co. Inc. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

=cut
