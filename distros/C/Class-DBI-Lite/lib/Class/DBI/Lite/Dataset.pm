
package 
Class::DBI::Lite::Dataset;

use strict;
use warnings 'all';
use Carp 'confess';
use POSIX 'ceil';
use SQL::Abstract;


sub new
{
  my ($class, %args) = @_;
  
  foreach(qw( sort_field sort_dir page_number page_size filters ))
  {
    confess "Required param '$_' was not provided"
      unless $args{$_};
  }# end foreach()
  
  # One of the following must be present:
  unless( $args{type} || ( $args{data_sql} && $args{count_sql} ) )
  {
    confess "Either type OR data_sql AND count_sql must be provided";
  }# end unless()
  
  my $s = bless \%args, $class;
  $s->init;
  
  return $s;
}# end new()


sub init { }


sub execute
{
  my ($s, $dbh) = @_;
  
  confess "Usage: \$ds->execute(\$dbh)" unless $dbh;
  
  my ($filters, @vals) = $s->where;
  
  my $count_sql = $s->count_sql( $filters );
  warn "CountSQL($count_sql)" if $s->{debug};
  
  my $data_sql = $s->data_sql( $filters );
  warn "DataSQL($data_sql)" if $s->{debug};
  
  my $count_sth = $dbh->prepare( $count_sql );
  $count_sth->execute( @vals );
  my ($total_count) = $count_sth->fetchrow;
  $count_sth->finish();
  
  my $page_count = $s->_get_page_count( $s->{page_size}, $total_count );
  
  my $data_sth = $dbh->prepare( $data_sql );
  $data_sth->execute( @vals );
  
  return {
    sth         => $data_sth,
    count_sql   => $count_sql,
    data_sql    => $data_sql,
    total_items => $total_count,
    page_number => $s->{page_number},
    page_size   => $s->{page_size},
    sort_field  => $s->{sort_field},
    sort_dir    => $s->{sort_dir},
    sql_args    => \@vals,
    page_count  => $page_count,
    show_prev   => $s->{page_number} > 1,
    show_next   => $s->{page_number} < $page_count,
  };
}# end execute()


sub where
{
  my $s = shift;
  
  return SQL::Abstract->new->where( $s->{filters} );
}# end where()


sub count_sql
{
  my ($s, $filters) = @_;
  
  if( $s->{count_sql} )
  {
    return $filters ? join " ", ( $s->{count_sql}, $filters ) : $s->{count_sql};
  }# end if()
}# end count_sql()


sub data_sql
{
  my ($s, $filters) = @_;
  
  my $sql;
  if( $s->{data_sql} )
  {
    $sql = $filters ? join " ", ( $s->{data_sql}, $filters ) : $s->{data_sql};
  }# end if()
  
  $sql .= $s->_order_clause();
  $sql .= $s->_limit_clause();
  
  return $sql;
}# end data_sql()


sub _order_clause
{
  my $s = shift;
  
  return " ORDER BY @{[ $s->{sort_field} ]} @{[ $s->{sort_dir} ]}";
}# end _order_clause()


#==============================================================================
sub _limit_clause
{
  my $s = shift;
  
  my $offset = $s->{page_number} == 1 ? 0 : ($s->{page_number} - 1) * $s->{page_size};
  my $limit = " LIMIT $offset, @{[ $s->{page_size} ]} " if $s->{page_size};
  
  return $limit;
}# end _limit_clause()


sub _get_page_count
{
  my ($s, $page_size, $total) = @_;
  if( ! $page_size || $total <= $page_size )
  {
    return 1;
  }
  else
  {
    return POSIX::ceil($total / $page_size);
  }# end if()
}# end _get_page_count


1;# return true:

