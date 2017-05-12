package Catalyst::Plugin::Session::Store::DBIC::Delegate;

use strict;
use warnings;
use base qw/Class::Accessor::Fast/;
use Carp qw/carp/;
use Scalar::Util qw/blessed/;

__PACKAGE__->mk_accessors(qw/model id_field data_field _session_row _flash_row/);

=head1 NAME

Catalyst::Plugin::Session::Store::DBIC::Delegate - Delegates between the session and flash rows

=head1 DESCRIPTION

This class delegates between two rows in your sessions table for a
given session (session and flash).  This is done for compatibility
with L<Catalyst::Plugin::Session::Store::DBI>.

=head1 METHODS

=head2 session

Return the session row for this delegate.

=cut

sub session {
    my ($self, $key) = @_;

    my $row = $self->_session_row;

    unless ($row) {
        $row = $self->_load_row($key);
        $self->_session_row($row);
    }

    return $row;
}

=head2 flash

Return the flash row for this delegate.

=cut

sub flash {
    my ($self, $key) = @_;

    my $row = $self->_flash_row;

    unless ($row) {
        $row = $self->_load_row($key);
        $self->_flash_row($row);
    }

    return $row;
}

=head2 _load_row

Load the specified session or flash row from the database. This is a
wrapper around L<DBIx::Class::ResultSet/find_or_create> to add support
for transactions.

=cut

sub _load_row {
    my ($self, $key) = @_;

    my $load_sub = sub {
        return $self->model->find_or_create({ $self->id_field => $key })
    };

    my $row;
    if (blessed $self->model and $self->model->can('result_source')) {
        $row = $self->model->result_source->schema->txn_do($load_sub);
    }
    else {
        # Fallback for DBIx::Class::DB
        $row = $load_sub->();
    }

    return $row;
}

=head2 expires

Return the expires row for this delegate.  As with
L<Catalyst::Plugin::Session::Store::DBI>, this maps to the L</session>
row.

=cut

sub expires {
    my ($self, $key) = @_;

    $key =~ s/^expires/session/;
    $self->session($key);
}

=head2 flush

Update the session and flash data in the backend store.

=cut

sub flush {
    my ($self) = @_;

    for (qw/_session_row _flash_row/) {
        my $row = $self->$_;
        next unless $row;

        # Check the size if available to avoid silent trucation on e.g. MySQL
        my $data_field = $self->data_field;
        if (my $size = $row->result_source->column_info($data_field)->{size}) {
            my $total_size = length($row->$data_field);
            carp "This session requires $total_size bytes of storage, but your database column '$data_field' can only store $size bytes. Storing this session may not be reliable; increase the size of your data field"
                if $total_size > $size;
        }

        $row->update if $row->in_storage;
    }

    $self->_clear_instance_data;
}

=head2 _clear_instance_data

Remove any references held by the delegate.

=cut

sub _clear_instance_data {
    my ($self) = @_;

    $self->id_field(undef);
    $self->model(undef);
    $self->_session_row(undef);
    $self->_flash_row(undef);
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>danieltwc@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006-2008 Daniel Westermann-Clark, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
