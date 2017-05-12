use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::SQLForm;
our $VERSION = '0.98';
use base qw(Apache::Wyrd::Form);
use Apache::Wyrd::Services::SAK qw(:db);
use warnings qw(all);
no warnings qw(uninitialized);

=pod

=head1 NAME

Apache::Wyrd::SQLForm - General Form Wyrd for editing data in SQL

=head1 SYNOPSIS

    <BASENAME::SQLForm index="user_id" table="users">
      <BASENAME::Form::Template name="password">
        <BASENAME::Form::Preload>
          <BASENAME::Defaults>
            select 'root' as user_id;
          </BASENAME::Defaults>
          <BASENAME::Query>
            select user_id from users where name='Groucho'
          </BASENAME::Query>
        </BASENAME::Form::Preload>
        <b>Enter Password:</b><br>
        <BASENAME::Input name="password" type="password" />
        <BASENAME::Input name="user_id" type="hidden" />
      </BASENAME::Form::Template>
      <BASENAME::Form::Template name="result">
        <H1>Status: $:_status</H1>
        <HR>
        <P>$:_message</P>
      </BASENAME::Form::Template>
    </BASENAME::SQLForm>

=head1 DESCRIPTION

The SQLForm is a subclass of Apache::Wyrd::Form.  It is meant to simplify
the creation of forms that are used to edit data within a database connected
to via the C<Apache::Wyrd::DBL>.

The SQLForm makes the assumption that there is a primary table on which the
edit is operating and that other tables will, if necessary, have elements
inserted, changed or deleted from them as they relate to the primary table.

This module is meant to be subclassed, so a large number of its methods are
only defined in order to be overridden.  Any changes to secondary tables,
for example, need to be handled by subclassing C<_prep_secondary>,
C<_submit_secondary>, and C<_perform_secondary_deletes>, all of which do
nothing by default.

=head2 HTML ATTRIBUTES

=over

=item index

The index column of the primary table, i.e. the name of the primary key column.

=item table

The name of the primary table.

=back

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (scalar) C<cancelled> (void)

Determine if the action has been cancelled.  Defaults to assuming the form is cancelled if the action parameter is set to B<cancel>.

=cut

sub cancelled {
	my ($self) = @_;
	if ($self->dbl->param('action') eq 'cancel') {
		$self->_set_feedback('Cancelled', '<BR>No changes were made to the Record');
		return 1;
	}
	return;
}

=item (scalar) C<index> (void)

Returns the name of the primary key column, or index.

=cut

sub index {
	my ($self) = @_;
	return $self->{'index'};
}

=item (scalar) C<table> (void)

Returns the name of the primary table.

=cut

sub table {
	my ($self) = @_;
	return $self->{'table'};
}

=item (scalar) C<default_ok> (void)

Returns the word used to describe the status of OK.  Default is literal
"OK".

=cut

sub default_ok {
	my ($self) = @_;
	return 'OK';
}

=item (scalar) C<default_ok> (void)

Returns the word used to describe the status of not OK.  Default is
literal "Error".

=cut

sub default_error {
	my ($self) = @_;
	return 'Error';
}

=item (scalar) C<default_log> (void)

Initializes the log of SQL transactions which took place during the
submission.  The idea is that each SQL query or command will produce
results, and these results will be fed back to the user as a log. 
Defaults to undef.

=cut

sub default_log {
	my ($self) = @_;
	return;
}

=item (scalar) C<default_insert_error> (scalar)

Format the error that occurs when there has been a database error during
an insert command.  The error itself is the argument.

=cut

sub default_insert_error {
	my ($self, $err) = @_;
	return "<BR>Unable to create the record: $err";
}

=item (scalar) C<default_update_error> (scalar)

Format the error that occurs when there has been a database error during
an update command.  The error itself is the argument.

=cut

sub default_update_error {
	my ($self, $err) = @_;
	return "<BR>Unable to update the record: $err";
}

=item (scalar) C<default_insert_ok> (void)

Format the log entry that occurs when there has been a successful insert
command.

=cut

sub default_insert_ok {
	my ($self) = @_;
	return "<BR>The record was successfully created";
}

=item (scalar) C<default_update_ok> (void)

Format the log entry that occurs when there has been a successful update
command.

=cut

sub default_update_ok {
	my ($self) = @_;
	return "<BR>The record was successfully updated";
}

=item (scalar) C<primary_delete_error> (void)

Format the log entry that occurs when the edited record cannot be
deleted.  The error is the argument.

=cut

sub primary_delete_error {
	my ($self, $err) = @_;
	return "Falied to delete the record: $err";
}

=item (scalar) C<deleted> (void)

