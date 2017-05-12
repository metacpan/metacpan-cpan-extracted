## no critic (Moose::RequireMakeImmutable)
use strict;
use warnings;

use Test::Database::Migrator;
use Test::More 0.88;

use Database::Migrator::Pg;

{
    package Test::Database::Migrator::Pg;

    use Moose;
    use namespace::autoclean;

    extends 'Test::Database::Migrator';

    around _write_ddl_file => sub {
        my $orig = shift;
        my $self = shift;
        my $file = shift;
        my $ddl  = shift;

        $ddl = <<"EOF";
SET CLIENT_MIN_MESSAGES = ERROR;

$ddl
EOF

        $self->$orig( $file, $ddl );
    };

    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    sub _tables {
        my $self = shift;

        my @tables;

        my $sth = $self->_dbh()->table_info( undef, 'public', undef, undef );
        while ( my $table = $sth->fetchrow_hashref() ) {
            push @tables, $table->{pg_table};
        }

        ## no critic (Subroutines::ProhibitReturnSort)
        return sort @tables;
    }

    sub _indexes_on {
        my $self  = shift;
        my $table = shift;

        my @indexes;

        my $sth = $self->_dbh()
            ->statistics_info( undef, 'public', $table, undef, undef );
        while ( my $index = $sth->fetchrow_hashref() ) {

            # With Pg we get some weird results back, including an index with
            # undef as the name.
            #
            ## no critic (ControlStructures::ProhibitNegativeExpressionsInUnlessAndUntilConditions)
            next
                unless $index->{INDEX_NAME}
                && $index->{COLUMN_NAME} !~ /_id$/;

            push @indexes, $index->{INDEX_NAME};
        }

        ## no critic (Subroutines::ProhibitReturnSort)
        return sort @indexes;
    }
}

Test::Database::Migrator::Pg->new(
    class => 'Database::Migrator::Pg',
)->run_tests();

done_testing();
