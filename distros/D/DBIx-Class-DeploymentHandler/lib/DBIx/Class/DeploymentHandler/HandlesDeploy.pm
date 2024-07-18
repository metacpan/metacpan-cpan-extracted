package DBIx::Class::DeploymentHandler::HandlesDeploy;
$DBIx::Class::DeploymentHandler::HandlesDeploy::VERSION = '0.002234';
use Moose::Role;

# ABSTRACT: Interface for deploy methods

requires 'initialize';

requires 'prepare_deploy';
requires 'deploy';

requires 'prepare_resultsource_install';
requires 'install_resultsource';

requires 'prepare_upgrade';
requires 'upgrade_single_step';

requires 'prepare_downgrade';
requires 'downgrade_single_step';

requires 'txn_do';

1;

# vim: ts=2 sw=2 expandtab

__END__

=pod

=head1 NAME

DBIx::Class::DeploymentHandler::HandlesDeploy - Interface for deploy methods

=head1 KNOWN IMPLEMENTATIONS

=over

=item *

L<DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator>

=item *

L<DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::Deprecated>

=back

=head1 METHODS

=head2 initialize

 $dh->initialize({
   version      => 1,
   storage_type => 'SQLite'
 });

Run scripts before deploying to the database

=head2 prepare_deploy

 $dh->prepare_deploy

Generate the needed data files to install the schema to the database.

=head2 deploy

 $dh->deploy({ version => 1 })

Deploy the schema to the database.

=head2 prepare_resultsource_install

 $dh->prepare_resultsource_install({
   result_source => $resultset->result_source,
 })

Takes a L<DBIx::Class::ResultSource> and generates a single migration file to
create the resultsource's table.

=head2 install_resultsource

 $dh->install_resultsource({
   result_source => $resultset->result_source,
   version       => 1,
 })

Takes a L<DBIx::Class::ResultSource> and runs a single migration file to
deploy the resultsource's table.

=head2 prepare_upgrade

 $dh->prepare_upgrade({
   from_version => 1,
   to_version   => 2,
   version_set  => [1, 2]
 });

Takes two versions and a version set.  This basically is supposed to generate
the needed C<SQL> to migrate up from the first version to the second version.
The version set uniquely identifies the migration.

=head2 prepare_downgrade

 $dh->prepare_downgrade({
   from_version => 2,
   to_version   => 1,
   version_set  => [1, 2]
 });

Takes two versions and a version set.  This basically is supposed to generate
the needed C<SQL> to migrate down from the first version to the second version.
The version set uniquely identifies the migration and should match its
respective upgrade version set.

=head2 upgrade_single_step

 my ($ddl, $sql) = @{
   $dh->upgrade_single_step({ version_set => $version_set })
 ||[]}

Call a single upgrade migration.  Takes a version set as an argument.
Optionally return C<< [ $ddl, $upgrade_sql ] >> where C<$ddl> is the DDL for
that version of the schema and C<$upgrade_sql> is the SQL that was run to
upgrade the database.

=head2 downgrade_single_step

 $dh->downgrade_single_step($version_set);

Call a single downgrade migration.  Takes a version set as an argument.
Optionally return C<< [ $ddl, $upgrade_sql ] >> where C<$ddl> is the DDL for
that version of the schema and C<$upgrade_sql> is the SQL that was run to
upgrade the database.

=head2 txn_do

 $dh->txn_do(sub { ... })

Wrap the passed coderef in a transaction (if transactions are enabled.)

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
