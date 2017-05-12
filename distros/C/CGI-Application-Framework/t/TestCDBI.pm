
package TestCDBI;
use Class::DBI::Loader;
use DBI;

use base 'CGI::Application::Framework::CDBI';

use strict;
use warnings;

sub db_config_section {
    'db_test';
}

sub import {
    my $caller = caller;
    $caller->new_hook('database_init');
    $caller->add_callback('database_init', \&setup_tables);
}

# CGI::Application::Framework->register_external_callback('init', \&setup_tables);

my $Already_Setup_Tables;
sub setup_tables {

    return if $Already_Setup_Tables;

    my $config = CGI::Application::Plugin::Config::Context->get_current_context(__PACKAGE__->db_config_name);
    my $db_config = $config->{__PACKAGE__->db_config_section};

    my $dbh = DBI->connect($db_config->{'dsn'}, $db_config->{'username'}, $db_config->{'password'});

    create_database($dbh);

    my $loader = Class::DBI::Loader->new(
        # debug         => 1,
        dsn           => $db_config->{'dsn'},
        user          => $db_config->{'username'},
        password      => $db_config->{'password'},
        namespace     => __PACKAGE__,
        relationships => 0,
    );

    $Already_Setup_Tables = 1;

}

sub create_database {
    my ($dbh) = @_;

    # Don't care if this fails
    eval { $dbh->do( "DROP TABLE users" ); };

    $dbh->do(
        qq{
            CREATE TABLE users (
              uid INTEGER NOT NULL PRIMARY KEY,
              username varchar(50) UNIQUE,
              fullname varchar(50),
              password varchar(50)
            );
        }
    );
    $dbh->do(
        qq{
            INSERT INTO users (username, fullname, password) VALUES('test', '', 'seekrit');
        }
    );
    $dbh->do(
        qq{
            INSERT INTO users (username, fullname, password) VALUES('test\@example.com', '', 'sooperseekrit');
        }
    );
    $dbh->do(
        qq{
            INSERT INTO users (username, fullname, password) VALUES('bubba', 'Bubba the Beatific', 'banana');
        }
    );
}


1;


