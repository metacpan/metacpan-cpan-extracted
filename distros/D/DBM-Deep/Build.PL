use Module::Build 0.28; # for prepare_metadata

use strict;
use warnings FATAL => 'all';

my $build = Module::Build->subclass(
    class => "Module::Build::Custom",
    code => '
        sub ACTION_test {
            my $self = shift;
            if ( $self->notes(\'TEST_MYSQL_DSN\') ) {
                $ENV{$_} = $self->notes($_) for qw(
                    TEST_MYSQL_DSN TEST_MYSQL_USER TEST_MYSQL_PASS
                );
            }
            foreach my $name ( qw( LONG_TESTS TEST_SQLITE ) ) {
                $ENV{$name} = 1 if $self->notes( $name );
            }

            $self->SUPER::ACTION_test( @_ );
        }
        sub ACTION_dist {
            my $self = shift;
            my $v = $self->dist_version;
            system
              $^X,
             "-pi -le",
              q"$line = $. if ?VERSION?; "
                 . q"$_ = q<" . $v . q"> if $line && $. == $line+2",
             "lib/DBM/Deep.pod";
            $self->SUPER::ACTION_dist( @_ );
        }
    ',
)->new(
    module_name => 'DBM::Deep',
    license => 'perl',
    requires => {
        'perl'              => '5.008_004',
        'Fcntl'             => '0.01',
        'Scalar::Util'      => '1.14',
        'Digest::MD5'       => '1.00',
    },
    build_requires => {
        'File::Path'      => '0.01',
        'File::Temp'      => '0.01',
        'Pod::Usage'      => '1.3',
        'Test::Deep'      => '0.095',
        'Test::Warn'      => '0.08',
        'Test::More'      => '0.88', # done_testing
        'Test::Exception' => '0.21',
    },
    create_makefile_pl => 'traditional',
    create_readme    =>  1,
    add_to_cleanup => [
        'META.yml', '*.bak', '*.gz', 'Makefile.PL', 'cover_db',
    ],
    test_files => 't/??_*.t',
    auto_features => {
        sqlite_engine => {
            description => 'DBI support via SQLite',
            requires => {
                'DBI'         => '1.5',
                'DBD::SQLite' => '1.25',
            },
        },
        mysql_engine => {
            description => 'DBI support via MySQL',
            requires => {
                'DBI'        => '1.5',
                'DBD::mysql' => '4.001',
            },
        },
    },
    meta_add => { no_index => { directory => [ 'utils' ] } },
    meta_merge => {
        resources => {
            repository => 'https://github.com/robkinyon/dbm-deep',
        }
    },
);

if ( $build->y_n( "Run the long-running tests", 'n' ) ) {
    $build->notes( 'LONG_TESTS' => 1 );
}

if ( $build->features( 'sqlite_engine' ) ) {
    if ( $build->y_n( "Run the tests against the DBI engine via SQLite?", 'n' ) ) {
        $build->notes( 'TEST_SQLITE' => 1 );
    }
}

if ( $build->features( 'mysql_engine' ) ) {
    if ( $build->y_n( "Run the tests against the DBI engine via MySQL?", 'n' ) ) {
        my ($dsn, $user, $pass) = ('') x 3;
        $dsn = $build->prompt( "\tWhat is the full DSN (for example 'dbi:mysql:test')" );
        if ( $dsn ) {
            $user = $build->prompt( "\tWhat is the username?" );
            if ( $user ) {
                $pass = $build->prompt( "\tWhat is the password?" );
            }
        }

        $build->notes( 'TEST_MYSQL_DSN'  => $dsn );
        $build->notes( 'TEST_MYSQL_USER' => $user );
        $build->notes( 'TEST_MYSQL_PASS' => $pass );
    }
}

$build->create_build_script;
