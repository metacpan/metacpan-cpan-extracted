
package Class::DBI::Lite::SQLite;

use strict;
use warnings 'all';
use base 'Class::DBI::Lite';
use Carp 'confess';
use Class::DBI::Lite::TableInfo;


#==============================================================================
sub set_up_table
{
  my $s = shift;
  
  # Get our columns:
  my $table = shift;
  $s->_init_meta( $table );
  $s->after_set_up_table;
  1;
}# end set_up_table()


#==============================================================================
sub get_tables
{
  my ($s, $schema) = @_;
  
  local $s->db_Main->{AutoCommit};
  my $sth = $s->db_Main->prepare(<<"");
select name
from sqlite_master
where type = 'table'
order by name

  $sth->execute();
  my @out = ( );
  while( my ($name) = $sth->fetchrow )
  {
    push @out, $name;
  }# end while()
  $sth->finish();
  
  @out ? return @out : return;
}# end get_tables()


#==============================================================================
sub get_meta_columns
{
  my ($s, $schema, $table) = @_;

  local $s->db_Main->{AutoCommit};
  my $sth = $s->db_Main->prepare(<<"");
    PRAGMA table_info( '$table' )

  # Simple discovery of fields and PK:
  $sth->execute( );
  my @cols = ( );
  my $PK;
  while( my $rec = $sth->fetchrow_hashref )
  {
    # Is this the primary column?:
    $PK = $rec->{name}
      if  $rec->{pk};
    push @cols, $rec->{name};
  }# end while()
  $sth->finish();
  
  confess "Table $table doesn't exist or has no columns"
    unless @cols;

  return {
    Primary   => [ $PK ],
    Essential => \@cols,
    All       => \@cols,
  };
}# end get_meta_columns()


#==============================================================================
sub after_set_up_table { }


#==============================================================================
sub get_table_info
{
  my $s = shift;
  my $class = ref($s) || $s;
  my $table = $class->table;
  my $cur = $class->db_Main->prepare("PRAGMA table_info('$table')");
  $cur->execute;
  
  my $info = Class::DBI::Lite::TableInfo->new( $class->table );
  
  my %key_types = (
    UNI => 'unique',
    PRI => 'primary_key'
  );
  
  while( my $res = $cur->fetchrow_hashref )
  {
    my ($type) = $res->{type} =~ m/^([^\(\)]+)/;
    my $length;
    if( $type =~ m/(text|varchar|char)/i )
    {
      ($length) = $res->{type} =~ m/\((\d+)\)/;
    }# end if()
    $info->add_column(
      name          => $res->{name},
      type          => lc($type),
      length        => $length,
      is_pk         => $res->{pk} ? 1 : 0,
      is_nullable   => $res->{notnull} ? 0 : 1,
      default_value => $res->{dflt_value},
      key           => undef,
    );
  }# end while()
  $cur->finish;
  
  return $info;
}# end get_table_info()


#==============================================================================
sub get_last_insert_id
{
  $_[0]->db_Main->func('last_insert_rowid');
}# end get_last_insert_id()

sub lock_table { }
sub unlock_table { }

1;# return true:

