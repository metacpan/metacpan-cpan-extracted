package DBIx::Class::PgLog;

=head1 NAME

DBIx::Class::PgLog - Postgres simple activity loging for DBIx::Class

The PgLog schema consists of 2 tables LogSet and Log, Log table extensively makes use of the power of Postgres to store the Columns, OldValues and NewValues in an Column Array format to avoid the relational database structure which imporves the performance of write and read from PgLog.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

DBIx::Class::PgLog is meant for Logging changes made to specific tables in your database.

Any insert/update/delete that requires auditing must be wrapped in a L<"txn_do"|DBIx::Class::Schema/"txn_do"> statement.

Transactions are saved as LogSets.  Each LogSet can have many Log's with TableAction as INSERT/UPDATE/DELETE. 

=head1 DESCRIPTION

Enable the PgLog schema component in your L<DBIx::Class::Schema> class file:

    package My::Schema;
    use base qw/DBIx::Class::Schema/;

    __PACKAGE__->load_components(qw/Schema::PgLog/);

Enable the PgLog component in your the individual L<DBIx::Class> table class files that you want to enable logging on:

    package My::Schema::Result::Table
    use base qw/DBIx::Class::Core/;

    __PACKAGE__->load_components(qw/PgLog/);

If you want to use methods created by L<DBIx::Class::Relationship::Base>, like "add_to_$rel" or "set_$rel",
if you are planing to use L<DBIx::Class::ResultSet/delete> or L<DBIx::Class::ResultSet/update> or if you use
modules which make use of these methods (like L<HTML::FormHandler> or L<DBIx::Class::ResultSet::RecursiveUpdate>,
load the PgLog-component in your ResultSet classes:

    package My::Schema::ResultSet::Table;

    use base 'DBIx::Class::ResultSet';

    __PACKAGE__->load_components('ResultSet::PgLog');

    1;

In your application wrap any insert/update/delete in a transaction to have pg log activated:

* Mandatorily Pass an extra hashref to the txn_do method to indicate a UserId and optional Description for the transaction:

    $my_schema->txn_do(
        sub {
            $my_row->update({ ... });
        },
        {
            UserId => 'User_id',
            Description => 'description of transaction' # optional
        }
    );

=head1 DBIx::Class OVERRIDDEN METHODS
 
=head2 insert
 
=head2 update
 
=head2 delete

=cut

# local $DBIx::Class::AuditLog::enabled = 0;
# can be set to temporarily disable audit logging
our $enabled = 1;

sub insert {
    my $self = shift;

    return $self->next::method(@_) if !$enabled || $self->in_storage;

    my $result = $self->next::method(@_);

	my $action = "INSERT";

	my %column_data = $result->get_columns;
	$self->_store_changes( $action, $result, {}, \%column_data );

    return $result;
}

sub update {
    my $self = shift;

    return $self->next::method(@_) if !$enabled;

    my $stored_row      = $self->get_from_storage;
    my %new_data        = $self->get_columns;
    my @changed_columns = keys %{ $_[0] || {} };

    my $result = $self->next::method(@_);

    return unless $stored_row; # update on deleted row - nothing to log

    my %old_data = $stored_row->get_columns;

    if (@changed_columns) {
        @new_data{@changed_columns} = map $self->get_column($_),
            @changed_columns;
    }

    if ( keys %new_data ) {
		my $action = "UPDATE";
		$self->_store_changes( $action, $result, \%old_data, \%new_data );
    }

    return $result;
}

sub delete {
    my $self = shift;

    return $self->next::method(@_) if !$enabled;

    my $stored_row = $self->get_from_storage;

    my $result = $self->next::method(@_);

	my $action = "DELETE";
	my %old_data = $stored_row->get_columns;
	$self->_store_changes( $action, $result, \%old_data, {} );

    return $result;
}

=head1 HELPER METHODS

=head2 _pg_log_schema

Returns PgLog schema from storage

	my $pl_schema = $schema->pg_log_schema;

=cut

sub _pg_log_schema {
    my $self = shift;
    return $self->result_source->schema->pg_log_schema;
}

=head2 _store_changes
 
Store the column data that has changed
 
Requires:
    action: the action object that has associated changes
	old_values: the old values are being replaced
	new_values: the new values that are replacing the old
	table: dbic object of the audit_log_table object

=cut

sub _store_changes {
    my $self       = shift;
    my $action	   = shift;
    my $row		   = shift;
    my $old_values = shift;
    my $new_values = shift;

	my $table = $row->result_source_instance->name; 
	my $log_data = {};

	foreach my $column (
		keys %{$new_values} ? keys %{$new_values} : keys %{$old_values} )
	{
		if ( $self->_do_pg_log($column) ) {
			push(@{$log_data->{Columns}}, $column);
			if(ref($old_values->{$column}) eq "ARRAY") {
				$old_values->{$column} = "{".join(",", @{$old_values->{$column}})."}";
			}
			if(ref($new_values->{$column}) eq "ARRAY") {
				$new_values->{$column} = "{".join(",", @{$new_values->{$column}})."}";
			}
			if ( $self->_do_modify_pg_log_value($column) ) {
				push(@{$log_data->{NewValues}}, $self->_modify_pg_log_value( $column, $new_values->{$column} ));
				push(@{$log_data->{OldValues}}, $self->_modify_pg_log_value( $column, $old_values->{$column} ));
			} else {
				push(@{$log_data->{NewValues}}, $new_values->{$column});
				push(@{$log_data->{OldValues}}, $old_values->{$column});
			}

		}

	}
	
	$log_data->{Table} = $table;
	$log_data->{TableId} = $row->can(Id)?$row->Id:$row->id;
	$log_data->{TableAction} = $action;

	$self->_pg_log_schema->pg_log_create_log($log_data);

}

=head2 _do_pg_log
 
Returns 1 or 0 if the column should be audited or not.
 
Requires:
    column: the name of the column/field to check

=cut

sub _do_pg_log {
    my $self   = shift;
    my $column = shift;

    my $info = $self->column_info($column);
    return defined $info->{pg_log_column}
        && $info->{pg_log_column} == 0 ? 0 : 1;
}

=head2 _do_modify_pg_log_value

Returns 1 or 0 if the columns value should be modified before audit.
 
Requires:
    column: the name of the column/field to check

=cut

sub _do_modify_pg_log_value {
    my $self   = shift;
    my $column = shift;

    my $info = $self->column_info($column);

    return $info->{modify_pg_log_value} ? 1 : 0;
}

=head2 _modify_pg_log_value

Modifies the colums audit-value. Dies if no modify-method could be found.
 
Returns:
    the modified value
	 
Requires:
	column: the name of the column/field to check
	value: the original value

=cut

sub _modify_pg_log_value {
    my $self   = shift;
    my $column = shift;
    my $value  = shift;

    my $info = $self->column_info($column);
    my $meth = $info->{modify_pg_log_value};
    return $value
        unless defined $meth;

    return &$meth( $self, $value )
        if ref($meth) eq 'CODE';

    $meth = "modify_pg_log_$column"
        unless $self->can($meth);

    return $self->$meth($value)
        if $self->can($meth);

    die "unable to find modify_pg_log_method ($meth) for $column in $self";

}

=head1 ADDITIONAL DBIC COLUMN ATTRIBUTES

Individual columns can have additional attributes added to change the Audit Log functionality.

=head2 pg_log_column

On an individual column basis you can disable auditing by setting 'pg_log_column' to 0:

    __PACKAGE__->add_columns(
      "admin_id",
      { data_type => "integer", is_auto_increment => 1, is_nullable => 0, pg_log_column => 0 },
      "admin_name",
      { data_type => "varchar", is_nullable => 0, size => 20 },
      "admin_pasword",
      { data_type => "varchar", is_nullable => 0, size => 20 },
    );

If you are using a DBIx::Class generated schema, and don't want to modify the column defintions directly, you can add the following to the editable portion of the Result Class file:

    __PACKAGE__->add_columns(
        "+admin_id",
        { pg_log_column => 0, }
    );

=head2 modify_pg_log_value

It is possible to modify the values stored by DBIC::PgLog on a per-column basis
by setting the 'modify_pg_log_value' attibute to either a CodeRef, a method
name or any true value. The configured code will be run as an object method of
the current DBIC::Result object, and expects the original value as parameter.

If 'modify_pg_log_value' is set to a true value which is NOT a method in the
current objects class, PgLog will look for a method called
'modify_pg_log_$colname', where $colname is the name of the corresponding column.

Note: PgLog will simply die if it can not find the modification method while
'modify_pg_log_value' is true.

The following examples have the same result:

passing a coderef:

    __PACKAGE__->add_columns(
        "+name",
        { modify_pg_log_value => sub{
        my ($self, $value) = @_;
        $value =~ tr/A-Z/a-z/;
        return $value;
    }, }
    );

passing a method name:

    __PACKAGE__->add_columns(
        "+name",
        { modify_pg_log_value => 'to_lowercase'},
    );

    sub to_lowercase{
        my ($self, $value) = @_;
        $value =~ tr/A-Z/a-z/;
        return $value;
    }

passing a true value which is NOT a method name:

    __PACKAGE__->add_columns(
        "+name",
        { modify_pg_log_value => 1},
    );

    sub modify_pg_log_name{
        my ($self, $value) = @_;
        $value =~ tr/A-Z/a-z/;
        return $value;
    }

=head1 DEPLOYMENT

To deploy an PgLog schema, load your main schema, and then run the deploy command on the pg_log_schema:

	my $schema = PgLogTestPg::Schema->connect( "DBI:Pg:dbname=pg_log_test",
	    "sheeju", "sheeju", { RaiseError => 1, PrintError => 1, 'quote_char' => '"', 'quote_field_names' => '0', 'name_sep' => '.' } ) || die("cant connect");;
	
	$schema->pg_log_schema->deploy();

The db user that is deploying the schema must have the correct create table permissions.

Note: this should only be run once.

=head1 METHODS

=head2 pg_log_schema

=over 4

=item Returns: DBIC schema

=back

The PgLog schema can be accessed from your main schema by calling the pg_log_schema method.

    my $pl_schema = $schema->pg_log_schema;

=head1 SEE ALSO

=over 4

=item * L<DBIx::Class>

=item * L<DBIx::Class::Journal>

=item * L<DBIx::Class::AuditLog>

=back

=head1 ACKNOWLEDGEMENTS

Development time supported by Exceleron L<www.exceleron.com|http://www.exceleron.com>.

Many ideas and code borrowed from L<DBIx::Class::AuditLog>.

=head1 AUTHOR

Sheeju Alex, C<< <sheeju at exceleron.com> >>

=head1 BUGS

https://github.com/sheeju/DBIx-Class-PgLog/issues

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::PgLog


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-PgLog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-PgLog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-PgLog>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-PgLog/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Sheeju Alex.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of DBIx::Class::PgLog
