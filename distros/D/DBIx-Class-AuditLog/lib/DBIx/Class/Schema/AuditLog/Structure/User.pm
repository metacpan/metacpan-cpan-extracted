package DBIx::Class::Schema::AuditLog::Structure::User;
$DBIx::Class::Schema::AuditLog::Structure::User::VERSION = '0.6.4';
use base 'DBIx::Class::Schema::AuditLog::Structure::Base';

use strict;
use warnings;

__PACKAGE__->table('audit_log_user');

__PACKAGE__->add_columns(
    'id' => {
        'data_type'         => 'integer',
        'is_auto_increment' => 1,
        'is_nullable'       => 0,
    },
    'name' => {
        'data_type'   => 'varchar',
        'is_nullable' => 0,
        'size'        => 100,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint( constraint_name => [qw/name/], );

__PACKAGE__->has_many(
    'Changeset',
    'DBIx::Class::Schema::AuditLog::Structure::Changeset',
    { 'foreign.user_id' => 'self.id' },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Schema::AuditLog::Structure::User

=head1 VERSION

version 0.6.4

=head1 AUTHOR

Mark Jubenville <ioncache@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Jubenville.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
