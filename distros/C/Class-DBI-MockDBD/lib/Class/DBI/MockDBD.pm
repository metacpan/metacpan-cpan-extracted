package Class::DBI::MockDBD;
use strict;
use warnings;

=head1 NAME

Class::DBI::MockDBD - Mocked database interface for Class::DBI

=head1 SYNOPSIS

use base qw(Class::DBI::MockDBD);

or

# probably nicer ways to do this ..  but classes won't need a single line of code changed (with any luck)

use ClassName;

unshift(@ClassName::ISA,'Class::DBI::MockDBD');

# set up result

ClassName->next_result([ [qw/foo_id foo_name foo_bar/],[1,'aaaa','bbbb',]...]);

# run query

my $iterator = ClassName->search(...);

# get sql and params for query

my $sql = ClassName->last_query_info('statement');

my $params = ClassName->last_query_info('params');

=head1 DESCRIPTION

A Class::DBI subclass allowing you to 'Mock' a database for testing
and/or debugging purposes, using DBD::Mock, via some additional
API methods.

=cut


use Carp;
# use Data::Dumper;

use overload ('bool'  => sub { return 1; } );
use base qw(Class::DBI Class::Data::Inheritable);

__PACKAGE__->mk_classdata('mocked_params');
__PACKAGE__->mk_classdata('mocked_statement');
__PACKAGE__->mk_classdata('mocked_statement_handle');

__PACKAGE__->connection('dbi:Mock:', '', '', {});

our $VERSION = '0.03';

=head1 METHODS

Calling a method that touches the database without specifying the results with next_result or
next_result_session method first will result in a fatal error.

=head2 next_result

This class method prepares the set of results to be provided to the next query made
to the mocked database.

# set up result before calling method that will interact with mocked database

ClassName->next_result([ [qw/foo_id foo_name foo_bar/],[1,'aaaa','bbbb',]...]);

ClassName->search(foo_bar => 'bbbb');

=head2 next_result_session

ClassName->next_result_session([
{ statement => 'select * from tablename where field = ?', results => [ .. ], bound_params => [ 10, qr/\d+/ ], },
{ statement => 'select * from tablename where field = ?', results => [ .. ], bound_params => [ 10, qr/\d+/ ], },
{ statement => 'select * from tablename where field = ?', results => [ .. ], bound_params => [ 10, qr/\d+/ ], },
]);

ClassName->search(foo_bar => 'bbbb');

=head2 last_query_info

This class method provides the statement and params of the last query to the mocked database.

my $sql = ClassName->last_query_info('statement');

my $params = ClassName->last_query_info('params');

It takes an argument specifying what information you want back : 'params' or 'statement'.

Query parameters are returned as an arrayref, SQL statement is returned as a string.

=cut

sub next_result {
  my ($class,$result) = @_;
  $class->db_Main->{mock_add_resultset} = $result;
  $class->mocked_statement_handle(undef);
  return;
};

sub next_result_session {
  my ($class,$results) = @_;
  my $session = DBD::Mock::Session->new('next_result_session' => (@$results) );
  $class->db_Main->{mock_session} = $session;
  $class->mocked_statement_handle(undef);
  return;
}

sub last_query_info {
  my ($class,$type) = @_;
  my $return;

  if ($type eq 'params') {
    my $sth = $class->mocked_statement_handle();
    croak("Class::DBI::MockDBD -- last_query_info can't be called with params without executing query") unless ($sth && ($sth->{mock_is_executed} eq 'yes'));
    $return = $class->mocked_params;
  } elsif ($type eq 'statement') {
    $return = $class->mocked_statement;
  } else {
    carp "Class::DBI::MockDBD -- $type not recognised as argument to last_query_info";
  }

  return $return;
}

=head1 METHODS OVER-RIDDEN/REDEFINED

MockDBD over-rides and/or redefines the following class and object methods :

=over 4

=item * sth_to_objects : Class method over-rides that inherited from Class::DBI

=item * update : Class method over-rides that inherited from Class::DBI

=item * _insert_row : Class method over-rides that inherited from Class::DBI

