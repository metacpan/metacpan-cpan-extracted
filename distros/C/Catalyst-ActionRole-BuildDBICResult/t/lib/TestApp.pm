package # Hide from PAUSE
  TestApp;

use Moose 1.03;
use namespace::autoclean;

extends Catalyst => { -version => 5.80 };

__PACKAGE__->config(
	name => 'TestApp',
	'Model::Schema' => {
        schema_class => 'TestApp::DBIC',
		connect_info => {
			dsn => 'dbi:SQLite:dbname=:memory:',
		},
	},
    'Controller::Inherit' => {
        action_args => {
            'role_value_store' => {
                store => {
                    value => 'fff',
                },
                find_condition => [ 'primary', ['name'] ],
                auto_stash => 'role',            
            },
        },
    },
);

__PACKAGE__->setup;

sub installdb {
    my $class = shift @_;
    my $schema = $class->model('Schema')->schema;
    my $schema_version = $schema->schema_version;
    my $sql_dir = $class->path_to('etc','sql');
    $schema->deploy({},$sql_dir);
    return 1;
}

sub deploy_dbfixtures {
    my $class = shift @_;
    my $schema = $class->model('Schema')->schema;

    $schema->populate('User' => [
        [qw(user_id email)],
        [100, 'john@shutterstock.com'],
        [101, 'james@shutterstock.com'],
        [102, 'jay@shutterstock.com'],
        [103, 'vanessa@shutterstock.com'],
        [104, 'error@error.com'],
    ]);
    $schema->populate('Role' => [
        [qw(role_id name)],
        [200, 'member'],
        [201, 'admin'],
    ]);
    $schema->populate('UserRole' => [
        [qw(fk_user_id fk_role_id)],
        [100, 200],
        [100, 201],
        [101, 200],
        [101, 201],
        [102, 200],
        [103, 201],
    ]);

    return 1;
}

## The following is used for authors if you need to change the testing database
## and then rebuild the setup ddl file.

sub generate_ddl {
    my $class = shift @_;
    my $schema = $class->model('Schema')->schema;
    my $sql_dir = $class->path_to('etc','sql');
    my $version = $schema->schema_version();
    $schema->create_ddl_dir( ['SQLite'], $version, $sql_dir );
    return 1;
}

1;
