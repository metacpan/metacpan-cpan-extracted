package Storage::PostgreSQL;

use Test::Roo::Role;
use Test::PostgreSQL;
with qw(Storage::Common);

BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        plan skip_all => 'SKIP these tests are for testing by the author';
    }
    unless ( $ENV{POSTGRES_HOME} ) {
        plan skip_all =>
          "SKIP postgresql tests because POSTGRES_HOME env variable not set";
    }
}

use Test::Requires qw(DBD::Pg);

has _pg => ( is => 'lazy', );

sub _build__pg {
    return Test::PostgreSQL->new;
}

sub connect_info { shift->_pg->dsn }

sub should_skip {
    my ( $self, $error, $method ) = @_;
    my %should_skip = (
        data_type => {
            columns =>
'PostgreSQL error message does not provide a clean way of fetching this data'
        }
    );
    return $should_skip{$error}{$method};
}

1;

__END__

=head1 NAME

Storage::PostgreSQL - PostgreSQL specific test setup

=head1 ENVIRONMENT VARIABLES

Tests using this module will not run unless C<AUTHOR_TESTING> is set to a true value
and C<POSTGRES_HOME> points to the location of your PostgreSQL installation.

Assumes the current user has a right to create and destroy databases.

=head1 METHODS

=head2 C<connect_info>

Returns the connection information for schema classes backed by PostgreSQL.

=head2 C<should_skip( $error_type, $method )>

    if ( my $reason = $tests->should_skip( 'data_type', 'columns' ) ) {
        SKIP: {
            skip $reason, $num_tests;
            ...
        }
    }

Given an error type and a method to test on the error object, returns a reason
why this particular test should be skipped.
