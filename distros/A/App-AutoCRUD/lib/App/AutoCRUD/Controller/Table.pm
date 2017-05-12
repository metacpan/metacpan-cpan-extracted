package App::AutoCRUD::Controller::Table;

use 5.010;
use strict;
use warnings;

use Moose;
extends 'App::AutoCRUD::Controller';
use SQL::Abstract::More 1.27;
use List::MoreUtils            qw/mesh firstval/;
use JSON::MaybeXS ();
use URI;

use namespace::clean -except => 'meta';

#----------------------------------------------------------------------
# entry point to the controller
#----------------------------------------------------------------------
sub serve {
  my ($self) = @_;

  my $context = $self->context;

  # extract from path : table name and method to dispatch to
  my ($table, $meth_name) = $context->extract_path_segments(2)
    or die "URL too short, missing table and method name";
  my $method = $self->can($meth_name)
    or die "no such method: $meth_name";

  # set default template and title
  $context->set_template("table/$meth_name.tt");
  $context->set_title($context->title . "-" . $table);

  # dispatch to method
  return $self->$method($table);
}


#----------------------------------------------------------------------
# published methods
#----------------------------------------------------------------------

sub descr {
  my ($self, $table) = @_;

  my $datasource = $self->datasource;
  my $descr      = $datasource->config(tables => $table => 'descr');

  # datastructure describing this table
  return {table       => $table, 
          colgroups   => $datasource->colgroups($table),
          primary_key => [$datasource->primary_key($table)],
          descr       => $descr};

}


sub list {
  my ($self, $table) = @_;

  my $context    = $self->context;
  my $req_data   = $context->req_data;
  my $datasource = $context->datasource;

  # the "message" arg is sent once from inserts/updates/deletes; not to
  # be repeated in links to other queries
  my $message = delete $req_data->{-message};

  # dashed args are set apart
  my %where_args  = %$req_data; # need a clone because of deletes below
  my %dashed_args = $context->view->default_dashed_args($context);
  foreach my $arg (grep {/^-/} keys %where_args) {
    $dashed_args{$arg} = delete $where_args{$arg};
  }

  # some dashed args are treated here (not sent to the SQL request)
  my $with_count = delete $dashed_args{-with_count};
  my $template   = delete $dashed_args{-template};
  $context->set_template($template) if $template;

  # select from database
  my $criteria  = $datasource->query_parser->parse(\%where_args) || {};
  my $statement = $datasource->schema->db_table($table)->select(
    -where => $criteria,
    %dashed_args,
    -result_as => 'statement',
   );
  my $rows         = $statement->select();

  # recuperate SQL for logging / informational purposes
  my ($sql, @bind) = $statement->sql;
  my $show_sql     = join " / ", $sql, @bind;
  $self->logger({level => 'debug', message => $show_sql});

  # assemble results
  my $data = $self->descr($table);
  $data->{rows}       = $rows;
  $data->{message}    = $message;
  $data->{criteria}   = $show_sql;
  if ($with_count) {
    $data->{row_count}  = $statement->row_count;
    $data->{page_count} = $statement->page_count;
  }

  # links to prev/next pages
  $self->_add_links_to_other_pages($data, $req_data,
                                   $dashed_args{-page_index},
                                   $dashed_args{-page_size});

  # link to update/delete forms
  $data->{where_args} = $self->_query_string(
    map { ("where.$_" => $where_args{$_}) } keys %where_args,
   );

  return $data;
}


sub _add_links_to_other_pages {
  my ($self, $data, $req_data, $page_index, $page_size) = @_;

  return unless defined $page_index && defined $page_size;

  $data->{page_index}    = $page_index;
  $data->{offset}        = ($page_index - 1) * $page_size + 1;
  $data->{similar_query} = $self->_query_string(%$req_data,
                                                -page_index => 1);
  $data->{next_page}     = $self->_query_string(%$req_data,
                                                -page_index => $page_index+1)
    unless @{$data->{rows}} < $page_size;
  $data->{prev_page}     = $self->_query_string(%$req_data,
                                                -page_index => $page_index-1)
    unless $page_index <= 1;
}



sub id {
  my ($self, $table) = @_;

  my $data     = $self->descr($table);

  my $pk       = $data->{primary_key};
  my @vals     = $self->context->extract_path_segments(scalar(@$pk));
  my %criteria = mesh @$pk, @vals;

  # get row from database
  my $row = $self->datasource->schema->db_table($table)->fetch(@vals);

  # assemble results
  $data->{row}    = $row;
  $data->{pk_val} = join "/", @vals;

  # links
  my %where_pk = map { ("where_pk.$_" => $criteria{$_}) } keys %criteria;
  $data->{where_pk} = $self->_query_string(%where_pk);

  return $data;
}


