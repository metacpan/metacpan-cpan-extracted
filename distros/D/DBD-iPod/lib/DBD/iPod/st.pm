=head1 NAME

DBD::iPod::st - the statement handle (sth)

=head1 SYNOPSIS

  $sth->execute();
  while(my $row = $sth->fetchrow_hashref()){
    #...
  }

You should really read the DBI perldoc if you don't get it.

=head1 DESCRIPTION

Statement handle implementation for the iPod.

=head1 AUTHOR

Author E<lt>allenday@ucla.edutE<gt>

=head1 SEE ALSO

L<DBD::_::st>.

=head1 COPYRIGHT AND LICENSE

GPL

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a '_'.  Methods are
in alphabetical order for the most part.

=cut

package DBD::iPod::st;
use strict;
our $VERSION = '0.01';
use base qw(DBD::_::st);

use vars qw($imp_data_size);

use DBD::iPod::row;
use DBI;
use Data::Dumper;

$imp_data_size = 0;

=head2 execute()

L<DBI>.

=cut

sub execute {
  my $sth = shift;
  my (@data, @columns);
  my ($ipod, $search, $statement, $item);

  # The Net::Google::Search instance
  $search = $sth->{'iPodSearch'};
  $statement = $sth->{'Statement'};

  # The names of the columns in which we are interested
  @columns = $statement->columns();

  # This is where fetchrow_hashref etc get their names from
  $sth->{'NAME'} = [ map { lc $_->name } @columns ];

  # This executes the search
  my($limit,$offset) = (999_999_999, 0);
  if($statement->{limit_clause}){
    $limit      = $statement->{limit_clause}->limit();  #sorry, have to do it
    $offset     = $statement->{limit_clause}->offset(); #sorry, have to do it
  }
  my $hit_offset = 0;
  for $item (@$search) {
    my (@this, $column);

    my $row = DBD::iPod::row->new($item);
    my $match = 1;
    if($statement->where()){
      $match = $row->is_match($statement->where());
    }

    if($match == 1){
      for $column (@columns) {
        my ($name, $method, $value, $function);
        $name = lc $column->name;
        $value = $item->{$name} || "";
        push @this, $value;
      }

      $hit_offset++;
      push @data, \@this if $hit_offset >= $offset;
      last if scalar(@data) == $limit;
    }
  }

  $sth->{'driver_data'} = \@data;
  $sth->{'driver_rows'} =  @data;
  $sth->STORE('NUM_OF_FIELDS', scalar @columns);

  return scalar @data || 'E0E';
}

=head2 fetchrow_arrayref()

L<DBI>.

=cut

sub fetchrow_arrayref {
  my $sth = shift;
  my ($data, $row);

  $data = $sth->FETCH('driver_data');

  $row = shift @$data
    or return;

  return $sth->_set_fbav($row);
}

=head2 fetch()

L<DBI>.

=cut

*fetch = *fetch = \&fetchrow_arrayref;

sub rows {
  my $sth = shift;
  return $sth->FETCH('driver_rows');
}

=head2 fetchrow_arrayref()

L<DBI>.  Returns "iPod".

=cut

# Returns available tables
sub table_info { return "iPod" }

1;

sub DESTROY { 1 }

__END__
