package Class::DBI::Loader::Informix;

use strict;
require Class::DBI::Informix;
require Class::DBI::Loader::Generic;
use base qw(Class::DBI::Loader::Generic);
use vars qw($VERSION);
use DBI;
use Carp;


$VERSION = '1.4';

=head1 NAME

Class::DBI::Loader::Informix - Class::DBI::Loader Informix Implementation.

=head1 SYNOPSIS

  use Class::DBI::Loader;

  my $loader = Class::DBI::Loader->new(
                                        dsn       => 'dbi:Informix:stores',
                                        user      => 'informix',
                                        password  => '',
                                        namespace => 'Stores',
                                      );

  my $class = $loader->find_class('customer'); 
  my $obj = $class->retrieve(1);

=head1 DESCRIPTION

L<Class::DBI::Loader> provides a mechanism of automatically setting
up the L<Class::DBI> sub-classes on demand.

This module provides the Informix specific methods required by
L<Class::DBI::Loader::Generic>.  The complete documentation can
be found in L<Class::DBI>

=cut

sub _db_class
{
    return 'Class::DBI::Informix';
}

sub _tables
{
    my ($self) = @_;
    my $dbh  = DBI->connect( @{ $self->{_datasource} } ) or croak($DBI::errstr);


    my @tables = map { /([^.]+$)/ and $1 } ($dbh->func('user','_tables'));
    return @tables;
}

sub _relationships
{
   my ($self) = @_;

   foreach my $table ( $self->tables() )
   {
      my $dbh = $self->find_class($table)->db_Main();

      my $sth = $dbh->prepare(<<SQL);
SELECT f.colname,
       d.tabname
  FROM systables a, 
       sysconstraints b, 
       sysreferences c,
       systables d, 
       sysindexes e, 
       syscolumns f
 WHERE b.constrtype = 'R'
   AND a.tabid = b.tabid
   AND b.constrid = c.constrid
   AND c.ptabid = d.tabid
   AND a.tabname = ? 
   AND b.idxname = e.idxname
   AND e.part1 = f.colno
   AND e.tabid = f.tabid
SQL
      $sth->execute($table);
      for my $fk  ( @{$sth->fetchall_arrayref()} )
      {
         eval
         {
            $self->_has_a_many($table, 
                               $fk->[0],
                               $fk->[1]);
         };
         warn qq/\# has_a_many failed "$@"\n\n/ if $@ && $self->debug;
      }
   }
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

L<Class::DBI::Loader>, L<Class::DBI::Loader::Generic>

=head1 AUTHOR

Jonathan Stowe <jns@gellyfish.com>

=head1 COPYRIGHT AND LICENSE

This library is free software - it comes with no warranty whatsoever.
        
  Copyright (c) 2006 Jonathan Stowe
               
This module can be distributed under the same terms as Perl itself.
                      
=cut

1;