sub search {
  my ($self, $table) = @_;

  my $context  = $self->context;
  my $req_data = $context->req_data;

  if ($context->req->method eq 'POST') {
    my $output = delete $req_data->{-output} || "";
    my $cols   = [keys %{delete $req_data->{col} || {}}];
    $req_data->{-columns} = join ",", @$cols;
    $self->redirect("list$output?" . $self->_query_string(%$req_data));
  }
  else {
    # display the search form
    my @cols = split /,/, (delete $req_data->{-columns} || "");
    $req_data->{"col.$_"} = 1 foreach @cols;
    my $data = $self->descr($table);
    $data->{init_form} = $self->_encode_json($req_data);
    return $data;
  }
}


sub update {
  my ($self, $table) = @_;

  $self->_check_canmodify;

  if ($self->context->req->method eq 'POST') {
    $self->_do_update_data($table);
  }
  else {
    $self->_display_update_form($table);
  }
}

sub _check_canmodify {
  my ($self) = @_;
  
  if ($self->context->app->readonly) {
    die 'readonly mode';    
  }
}

sub _do_update_data {
  my ($self, $table) = @_;

  $self->_check_canmodify;

  my $context    = $self->context;
  my $req_data   = $context->req_data;
  my $datasource = $context->datasource;

  # columns to update
  my $to_set = $req_data->{set} || {};
  foreach my $key (keys %$to_set) {
    my $val = $to_set->{$key};
    delete $to_set->{$key} if ! length $val;
    $to_set->{$key} = undef if $val eq 'Null';
  }
  keys %$to_set or die "nothing to update";

  # build filtering criteria
  my $where  = $req_data->{where} or die "update without any '-where' clause";
  my $criteria = $datasource->query_parser->parse($where);
  $criteria and keys %$criteria or die "update without any '-where' criteria";

  # perform the update
  my $db_table  = $datasource->schema->db_table($table);
  my $n_updates = $db_table->update(-set => $to_set, -where => $criteria);

  # redirect to a list to display the results
  my $message = ($n_updates == 1) ? "1 record was updated"
                                  : "$n_updates records were updated";
  # TODO: $message could repeat the $to_set pairs
  my $query_string = $self->_query_string(%$where, -message => $message);
  $self->redirect("list?$query_string");
}

sub _display_update_form {
  my ($self, $table) = @_;

  $self->_check_canmodify;

  my $context    = $self->context;
  my $req_data   = $context->req_data;
  my $datasource = $context->datasource;
  my $data       = $self->descr($table);

  if (my $where_pk  = delete $req_data->{where_pk}) {
    # we got the primary key of one single record
    $data->{where_pk}  = $where_pk;
    $req_data->{where} = $where_pk;

    # fetch current values so that we can display them on page
    my $criteria = $datasource->query_parser->parse($where_pk);
    my $db_table = $datasource->schema->db_table($table);
    $req_data->{curr} = $db_table->select(-where     => $criteria,
                                          -result_as => 'firstrow');
  }
  else {
    # we got criteria that may touch several records
    $self->_mark_multicols_keys($data);
  }

  # fields that should not be updatable
  if (my $noupd = delete $req_data->{_noupd}) {
    $data->{noupd}{$_} = 1 foreach split qr[/], $noupd;
  }

  # initial values for the form
  $data->{init_form} = $self->_encode_json($req_data);

  return $data;
}


sub delete {
  my ($self, $table) = @_;

  $self->_check_canmodify;

  my $context    = $self->context;
  my $req_data   = $context->req_data;
  my $datasource = $context->datasource;

  if ($context->req->method eq 'POST') { # POST => delete in database
    # build filtering criteria
    my $where = $req_data->{where} or die "delete without any '-where' clause";
    my $criteria = $datasource->query_parser->parse($where);
    $criteria and keys %$criteria or die "delete without any '-where' criteria";

    # perform the delete
    my $db_table  = $datasource->schema->db_table($table);
    my $n_deletes = $db_table->delete(-where => $criteria);

    # redirect to a list to display the results
    my $message = ($n_deletes == 1) ? "1 record was deleted"
                                    : "$n_deletes records were deleted";
    my $query_string = $self->_query_string(%$where, -message => $message);
    $self->redirect("list?$query_string");
  }
  else {                                  # GET => display the delete form
    # display the delete form
    my $data = $self->descr($table);
    if (my $where_pk  = delete $req_data->{where_pk}) {
      # we got the primary key of one single record
      $data->{where_pk}  = $where_pk;
      $req_data->{where} = $where_pk;
    }
    else {
      # we got criteria that may touch several records
      $self->_mark_multicols_keys($data);
    }

    # initial values for the form
    $data->{init_form} = $self->_encode_json($req_data);

    return $data;
  }
}




