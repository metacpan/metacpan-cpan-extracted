package DBIx::Class::Schema::AuditLog::Structure::Change;
$DBIx::Class::Schema::AuditLog::Structure::Change::VERSION = '0.6.4';
use base 'DBIx::Class::Schema::AuditLog::Structure::Base';

use strict;
use warnings;

__PACKAGE__->table('audit_log_change');

__PACKAGE__->add_columns(
    'id' => {
        'data_type'         => 'integer',
        'is_auto_increment' => 1,
        'is_nullable'       => 0,
    },
    'action_id' => {
        'data_type'   => 'integer',
        'is_nullable' => 0,
    },
    'field_id' => {
        'data_type'   => 'integer',
        'is_nullable' => 0,
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
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    'Action',
    'DBIx::Class::Schema::AuditLog::Structure::Action',
    { 'foreign.id' => 'self.action_id' },
);

__PACKAGE__->belongs_to(
    'Field',
    'DBIx::Class::Schema::AuditLog::Structure::Field',
    { 'foreign.id' => 'self.field_id' },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Schema::AuditLog::Structure::Change

=head1 VERSION

version 0.6.4

=head1 AUTHOR

Mark Jubenville <ioncache@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Jubenville.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
