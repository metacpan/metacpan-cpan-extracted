package DBIx::Class::AuditLog;
$DBIx::Class::AuditLog::VERSION = '0.6.4';
use base qw/DBIx::Class/;

use strict;
use warnings;

# local $DBIx::Class::AuditLog::enabled = 0;
# can be set to temporarily disable audit logging
our $enabled = 1;

sub insert {
    my $self = shift;

    return $self->next::method(@_) if !$enabled || $self->in_storage;

    my $result = $self->next::method(@_);

    my ( $action, $table ) = $self->_action_setup( $result, 'insert' );

    if ($action) {
        my %column_data = $result->get_columns;
        $self->_store_changes( $action, $table, {}, \%column_data );
    }

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

    foreach my $col ( $self->columns ) {
        if ( $self->_force_audit($col) ) {
            $old_data{$col} = $stored_row->get_column($col)
                unless defined $old_data{$col};
            $new_data{$col} = $self->get_column($col)
                unless defined $new_data{$col};
        }
    }

    # remove unwanted columns
    foreach my $key ( keys %new_data ) {
        next if $self->_force_audit($key);    # skip forced cols
        if (   defined $old_data{$key}
            && defined $new_data{$key}
            && $old_data{$key} eq $new_data{$key}
            || !defined $old_data{$key} && !defined $new_data{$key} )
        {
            delete $new_data{$key};           # remove unchanged cols
        }
    }

    if ( keys %new_data ) {
        my ( $action, $table )
            = $self->_action_setup( $stored_row, 'update' );

        if ($action) {
            $self->_store_changes( $action, $table, \%old_data, \%new_data );
        }
    }

    return $result;
}

sub delete {
    my $self = shift;

    return $self->next::method(@_) if !$enabled;

    my $stored_row = $self->get_from_storage;

    my $result = $self->next::method(@_);

    my ( $action, $table ) = $self->_action_setup( $stored_row, 'delete' );

    if ($action) {
        my %old_data = $stored_row->get_columns;
        $self->_store_changes( $action, $table, \%old_data, {} );
    }

    return $result;
}


sub _audit_log_schema {
    my $self = shift;
    return $self->result_source->schema->audit_log_schema;
}

sub _action_setup {
    my $self = shift;
    my $row  = shift;
    my $type = shift;

    return $self->_audit_log_schema->audit_log_create_action(
        {   row         => join( '-', $row->id ),
            table       => $row->result_source_instance->name,
            action_type => $type,
        }
    );
}

sub _store_changes {
    my $self       = shift;
    my $action     = shift;
    my $table      = shift;
    my $old_values = shift;
    my $new_values = shift;

    foreach my $column (
        keys %{$new_values} ? keys %{$new_values} : keys %{$old_values} )
    {
        if ( $self->_do_audit($column) ) {
            my $field = $table->find_or_create_related( 'Field',
                { name => $column } );

            my $create_params = { field_id => $field->id, };

            if ( $self->_do_modify_audit_value($column) ) {
                $create_params->{new_value}
                    = $self->_modify_audit_value( $column,
                    $new_values->{$column} );
                $create_params->{old_value}
                    = $self->_modify_audit_value( $column,
                    $old_values->{$column} );
            }
            else {
                $create_params->{new_value} = $new_values->{$column};
                $create_params->{old_value} = $old_values->{$column};
            }

            $action->create_related( 'Change', $create_params, );
        }
    }
}

sub _force_audit {
    my ( $self, $column ) = @_;

    ## make sure that this is an actual column, and is not
    ## a correlated column
    return unless $self->has_column($column);

    my $info = $self->column_info($column);

    return defined $info->{force_audit_log_column}
        && $info->{force_audit_log_column};
}

sub _do_audit {
    my $self   = shift;
    my $column = shift;

    return 1 if $self->_force_audit($column);

    my $info = $self->column_info($column);
    return defined $info->{audit_log_column}
        && $info->{audit_log_column} == 0 ? 0 : 1;
}

sub _do_modify_audit_value {
    my $self   = shift;
    my $column = shift;

    my $info = $self->column_info($column);

    return $info->{modify_audit_value} ? 1 : 0;
}

sub _modify_audit_value {
    my $self   = shift;
    my $column = shift;
    my $value  = shift;

    my $info = $self->column_info($column);
    my $meth = $info->{modify_audit_value};
    return $value
        unless defined $meth;

    return &$meth( $self, $value )
        if ref($meth) eq 'CODE';

    $meth = "modify_audit_$column"
        unless $self->can($meth);

    return $self->$meth($value)
        if $self->can($meth);

    die "unable to find modify_audit_method ($meth) for $column in $self";

}

# ABSTRACT: Simple activity audit logging for DBIx::Class

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::AuditLog - Simple activity audit logging for DBIx::Class

=head1 VERSION

version 0.6.4

=head1 NAME

DBIx::Class::AuditLog - Simple activity audit logging for DBIx::Class

=head1 VERSION

version 0.2.6

=head1 DBIx::Class OVERRIDDEN METHODS

=head2 insert

=head2 update

=head2 delete

=head1 HELPER METHODS

=head2 _audit_log_schema

Returns the AuditLog schema from storage.

    my $al_schema = $schmea->audit_log_schema;

=head2 _action_setup

Creates a new AuditLog Action for a specific type.

Requires:
    row: primary key of the table that is being audited
    action_type: action type, 1 of insert/update/delete

=head2 _store_changes

Store the column data that has changed

Requires:
    action: the action object that has associated changes
    old_values: the old values are being replaced
    new_values: the new values that are replacing the old
    table: dbic object of the audit_log_table object

=head2 _do_audit

Returns 1 or 0 if the column should be audited or not.

Requires:
    column: the name of the column/field to check

=head2 _force_audit

Returns 1 or 0 if the column should be audited even if its value did not change.

Requires:
    column: the name of the column/field to check

=head2 _do_modify_audit_value

Returns 1 or 0 if the columns value should be modified before audit.

Requires:
    column: the name of the column/field to check

=head2 _modify_audit_value

Modifies the colums audit-value. Dies if no modify-method could be found.

Returns:
    the modified value

Requires:
    column: the name of the column/field to check
    value: the original value

=head1 AUTHOR

Mark Jubenville <ioncache@gmail.com>

=head1 CONTRIBUTORS

Lukas Thiemeier <lukast@cpan.org>

Dimitar Petrov <dcpetrov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Jubenville.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Mark Jubenville <ioncache@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Jubenville.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
