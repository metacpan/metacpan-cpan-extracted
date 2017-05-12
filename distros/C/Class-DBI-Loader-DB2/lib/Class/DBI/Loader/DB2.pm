package Class::DBI::Loader::DB2;
use strict;
use DBI;
use Carp ();
require Class::DBI::DB2;
require Class::DBI::Loader::Generic;
use base qw(Class::DBI::Loader::Generic);
use vars qw($VERSION);

$VERSION = '0.14';

sub _croak { require Carp; Carp::croak(@_); }
sub _load_classes {
    my $self = shift;
    my $dbh = DBI->connect(@{$self->_datasource}) or _croak($DBI::errstr);
    foreach my $table($dbh->tables( { 'TABLE_TYPE' => 'TABLE' } ) ) {
      my $sth = $dbh->prepare(<<"SQL");
SELECT c.COLNAME FROM SYSCAT.KEYCOLUSE kc, SYSCAT.TABCONST tc,  SYSCAT.COLUMNS c
WHERE kc.CONSTNAME=tc.CONSTNAME AND kc.TABSCHEMA=tc.TABSCHEMA
AND kc.TABNAME=tc.TABNAME AND kc.TABSCHEMA=c.TABSCHEMA AND
kc.TABNAME=c.TABNAME AND kc.COLNAME=c.COLNAME AND kc.TABSCHEMA = ? AND
kc.TABNAME = ? AND tc.TYPE = 'P' ORDER BY kc.COLSEQ
SQL
      my ($tabschema,$tbl) = split '\.', $table;
      $sth->execute( uc($tabschema), uc($tbl) );
      my $primaries = $sth->fetchall_arrayref;
      $sth->finish;
      my ( @primary );
      map { push @primary, $_ } @$primaries;

      if ( @primary ) {
        my $class = $self->_table2class(lc($table));
	no strict 'refs';
	@{"$class\::ISA"} = qw(Class::DBI::DB2);
	$class->set_db(Main => @{$self->_datasource});
        my $alias = $table;
        $alias =~ s/\./_/;
	$class->set_up_table(lc($table),$alias);
	$self->{CLASSES}->{$table} = $class;
      }
    }
    $dbh->disconnect;
}

1;

__END__

=head1 NAME

Class::DBI::Loader::DB2 - Class::DBI::Loader DB2 implementation.

=head1 SYNOPSIS

  use Class::DBI::Loader;

  # $loader is a Class::DBI::Loader::DB2
  my $loader = Class::DBI::Loader->new(
    dsn => "dbi:DB2:dbname",
    user => "root",
    password => "",
    namespace => "Data",
  );
  my $class = $loader->find_class('film'); # $class => Data::Film
  my $obj = $class->retrieve(1);

=head1 DESCRIPTION

please see L<Class::DBI::Loader>

=head1 AUTHOR

Mark Ferris E<lt>mark.ferris@geac.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2004 Mark Ferris. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI::Loader>

=cut
