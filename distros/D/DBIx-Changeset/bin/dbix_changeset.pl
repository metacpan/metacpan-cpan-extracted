#!/usr/bin/env perl

use strict;
use warnings;

use DBIx::Changeset::App;

my $cmd = DBIx::Changeset::App->new();

my @config_files = ('/etc/dbix_changeset.yml', '/usr/local/etc/dbix_changeset.yml', $ENV{HOME}.'/.dbix_changeset.yml');

if ( $ENV{DBIX_CHANGESET_CONFIG} ) {
	@config_files = split(/:/xm,$ENV{DBIX_CHANGESET_CONFIG});
}

$cmd->config(\@config_files);

$cmd->run();

=head1 NAME
dbix_changeset.pl - Manage database changesets

=head1 SYNOPSIS
dbix_changeset.pl <command> [options]

run dbix_changeset.pl commands to see list of commands and dbix_changeset.pl <command> --help
for the commands options.

=head1 DESCRIPTION

C<dbix_changeset.pl> is command-line interface to L<DBIx::Changeset>.

=head1 CONFIGURATION

dbix-changeset.pl will look for configuration files before reading its command line
parameters. It looks for the following files in order: 
C</etc/dbix_changeset.yml>, C</usr/local/etc/dbix_changeset.yml>, C<$HOME/.dbix_changeset.yml>
each file will overwrite the values of the previous file. Also a list of configuration files 
can be set through the DBIX_UPDATE_CONFIG environment variable that will be loaded instead.

The configuration file is in YAML format, and each option available to a command can be set
in the file either at the root or as a key for that command name. I.E:

db_name: testdb
db_user: dbuser
db_password: dbpassword
create:
	template: '~/src/amarus/trunk/etc/delta_template.txt'


=head1 COPYRIGHT & LICENSE

Copyright 2004-2008 Grox Pty Ltd.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut
