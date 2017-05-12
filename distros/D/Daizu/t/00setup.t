use warnings;
use strict;

use Test::More;
use Path::Class qw( file );
use Carp::Assert qw( assert );
use Daizu::Test qw(
    init_tests test_config
    create_test_repos create_database
);
use Daizu::Util qw( db_insert );

init_tests(1, 1);

my $ra = create_test_repos();
assert($ra);

my $db = create_database();
assert($db);

rmtree($Daizu::Test::TEST_OUTPUT_DIR)
    if -e $Daizu::Test::TEST_OUTPUT_DIR;

# Add people to the database, for usernames used in the test repository.
db_insert($db, 'person', id => 1, username => 'geoff');
db_insert($db, 'person_info',
    person_id => 1,
    path => '',
    name => 'Geoff Richards',
    email => 'geoff@daizucms.org',
    uri => 'http://www.laxan.com/',
);

db_insert($db, 'person', id => 2, username => 'alice');
db_insert($db, 'person_info',
    person_id => 2,
    path => 'foo.com',
    name => 'Alice Foonly',
);
db_insert($db, 'person_info',
    person_id => 2,
    path => 'example.com',
    name => 'Alice Anonym',
);

db_insert($db, 'person', id => 3, username => 'bob');
db_insert($db, 'person_info',
    person_id => 3,
    path => '',
    name => 'bob',
    email => 'bob@daizucms.org',
);

# Create the config file to use from the template.
{
    open my $tmpl_file, '<', 'test-config.xml.tmpl'
        or die "error opening test config template file: $!";
    my $config = do { local $/; <$tmpl_file> };

    {
        my $test_config = test_config();
        my $dbconf = 'dsn="' . _xml_esc($test_config->{'test-dsn'}) . '"';
        for (qw( user password )) {
            $dbconf .= " $_=\"" . _xml_esc($test_config->{"test-$_"}) . '"'
                if exists $test_config->{"test-$_"}
        }
        $config =~ s/\@TEST_DATABASE_CONFIG\@/$dbconf/g;
    }

    {
        my $test_repos_url = _xml_esc($Daizu::Test::TEST_REPOS_URL);
        $config =~ s/\@TEST_REPOS_URL\@/$test_repos_url/g;
        my $test_output_dir = _xml_esc($Daizu::Test::TEST_OUTPUT_DIR);
        $config =~ s/\@TEST_OUTPUT_DIR\@/$test_output_dir/g;
    }

    open my $config_file, '>', 'test-config.xml'
        or die "error opening test config file: $!";
    print $config_file $config or die $!;
    close $config_file or die $!;
}

ok(1, 'set up test database and repository');


sub _xml_esc
{
    my ($s) = @_;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/"/&quot;/g;
    return $s;
}

# vi:ts=4 sw=4 expandtab filetype=perl
