
=head1 DESCRIPTION

This tests the L<CPAN::Testers::Backend::Migrate::MetabaseUsers> module
to make sure that users are migrated correctly and only the last record
is kept.

=head1 SEE ALSO

L<CPAN::Testers::Backend::Migrate::MetabaseUsers>

=cut

use CPAN::Testers::Backend::Base 'Test';
use CPAN::Testers::Backend::Migrate::MetabaseUsers;
use CPAN::Testers::Schema;
use DBI;

my $class = 'CPAN::Testers::Backend::Migrate::MetabaseUsers';
my $schema = CPAN::Testers::Schema->connect( 'dbi:SQLite::memory:', undef, undef, { ignore_version => 1 } );
$schema->deploy;

my $dbh = DBI->connect( 'dbi:SQLite::memory:' );
$dbh->do( 'CREATE TABLE `metabase` (
  `guid` char(36) PRIMARY KEY,
  `id` int(10) NOT NULL,
  `updated` varchar(32) DEFAULT NULL,
  `report` longblob NOT NULL,
  `fact` longblob
)' );
$dbh->do( 'CREATE TABLE `testers_email` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `resource` varchar(64) NOT NULL,
  `fullname` varchar(255) NOT NULL,
  `email` varchar(255) DEFAULT NULL
) ');

$dbh->do( 'INSERT INTO testers_email (resource, fullname, email ) VALUES (
    "metabase:user:12345678-1234-1234-1234-123456789012",
    "Doug Bell",
    "doug@preaction.me"
)' );
$dbh->do( 'INSERT INTO testers_email (resource, fullname, email ) VALUES (
    "metabase:user:11111111-1111-1111-1111-111111111111",
    "Chris Williams",
    "root@klanker.net"
)' );
$dbh->do( 'INSERT INTO testers_email (resource, fullname, email ) VALUES (
    "metabase:user:11111111-1111-1111-1111-111111111111",
    "Chris Williams",
    "bingos@example.com"
)' );

subtest 'migrate users' => sub {
    $class->new( schema => $schema, metabase_dbh => $dbh )->run;
    my @users = $schema->resultset( 'MetabaseUser' )->all;
    is scalar @users, 2, 'two users were migrated';
    my ( $user ) = grep { $_->fullname eq 'Chris Williams' } @users;
    is $user->resource, 'metabase:user:11111111-1111-1111-1111-111111111111',
        'resource for bingos is correct';
    is $user->email, 'bingos@example.com', 'the last registered e-mail is used';

    ( $user ) = grep { $_->fullname eq 'Doug Bell' } @users;
    is $user->resource, 'metabase:user:12345678-1234-1234-1234-123456789012',
        'resource for preaction is correct';
    is $user->email, 'doug@preaction.me', 'the last registered e-mail is used';
};

$dbh->do( 'INSERT INTO testers_email (resource, fullname, email ) VALUES (
    "metabase:user:11111111-1111-1111-1111-111111111111",
    "Chris Williams",
    "real@fake.email"
)' );
$dbh->do( 'INSERT INTO testers_email (resource, fullname, email ) VALUES (
    "metabase:user:22222222-2222-2222-2222-222222222222",
    "Ray Mannarelli",
    "raytestinger@yahoo.com"
)' );

subtest 'migrate users again' => sub {
    $class->new( schema => $schema, metabase_dbh => $dbh )->run;

    my @users = $schema->resultset( 'MetabaseUser' )->all;
    is scalar @users, 3, 'three users migrated in total';
    my ( $user ) = grep { $_->fullname eq 'Chris Williams' } @users;
    is $user->resource, 'metabase:user:11111111-1111-1111-1111-111111111111',
        'resource for bingos is correct';
    is $user->email, 'real@fake.email', 'the last registered e-mail is used';

    ( $user ) = grep { $_->fullname eq 'Ray Mannarelli' } @users;
    is $user->resource, 'metabase:user:22222222-2222-2222-2222-222222222222',
        'resource for raytestinger is correct';
    is $user->email, 'raytestinger@yahoo.com', 'the last registered e-mail is used';
};

done_testing;

