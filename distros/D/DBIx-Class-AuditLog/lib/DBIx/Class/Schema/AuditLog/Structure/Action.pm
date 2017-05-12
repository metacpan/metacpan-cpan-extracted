package DBIx::Class::Schema::AuditLog::Structure::Action;
$DBIx::Class::Schema::AuditLog::Structure::Action::VERSION = '0.6.4';
use base 'DBIx::Class::Schema::AuditLog::Structure::Base';

use strict;
use warnings;

__PACKAGE__->table('audit_log_action');

__PACKAGE__->add_columns(
    'id' => {
        'data_type'         => 'integer',
        'is_auto_increment' => 1,
        'is_nullable'       => 0,
    },
    'changeset_id' => {
        'data_type'   => 'integer',
        'is_nullable' => 0,
    },
    'audited_table_id' => {
        'data_type'   => 'integer',
        'is_nullable' => 0,
    },
    'audited_row' => {
        'data_type'   => 'varchar',
        'is_nullable' => 0,
        'size'        => 255,
    },
    'action_type' => {
        'data_type'   => 'varchar',
        'is_nullable' => 0,
        'size'        => 10,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    'Changeset',
    'DBIx::Class::Schema::AuditLog::Structure::Changeset',
    { 'foreign.id' => 'self.changeset_id' },
);

__PACKAGE__->belongs_to(
    'AuditedTable',
    'DBIx::Class::Schema::AuditLog::Structure::AuditedTable',
    { 'foreign.id' => 'self.audited_table_id' },
);

__PACKAGE__->has_many(
    'Change',
    'DBIx::Class::Schema::AuditLog::Structure::Change',
    { 'foreign.action_id' => 'self.id' },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Schema::AuditLog::Structure::Action

=head1 VERSION

version 0.6.4

=head1 AUTHOR

Mark Jubenville <ioncache@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Jubenville.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