Checks to see if the B<action> CGI parameter is set to "really_delete", and
if so, deletes the record from the primary table and calls the
C<_perform_secondary_deletes> method to remove associated records in
secondary tables.  Returns a 1 if the deletion occurred, undef otherwise.

=cut

sub deleted {
	my ($self) = @_;
	my $table = $self->table;
	my $index = $self->index;
	$self->_raise_exception('table and index need to be provided in an SQLForm') unless ($table and $index);
	my %var = %{$self->{'_variables'}};
	my ($log) = $self->default_log;
	my ($log_title) = $self->default_ok;
	if ($self->dbl->param('action') eq 'really_delete') {
		if ($var{$index}) {#Delete it only if it actually exists
			my $sh = $self->do_query("delete from $table where $index=\$:$index", \%var);
			my $err = $sh->errstr;
			if ($err) {
				$log_title = $self->default_error;
				$log .= $self->primary_delete_error($err);
			} else {
				$self->_deleted_hook({table=>$table,column=>$index,value=>$var{$index}});
				my ($log_title, $addendum) = $self->_perform_secondary_deletes;
				$log .= $addendum;
			}
		}
		$self->_set_feedback($log_title, $log);
		return 1;
	}
	return;
}

=item (void) C<_prep_submission> (void)

Hook method for preparing the data submission.  Performed prior to
submitting, but after a check for deletions.  Does nothing by default.

=cut

sub _prep_submission {
	my ($self) = @_;
	$self->_join_sets;
	return;
}

=item (void) C<_prep_secondary> (void)

Hook method for preparing the secondary data.  Called prior to
C<_submit_secondary>.  Does nothing by default.

=cut

sub _prep_secondary {
	my ($self) = @_;
	return;
}

=item (void) C<_submit_secondary> (void)

Hook method for performing alterations on tables other than the primary one.
 Does nothing by default.

=cut

sub _submit_secondary {
	my ($self) = @_;
	return;
}

=item (void) C<_perform_secondary_deletes> (void)

Hook method for removing records associated with the primary record. 
Does nothing by default.

=cut

sub _perform_secondary_deletes {
	my ($self) = @_;
	return;
}

=item (scalar) C<_logger_hook> (hashref, scalar)

Generic logger for the hook methods (below).  Is the method called by
the default hooks.  Takes a hook hashref and an action scalar.

=cut

sub _logger_hook {
	my ($self, $spec, $action) = @_;
	if (ref($spec) eq 'HASH') {
		my $table = $spec->{'table'};
		my $column = $spec->{'column'};
		my $value = $spec->{'value'};
		if ($table and $column and $value) {
			$self->_info("$column=$value $action in $table");
		}
	}
}

=item (scalar) C<_deleted_hook> (hashref)

Backend hook.  Allows a secondary device to be notified that a deletion,
addition, or update has occurred.  Takes the argument of a hashref in
the same format as Apache::Wyrd::Services::SAK::_exists_in_table.  By
default only logs the event in the _info log via the _logger_hook above.

=cut

sub _deleted_hook {
	my ($self, $spec) = @_;
	$self->_logger_hook($spec, 'deleted');
}

=item (scalar) C<_added_hook> (hashref)

Like the _deleted_hook above.

=cut

sub _added_hook {
	my ($self, $spec) = @_;
	$self->_logger_hook($spec, 'added');
}

=item (scalar) C<_updated_hook> (hashref)

Like the _deleted_hook above.

=cut

sub _updated_hook {
	my ($self, $spec) = @_;
	$self->_logger_hook($spec, 'updated');
}

=item C<_sets>, C<_join_sets>, C<_split_sets>

Hook methods for dealing with data which may arrive from CGI as an array, but is submitted in the form of a comma-joined set of values.  These are usually data in a SET or ENUM column within an SQL database table.

=over

=item (array) C<_sets> (void)

List all columns to be treated as sets.  The CGI param of this name will
be manipulated to convert to and from arrays in order to translate
between SQL and CGI.

=cut

sub _sets {
	return;
}

=item (void) C<_split_sets> (void)

depending how sets data types are treated in your DBA, use this method
for splitting the set value into an arrayref of the values of the set. 
The default is to split the sets by comma.

=cut

sub _split_sets {
	my ($self) = @_;
	my @fields = $self->_sets;
	#set types are usually comma-delineated text from a database.  If this is a preload, they need to be split.
	foreach my $field (@fields) {
		if (ref($self->{_variables}->{$field}) ne 'ARRAY') {
			$self->{_variables}->{$field} = [split (',', $self->{_variables}->{$field})];
		} else {
			$self->_error(qq(Field $field is defined as a set but was supplied as an ARRAY.));
		}
	}
}

=item (void) C<_join_sets> (void)

the opposite of _split_sets.  How to turn an arrayref of values into a
value acceptable by your DBA.  By default, joins the values with a
comma.

