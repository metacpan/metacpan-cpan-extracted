package DBIx::Class::Schema::AuditLog::Structure::View;
$DBIx::Class::Schema::AuditLog::Structure::View::VERSION = '0.6.4';
use base 'DBIx::Class::Schema::AuditLog::Structure::Base';

use strict;
use warnings;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table('audit_log_view');

__PACKAGE__->result_source_instance->view_definition(
    q{
        select 
            c.id as change_id,
            s.id as changeset_id,
            c.old_value,
            c.new_value,
            a.action_type,
            a.audited_row,
            s.description,
            s.created_on,
            t.name as table_name,
            f.name as field_name,
            u.name as user_name
        from
            audit_log_action    a
            inner join
            audit_log_change    c
                on c.action_id = a.id   
            inner join
            audit_log_field     f
                on f.id = c.field_id
            inner join
            audit_log_table     t
                on t.id = a.audited_table_id
            inner join
            audit_log_changeset s
                on s.id = a.changeset_id
            left join
            audit_log_user      u
                on s.user_id = u.id
    }
);

__PACKAGE__->add_columns(
    'change_id' => {
        'data_type'         => 'integer',
        'is_nullable'       => 0,
    },
    'changeset_id' => {
        'data_type'         => 'integer',
        'is_nullable'       => 0,
    },
    'old_value' => {
        'data_type'   => 'varchar',
        'is_nullable' => 1,
        'size'        => 255,
    },
    'new_value' => {
        'data_type'   => 'varchar',
        'is_nullable' => 1,
        'size'        => 255,
    },
    'action_type' => {
        'data_type'   => 'varchar',
        'is_nullable' => 0,
        'size'        => 10,
    },
    'audited_row' => {
        'data_type'   => 'varchar',
        'is_nullable' => 0,
        'size'        => 255,
    },
    'description' => {
        'data_type'   => 'varchar',
        'is_nullable' => 1,
        'size'        => 255,
    },
    'created_on' => {
        'data_type'     => 'timestamp',
        'set_on_create' => 1,
        'is_nullable'   => 0,
    },
    'table_name' => {
        'data_type'   => 'varchar',
        'is_nullable' => 0,
        'size'        => 40,
    },
    'field_name' => {
        'data_type'   => 'varchar',
        'is_nullable' => 0,
        'size'        => 40,
    },
    'user_name' => {
        'data_type' => "varchar", 
        'is_nullable' => 1, 
        'size' => 100
    },
);

__PACKAGE__->set_primary_key('change_id');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Schema::AuditLog::Structure::View

=head1 VERSION

version 0.6.4

=head1 AUTHOR

Mark Jubenville <ioncache@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Jubenville.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