=back

=cut


sub sth_to_objects {
  my ($class,$sth,$args) = (shift,@_);

  # check arguments and state of handles
  croak("Class::DBI::MockDBD -- sth_to_objects needs a statement handle") unless ($sth);
  carp("Class::DBI::MockDBD -- no records to instantiate into objects - did you set results via next_result?") unless ($sth->{mock_num_records});

  # handle Ima::DBI sql_foo methods
  unless (UNIVERSAL::isa($sth => "DBI::st")) {
    my $meth = "sql_$sth";
    $sth = $class->$meth();
  }

  my $rows = [];
  eval { $sth->execute(@$args) unless $sth->{Active};
	 # set last statement handle to check state in other methods later
	 $class->mocked_statement_handle($sth);

	 #  set mock::dbd info
	 $class->mocked_params($sth->{mock_params});
	 $class->mocked_statement($sth->{mock_statement});

 	 while (my $data = $sth->fetchrow_hashref()) {
 	   push (@$rows, $data);
 	 }
        };

  return $class->_croak("Class::DBI::MockDBD -- $class can't $sth->{Statement}: $@", err => $@)
    if $@;
  return $class->_ids_to_objects($rows);
}

sub _insert_row {
  my $self = shift;
  my $class = ref($self);
  my $data = shift;
  eval {
    my @columns = keys %$data;
    my $sth     = $self->sql_MakeNewObj(
					join(', ', @columns),
					join(', ', map $self->_column_placeholder($_), @columns),
				       );
    $self->_bind_param($sth, \@columns);
    $sth->execute(values %$data);

    # set last statement handle to check state in other methods later
    $class->mocked_statement_handle($sth);

    #  set mock::dbd info
    $class->mocked_params($sth->{mock_params});
    $class->mocked_statement($sth->{mock_statement});

    my @primary_columns = $self->primary_columns;
    $data->{ $primary_columns[0] } = $self->_auto_increment_value
      if @primary_columns == 1
	&& !defined $data->{ $primary_columns[0] };
  };
  if ($@) {
    my $class = ref $self;
    return $self->_db_error(
			    msg    => "Can't insert new $class: $@",
			    err    => $@,
			    method => 'insert'
			   );
  }
  return 1;
}


sub update {
  my $self  = shift;
  my $class = ref($self)
    or return $self->_croak("Class::DBI::MockDBD -- Can't call update as a class method");

  $self->call_trigger('before_update');
  return -1 unless my @changed_cols = $self->is_changed;
  $self->call_trigger('deflate_for_update');
  my @primary_columns = $self->primary_columns;
  my $sth             = $self->sql_update($self->_update_line);

  # set last statement handle to check state in other methods later
  $class->mocked_statement_handle($sth);

  $class->_bind_param($sth, \@changed_cols);
  my $rows = eval { $sth->execute($self->_update_vals, $self->id); };

  #  set mock::dbd info
  $class->mocked_params($sth->{mock_params});
  $class->mocked_statement($sth->{mock_statement});


  if ($@) {
    return $self->_db_error(
			    msg    => "Can't update $self: $@",
			    err    => $@,
			    method => 'update'
			   );
  }

  # enable this once new fixed DBD::SQLite is released:
  if (0 and $rows != 1) {	# should always only update one row
    $self->_croak("Can't update $self: row not found") if $rows == 0;
    $self->_croak("Can't update $self: updated more than one row");
  }

  $self->call_trigger('after_update', discard_columns => \@changed_cols);

  # delete columns that changed (in case adding to DB modifies them again)
  $self->_attribute_delete(@changed_cols);
  delete $self->{__Changed};
  return 1;
}


##############################################################################

1;

__END__

=head1 BUGS AND CAVEATS

* rv return value from execute is not correct (DBD::Mock issue)

=head1 SEE ALSO

* Class::DBI

* Mock::DBD

* DBI::Mock

* Website : http://www.aarontrevena.co.uk/opensource/

=head1 AUTHOR

aaron trevena, E<lt>aaron.trevena@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by aaron trevena

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
