package DBIx::Class::Schema::AuditLog::Structure::AuditedTable;
$DBIx::Class::Schema::AuditLog::Structure::AuditedTable::VERSION = '0.6.4';
use base 'DBIx::Class::Schema::AuditLog::Structure::Base';

use strict;
use warnings;

__PACKAGE__->table('audit_log_table');

__PACKAGE__->add_columns(
    'id' => {
        'data_type'         => 'integer',
        'is_auto_increment' => 1,
        'is_nullable'       => 0,
        'name'              => 'id',
    },
    'name' => {
        'data_type'   => 'varchar',
        'is_nullable' => 0,
        'name'        => 'name',
        'size'        => 40,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint( [qw/name/] );

__PACKAGE__->has_many(
    'Field',
    'DBIx::Class::Schema::AuditLog::Structure::Field',
    { 'foreign.audited_table_id' => 'self.id' },
);

__PACKAGE__->has_many(
    'Action',
    'DBIx::Class::Schema::AuditLog::Structure::Action',
    { 'foreign.audited_table_id' => 'self.id' },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Schema::AuditLog::Structure::AuditedTable

=head1 VERSION

version 0.6.4

=head1 AUTHOR

Mark Jubenville <ioncache@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Jubenville.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
