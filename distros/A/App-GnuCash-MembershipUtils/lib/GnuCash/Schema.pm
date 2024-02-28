use utf8;
package GnuCash::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-02-18 13:56:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:D6Jk1c48fGe4gH1PPLpVQg

=head1 NAME

GnuCash::Schema - Schema generated using dbicdump

=head1 SYNOPSIS

    use GnuCash::Schema;

    my $schema = GnuCash::Schema->connect("dbi:SQLite:/path/to/file.gnucash");

    my $account = $schema->resultset->('Account')->search()->first();

=head1 DESCRIPTION

This module and all the GnuCash::Schema::Result modules were auto generated
by running the following: 

    dbicdump -o dump_directory=./lib -o components='["InflateColumn::DateTime"]' GnuCash::Schema dbi::SQLite:/path/to/sample.gnucash

=cut

1;