sub clone {
  my ($self, $table) = @_;

  $self->_check_canmodify;

  my $context = $self->context;
  $context->req->method eq 'GET'
    or die "the /clone URL only accepts GET requests";

  # get primary key
  my $data    = $self->descr($table);
  my $pk      = $data->{primary_key};
  my %is_pk   = map {$_ => 1} @$pk;
  my @vals    = $context->extract_path_segments(scalar(@$pk));

  # get row from database
  my $row = $self->datasource->schema->db_table($table)->fetch(@vals);

  # populate req_data before calling insert()
  my $req_data   = $context->req_data;
  foreach my $col (keys %$row) {
    my $val = $row->{$col};
    $req_data->{$col} = $val if $val and !$is_pk{$col};
  }

  # cheat with path (simulating a call to insert())
  my $path = $context->path;
  $path =~ s/clone$/insert/;
  $context->set_path($path);
  $context->set_template('table/insert.tt');

  # forward to insert()
  $self->insert($table);
}


sub insert {
  my ($self, $table) = @_;

  $self->_check_canmodify;

  my $context    = $self->context;
  my $req_data   = $context->req_data;
  my $datasource = $context->datasource;

  if ($context->req->method eq 'POST') {
    # perform the insert
    my $db_table  = $datasource->schema->db_table($table);
    my @pk = $db_table->insert($req_data);

    # redirect to a list to display the results
    my $message = "1 record was inserted";
    my $query_string = $self->_query_string(-message => $message);
    $self->redirect(join("/", "id", @pk) . "?$query_string");
  }
  else {
    # display the insert form
    my $data = $self->descr($table);
    $data->{init_form} = $self->_encode_json($req_data);

    return $data;
  }
}



sub count_where { # used in Ajax mode by update and delete forms
  my ($self, $table) = @_;

  my $context    = $self->context;
  my $req_data   = $context->req_data;
  my $datasource = $context->datasource;

  my $n_records = -1;

  if (my $where = $req_data->{where}) {
    my $criteria = $datasource->query_parser->parse($where);
    if ($criteria and keys %$criteria) {
      my $db_table  = $datasource->schema->db_table($table);
      my $result = $db_table->select(
        -columns   => 'COUNT(*)',
        -where     => $criteria,
        -result_as => 'flat_arrayref',
       );
      $n_records = $result->[0];
    }
  }

  return {n_records => $n_records};
}




#----------------------------------------------------------------------
# auxiliary methods
#----------------------------------------------------------------------


sub _query_string {
  my ($self, %params) = @_;
  my @fragments; 
 KEY:
  foreach my $key (sort keys %params) {
    my $val = $params{$key};
    length $val or next KEY;

    # cheap URI escape (for chars '=', '&', ';' and '+')
    s/=/%3D/g, s/&/%26/g, s/;/%3B/g, s/\+/%2B/g for $key, $val;

    push @fragments, "$key=$val";
  }

  return join "&", @fragments;
}


sub _encode_json {
  my ($self, $data) = @_;

  # utf8-encoding is done in the view, so here we turn it off
  my $json_maker = JSON::MaybeXS->new(allow_blessed   => 1,
                                      convert_blessed => 1,
                                      utf8            => 0);
  return $json_maker->encode($data);
}


sub _mark_multicols_keys {
  my ($self, $data) = @_;

  if (my $sep = $self->datasource->schema->sql_abstract->multicols_sep) {
    # in case of multi-columns keys, the form needs to add special fields
    # and to ignore regular fields for those columns
    my $where = $self->context->req_data->{where} || {};
    my @multi_cols_keys = grep m[$sep], keys %$where;
    $data->{multi_cols_keys} = \@multi_cols_keys;
    $data->{ignore_col}{$_} = 1 foreach map {split m[$sep]} @multi_cols_keys;
  }
}


1;

__END__

=head1 NAME

App::AutoCRUD::Controller::Table - Table controller

=head1 DESCRIPTION

This controller provides methods for searching and describing
a given table within some datasource.

=head1 METHODS

=head2 serve

Entry point to the controller; from the URL, it extracts the table
name and the name of the method to dispatch to (the URL is expected
to be of shape C<< table/{table_name}/{$method_name}?{arguments} >>).
It also sets the default template to C<< table/{method_name}.tt >>.

=head2 descr

Returns a hashref describing the table, with keys C<descr>
(description information from the config), C<table> (table name),
C<colgroups> (datastructure as returned from 
L<App::AutoCRUD::DataSource/colgroups>), and 
C<primary_key> (arrayref of primary key columns).

=head2 list

Returns a list of records from the table, corresponding to the query
parameters specified in the URL. 
[TODO: EXPLAIN MORE -- in particular the "-template" arg ]





