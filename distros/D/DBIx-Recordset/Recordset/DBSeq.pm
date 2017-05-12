
###################################################################################
#
#   DBIx::Recordset - Copyright (c) 1997-2000 Gerald Richter / ECOS
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS IS BETA SOFTWARE!
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: DBSeq.pm,v 1.5 2000/06/26 05:16:18 richter Exp $
#
###################################################################################


package DBIx::Recordset::DBSeq ;

use strict 'vars' ;



## ----------------------------------------------------------------------------
##
## new
##
## creates a new DBIx::Recordset::DBSeq object. 
##
## $dbh          = Database handle
## $table        = table where to keep sequences
##

sub new

    {
    my ($class, $dbh, $table, $min, $max) = @_ ;
    


    my $self = {
                '*Debug'      => $DBIx::Recordset::Debug,
                '*dbh'        => $dbh,
                '*table'      => $table,
                '*DefaultMin' => $min || 1,
                '*DefaultMax' => $max || 'NULL',
               } ;

    bless ($self, $class) ;

    return $self ;
    }



## ----------------------------------------------------------------------------
##
## NextVal
##
## get next value from counter
##
## in   $name = counter name
##


sub NextVal 

    {
    my ($self, $name) = @_ ;

    my $dbh = $self -> {'*dbh'} ;
    
    $dbh -> do ("lock table $self->{'*table'} write") or die "Cannot lock $self->{'*table'} ($DBI::errstr)" ;



    my $sth = $dbh -> prepare ("select cnt,maxcnt from $self->{'*table'} where name=?") or die "Cannot prepare select for $self->{'*table'} ($DBI::errstr)" ;

    $sth -> execute ($name) ;

    my $row = $sth -> fetchrow_arrayref ;
    my $cnt ;
    my $max ;
    
    if (!$row)
        {
        $cnt = $self->{'*DefaultMin'} ;
        $max = $self->{'*DefaultMax'} ;
        my $cnt1 = $cnt + 1 ;
        $dbh -> do ("insert into $self->{'*table'} (name,cnt,maxcnt) values ('$name',$cnt1,$max)") or die "Cannot insert $self->{'*table'} ($DBI::errstr)" ;
        }
    else
        {
        $cnt = $row -> [0] ;
        die "Max count reached for sequence $name" if (defined ($row->[1]) && $cnt+1 > $row->[1]) ;
        $dbh -> do ("update $self->{'*table'} set cnt=cnt+1 where name='$name'") or die "Cannot update $self->{'*table'} ($DBI::errstr)" ;
        }

    $dbh -> do ("unlock table") or die "Cannot unlock $self->{'*table'} ($DBI::errstr)" ;
    
    return $cnt ;
    }

1;

__END__


=pod

=head1 NAME

DBIx::Recordset::DBSeq - Sequence generator in DBI database

=head1 SYNOPSIS

 use DBIx::Recordset::DBSeq ;

 $self = DBIx::Recordset::DBSeq ($dbh, 'sequences', $min, $max) ;
 
 $val1 = $self -> NextVal ('foo') ;
 $val2 = $self -> NextVal ('foo') ;
 $val3 = $self -> NextVal ('bar') ;
 

=head1 DESCRIPTION

DBIx::Recordset::FileSeq generates unique numbers. State is kept in the
one table of a database accessable via DBI. With the new constructor you
give an open database handle and sepcify the the table where state should be kept.
Optionaly you can give a min and
a max values, which will be used for new sequences.

With B<NextVal> you can get the next value
for the sequence of the given name.

The table must created in the following form:

create table
    (
    name    varchar (32),
    cnt     integer,
    maxcnt  integer,
    primary key name
    ) ;


If the sequence value reaches the maxcnt value, NextVal will die with an
error message. If maxcnt contains C<null> there is no limit.



=head1 AUTHOR

G.Richter (richter@dev.ecos.de)

=head1 SEE ALSO

=item DBIx::Recordset


=cut
    