=cut

sub _join_sets {
	my ($self) = @_;
	my @fields = $self->_sets;
	foreach my $field (@fields) {
		if (ref($self->{_variables}->{$field}) eq 'ARRAY') {
			$self->{_variables}->{$field} = join(',', @{$self->{_variables}->{$field}});
		} else {
			my $value = $self->{_variables}->{$field};
			if ($value) {
				$self->_error(qq(Field $field is non-null (value: $value), defined as a set, and did not resolve as an array.  This is probably an error.));
			}
		}
	}
}

=pod

=back

=item (void) C<_set_feedback> (void)

Allow globals to be set for the feedback page.  Called as a last step
after all the data has been submitted.

=cut

sub _set_feedback {
	my ($self, $title, $log) = @_;
	$self->{'globals'}->{'_status'} = $title;
	$self->{'globals'}->{'_message'} = ($log || 'OK');
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _submit_data method above and beyond the methods already
reserved by C<Apache::Wyrd::Form>.  Also overrides the Form methods
C<_prep_preloads> and C<_check_form>.

=cut

sub _submit_data {
	my ($self) = @_;
	return undef if ($self->cancelled);
	return undef if ($self->deleted);
	my ($status, $log, $s_log) = ();
	$self->_prep_submission;#Prep the data to fit the SQL engine: date-formats, set/enum formats.
	$self->_prep_secondary;#If you've polluted the _variables namespace, here's your chance to clean it up.
	($status, $log) = $self->_submit_primary;
	($status, $s_log) = $self->_submit_secondary if ($status eq $self->default_ok);
	$log .= $s_log;
	$self->_set_feedback($status, $log);
	return;
}

sub _prep_preloads {
	my ($self) = @_;
	if (($self->_flags->preload and not($self->_flags->preloaded)) or $self->_flags->autopreload) {
		my $id = $self->dbl->param($self->index);
		if ($id) {
			my $query = 'select * from ' . $self->table . ' where ' . $self->index . '=' . $self->dbl->dbh->quote($id);
			$self->_info("Auto-Prepping the Form with the query '$query;'");
			my $sh = $self->dbl->dbh->prepare($query);
			$sh->execute;
			my $hashref = $sh->fetchrow_hashref;
			$self->_raise_exception("Asked to auto-preload, but data is ambiguous.") if ($sh->fetchrow_hashref);
			foreach my $key (keys %$hashref) {
				$self->{'_variables'}->{$key} = $hashref->{$key};
			}
		} else {
			$self->_error("Asked to auto-preload, but no CGI variable for the index was set");
		}
	}
	$self->_split_sets;
	return;
}

sub _check_form {
	my ($self) = @_;
	$self->insert_error('preview') if ($self->dbl->param('action') eq 'preview');
	$self->insert_error('preview') if ($self->dbl->param('action') eq 'delete');
	$self->_flags->ignore_errors(1) if ($self->dbl->param('action') eq 'really_delete');
	$self->_flags->ignore_errors(1) if ($self->dbl->param('action') eq 'cancel');
	return;
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

sub _submit_primary {
	my ($self) = @_;
	my $table = $self->table;
	my $index = $self->index;
	$self->_raise_exception('table and index need to be provided in an MySQLForm') unless ($table and $index);
	my %var = %{$self->{'_variables'}};
	my ($log) = $self->default_log;
	my ($log_title) = $self->default_ok;
	my ($sh) = ();
	my $must_update = $var{$index};
	if ($self->_flags->check_index) {
		my ($count) = $self->dbl->dbh->selectrow_array("select count(*) from $table where $index=" . $self->dbl->dbh->quote($var{$index}));
		$must_update = 0 unless ($count);
	}
	if ($must_update) {#Perform an update, not an insert
		my $sh = $self->do_query("update $table set " . set_clause(keys(%var)) . " where $index=\$:$index", \%var);
		my $err = $sh->errstr;
		if ($err) {
			$log_title = $self->default_error;
			$log .= $self->default_update_error($err);
		} else {
			$log .= $self->default_update_ok;
		}
		$self->_updated_hook({table=>$table,column=>$index,value=>$var{$index}});
	} else {#Perform an insert
		delete($var{$index}) unless ($self->_flags->check_index);
		my $sh = $self->do_query("insert into $table set " . set_clause(keys(%var)), \%var);
		my $err = $sh->errstr;
		if ($err) {
			$log_title = $self->default_error;
			$log .= $self->default_insert_error($err);
		} else {
			$self->{'_variables'}->{$index} = $self->_insert_id($sh);
			$log .= $self->default_insert_ok;
		}
		$self->_added_hook({table=>$table,column=>$index,value=>$var{$index}});
	}
	return ($log_title, $log);
}

1;