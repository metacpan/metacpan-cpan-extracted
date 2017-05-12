package Test::App::Container;
use Moose;
use Bread::Board;

extends 'Catalyst::Plugin::Bread::Board::Container';

sub BUILD {
    my $self = shift;

    container $self => as {

        container 'Model' => as {
            container 'DBIC' => as {
                service 'schema_class' => 'Test::App::Schema::DB';
                service 'connect_info' => (
                    block => sub {
                        my $root = (shift)->param('app_root');
                        'dbi:SQLite:dbname=' . $root->file(qw[ root db ])
                    },
                    dependencies => [ depends_on('/app_root') ]
                );
            };
        };

        container 'View' => as {
            container 'TT' => as {
                service 'TEMPLATE_EXTENSION' => '.tt';
                service 'INCLUDE_PATH'       => (
                    block => sub {
                        my $root = (shift)->param('app_root');
                        [ $root->subdir('root/templates')->stringify ]
                    },
                    dependencies => [ depends_on('/app_root') ]
                );
            };
        };

        container 'Controller' => as {
            container 'Foo' => as {
                service bar => 42;
            },
        };
    };
}

no Bread::Board; no Moose; 1;
