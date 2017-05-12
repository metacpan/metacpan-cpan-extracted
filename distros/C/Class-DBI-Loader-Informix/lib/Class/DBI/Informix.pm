package Class::DBI::Informix;

use strict;
require Class::DBI;
use base qw(Class::DBI);
use vars qw($VERSION);

$VERSION = '1.4';

=head1 NAME

Class::DBI::Informix - Class::DBI extension for Informix

=head1 SYNOPSIS

  use strict;
  use base qw(Class::DBI::Informix);

  __PACKAGE__->set_db(Main => 'dbi:Informix:stores');
  __PACKAGE__->set_up_table('customer');

=head1 DESCRIPTION

This module implements a sub class of L<Class::DBI> that provides for
some of the quirks of the Informix databases. You should probably be
using this module rather than L<Class::DBI> if you are working with an
Informix database.

It provides one public method set_up_table() that will setup the columns 
and the primary key for the specified table.

=cut

sub _croak 
{ 
   require Carp; 
   Carp::croak(@_); 
}

=over 2

=item set_up_table

Determines the Primary key and column names for the given table
will be called by Class::DBI::Loader

=back

=cut

sub set_up_table
{
    my ( $class, $table ) = @_;
    my $dbh     = $class->db_Main;

    # DBIs primary_key_info doesn't work for informix
    # Oh yes the storage of indexes really is that nasty
    my $sth = $dbh->prepare(<<"SQL");
SELECT p1.colname,
       p2.colname,
       p3.colname,
       p4.colname,
       p5.colname,
       p6.colname,
       p7.colname,
       p8.colname,
       p9.colname,
       p10.colname,
       p11.colname,
       p12.colname,
       p13.colname,
       p14.colname,
       p15.colname
 from sysconstraints
join systables
on sysconstraints.tabid = systables.tabid
join sysindexes on sysconstraints.idxname = sysindexes.idxname
left outer join syscolumns as p1 on p1.colno = sysindexes.part1 and p1.tabid = systables.tabid
left outer join syscolumns as p2 on p2.colno = sysindexes.part2 and p2.tabid = systables.tabid
left outer join syscolumns as p3 on p3.colno = sysindexes.part3 and p3.tabid = systables.tabid
left outer join syscolumns as p4 on p4.colno = sysindexes.part4 and p4.tabid = systables.tabid
left outer join syscolumns as p5 on p5.colno = sysindexes.part5 and p5.tabid = systables.tabid
left outer join syscolumns as p6 on p6.colno = sysindexes.part6 and p6.tabid = systables.tabid
left outer join syscolumns as p7 on p7.colno = sysindexes.part7 and p7.tabid = systables.tabid
left outer join syscolumns as p8 on p8.colno = sysindexes.part8 and p8.tabid = systables.tabid
left outer join syscolumns as p9 on p9.colno = sysindexes.part9 and p9.tabid = systables.tabid
left outer join syscolumns as p10 on p10.colno = sysindexes.part10 and p10.tabid = systables.tabid
left outer join syscolumns as p11 on p11.colno = sysindexes.part11 and p11.tabid = systables.tabid
left outer join syscolumns as p12 on p12.colno = sysindexes.part12 and p12.tabid = systables.tabid
left outer join syscolumns as p13 on p13.colno = sysindexes.part13 and p13.tabid = systables.tabid
left outer join syscolumns as p14 on p14.colno = sysindexes.part14 and p14.tabid = systables.tabid
left outer join syscolumns as p15 on p15.colno = sysindexes.part15 and p15.tabid = systables.tabid
where systables.tabname = ? 
and constrtype = 'P'
SQL
    $sth->execute($table);
    my @primary = grep { defined $_ } $sth->fetchrow_array;
    $sth->finish;

    $sth = $dbh->prepare(<<"SQL");
select colname
from systables
join syscolumns on syscolumns.tabid = systables.tabid
where systables.tabname = ?
SQL
    $sth->execute($table);
    my @cols = map { $_->[0] } @{$sth->fetchall_arrayref};
    $sth->finish;

    _croak("$table has no primary key") unless @primary;
    $class->table($table);
    $class->columns( Primary => @primary );
    $class->columns( All     => @cols );
}

# It appears that none of the methods that DBI::Class uses to
# obtain the last serial value work.
sub _auto_increment_value 
{
   my ($self) = @_;
   my $dbh  = $self->db_Main();

   my $id = $dbh->{ix_sqlerrd}[1] 
      or  $self->_croak("Can't get last insert id");

   return $id;
}


=head1 BUGS
                                                                                
This has only tested with IDS 9.40.UC2E1 and 10.UC5 and could well be using
specific features of those databases.  If reporting a bug please
specify the server version that use are using.
                                                                                
                                                                                
=head1 SUPPORT
                                                                                
All bug reports and patches should be made via RT at:
                                                                                
   bug-Class-DBI-Loader-Informix@rt.cpan.org

That way I'm less likely to ignore them.
                                                                                   

=head1 SEE ALSO

L<Class::DBI> L<Class::DBI::mysql> L<DBD::Informix>

=head1 AUTHOR

Jonathan Stowe <jns@gellyfish.com>

=head1 LICENSE

This library is free software - it comes with no warranty whatsoever.
                                                                                
  Copyright (c) 2006 Jonathan Stowe

This module can be distributed under the same terms as Perl itself

=cut

1;
