#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use Path::Class;

use Test::More;
use Test::Exception;
use Test::Moose;

BEGIN {
    use_ok('Catalyst::Plugin::Bread::Board::Container');
}

{
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

            container 'Plugin' => as {
                container 'Session' => as {
                    service 'cookie_name' => 'test_session';
                    service 'expires'     => 1920;
                    service 'namespace'   => 'test';
                };
            };

        };
    }
}

my $app_root = dir( $FindBin::Bin );

my $c = Test::App::Container->new(
    name     => 'Test010',
    app_root => $app_root,
);
isa_ok($c, 'Test::App::Container');
isa_ok($c, 'Catalyst::Plugin::Bread::Board::Container');

is_deeply(
    $c->as_catalyst_config,
    {
        'app_root'    => $app_root,
        'Model::DBIC' => {
            'schema_class' => 'Test::App::Schema::DB',
            'connect_info' => 'dbi:SQLite:dbname=' . $app_root->file(qw[ root db ])
        },
        'View::TT' => {
            'TEMPLATE_EXTENSION' => '.tt',
            'INCLUDE_PATH' => [
                $app_root->file(qw[ root templates ])->stringify
            ]
        },
        'Plugin::Session' => {
            'namespace'   => 'test',
            'cookie_name' => 'test_session',
            'expires'     => 1920
        }
    },
    '... got the config we expected for Catalyst'
);

done_testing;