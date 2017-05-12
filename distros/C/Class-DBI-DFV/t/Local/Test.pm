# $Id: Test.pm 10 2005-11-15 22:19:45Z evdb $
# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.
# http://ecclestoad.co.uk

use strict;
use warnings;

# Create a package that will be used to test the CDBI functions.
package Local::Test;
use base 'Class::DBI::DFV';

use Data::Dumper;

__PACKAGE__->connection( 'dbi:SQLite:dbname=t/test-database.sqlite', '', '' );
__PACKAGE__->table('cdbi_tests');
__PACKAGE__->columns( All => qw( id val_unique val_optional dup_a dup_b ) );

# this is a slightly dirty hack to emulate a sequence. It works four
# our purposes but would not work in other situations.
my $id = 1;

sub dfv_profile {
    my $class = shift;

    return {
        filters  => 'trim',
        required => [qw/val_unique/],

        defaults => { id => sub { $id++ }, },

        constraint_methods => {
            val_unique => $class->unique_constraint,
            dup_a      => $class->unique_constraint( 'dup_a', 'dup_b' ),
        },
        msgs => {
            format      => 'validation error: %s',
            constraints => { unique_constraint => 'duplicate' },
        },
    };
}

1;
