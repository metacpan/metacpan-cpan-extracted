use warnings;
use strict;
use Test::More tests => 10;
use File::Spec;
use Test::TempDir::Tiny;
use DBI;

use App::SpamcupNG::Summary;
use App::SpamcupNG::Summary::Receiver;
use App::SpamcupNG::Summary::Recorder;

my $summary = App::SpamcupNG::Summary->new;
$summary->set_age_unit('hour');
$summary->set_age(2);
$summary->set_charset('utf-8');
$summary->set_content_type('text/html');
$summary->set_mailer('WebService/1.1.18749 YMailNorrin');
$summary->set_tracking_id('z6746172301zed5b6b1ebead7134e06e5ae08cc87e0cz');
$summary->set_receivers(
    [
        [ 'report_spam@hotmail.com',       7173783708 ],
        [ 'junk@office365.microsoft.com',  7173783709 ],
        [ 'abuse@messaging.microsoft.com', 7173783710 ]
    ]
);

my $dir     = tempdir();
my $db_file = File::Spec->catfile( $dir, 'sample.db' );
note("Using $db_file");
my $now      = 1648003838;
my $recorder = App::SpamcupNG::Summary::Recorder->new( $db_file, $now );
ok( $recorder->init,           'database is properly initialized' );
ok( $recorder->save($summary), 'a summary is properly persisted' );
note('Now forcing database to be persisted on disk');
$recorder->{dbh}->disconnect;

note('Now checking what is on DB');
my $dbh             = DBI->connect( "dbi:SQLite:dbname=$db_file", '', '' );
my $result_ref      = query_all_tables($dbh);
my @expected_tables = (
    'email_content_type', 'spam_age_unit',
    'email_charset',      'receiver',
    'mailer',             'summary',
    'summary_receiver'
);
is_deeply( $result_ref, \@expected_tables, 'got the expected tables' );

my %expected_results;

@expected_results{@expected_tables} = (
    [ 1, 'text/html' ],
    [ 1, 'hour' ],
    [ 1, 'utf-8' ],
    [ 1, 'report_spam@hotmail.com' ],
    [ 1, 'WebService/1.1.18749 YMailNorrin' ],
    [
        1,    'z6746172301zed5b6b1ebead7134e06e5ae08cc87e0cz',
        $now, 1, 1, 2, 1, 1
    ],
    [ 1, 1, 1, '7173783708' ]
);

foreach my $table ( keys(%expected_results) ) {
    $result_ref = query_single_table( $dbh, $table );
    is_deeply(
        $result_ref,
        $expected_results{$table},
        "got the expected on '$table' table"
    ) or diag( explain($result_ref) );
}

sub query_single_table {
    my ( $dbh, $table ) = @_;
    return $dbh->selectrow_arrayref("SELECT * from $table");
}

sub query_all_tables {
    my $dbh        = shift;
    my $result_ref = $dbh->selectall_arrayref(
        q{
SELECT name
FROM sqlite_schema
WHERE type ='table' AND 
name NOT LIKE 'sqlite_%'
}
    );

    my @rows = map { $_->[0] } @{$result_ref};
    return \@rows;
}

# vim: filetype=perl

