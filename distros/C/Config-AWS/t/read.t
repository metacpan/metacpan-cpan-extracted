use Test2::V0;
use Test2::Tools::Spec;

use Config::AWS;
use Path::Tiny qw( path );
use File::Share qw( dist_dir );

describe 'Config::AWS read tests' => sub {
    my ($dir, $file, $profiles);

    before_all 'Prepare data' => sub {
        $profiles = {
            default => {
                root_key => 'root value',
                another_root_key => 'another root value',
                parent => {
                    child => 'value for child',
                },
            },
            alternate => {
                root_key => 'alternate root value',
                another_root_key => 'alternate another root value',
                parent => {
                    child => 'alternate value for child',
                },
                another_parent => {
                    another_child => 'alternate value for another child',
                },
            },
            bad => {
                empty_value => '',
                parent => { child => 'bad child' },
            },
        };

        $dir = path dist_dir('Config-AWS');
        $ENV{HOMEDIR} = $ENV{HOME} = $dir->child('config')->stringify;
        $file = $dir->child('config/.aws/config');
    };

    describe 'Dies with unparseable arguments' => sub {
        my ($function);

        case 'read()' => sub {
            $function = \&Config::AWS::read;
        };
        case 'read_all()' => sub {
            $function = \&Config::AWS::read_all;
        };

        it 'Tests parameter validation' => sub {
            like dies { $function->( {} ) },
                qr/could not use .* as source/i,
                'Plain hash ref';

            like dies { $function->( bless( {}, 'Some::Package' ) ) },
                qr/cannot read from object/i,
                'Object which is not a Path::Tiny';
        };
    };

    it 'Reads file from ENV' => sub {
        my $dir = path dist_dir('Config-AWS');

        local $ENV{AWS_CONFIG_FILE} = $dir->child('config/.aws/config');
        like Config::AWS::read( undef, 'default' ),
            { parent => { child => 'value for child' } },
            'Read default config file from ENV';

        local $ENV{AWS_SHARED_CREDENTIALS_FILE}
            = $dir->child('credentials/.aws/credentials');

        like Config::AWS::read( undef, 'default' ),
            { parent => { child => 'value for credentials child' } },
            'Read default credentials file from ENV';
    };

    it 'Reads profile with hyphens' => sub {
        my $dir = path dist_dir('Config-AWS');

        my $file = $dir->child('credentials/.aws/credentials');
        like Config::AWS::read( $file, 'with-hyphens' ),
            { key => 'key-with-hyphens' },
            'Read default credentials file from ENV';
    };

    it 'Does not die on bad config data' => sub {
        is Config::AWS::read( $dir->child('config/.aws/config'), 'bad' ),
            $profiles->{bad},
            'Reads a bad profile';
    };

    it 'Reads all profiles' => sub {
        is Config::AWS::read_all( $dir->child('config/.aws/config') ),
            $profiles,
            'Reads all profiles';

    };

    describe 'Read config' => sub {
        my ($input);

        case 'No arguments' => sub {
            $input = undef;
        };

        case 'Read object' => sub {
            $input = $file;
        };

        case 'Read file' => sub {
            $input = $file->stringify;
        };

        case 'Read lines' => sub {
            $input = [ $file->lines({ chomp => 1 }) ];
        };

        case 'Read slurped contents' => sub {
            my $string = $file->slurp;
            $input = \$string;
        };

        it 'Uses the default profile' => sub {
            is Config::AWS::read( $input ),
                $profiles->{default}, 'Read default profile';
        };

        it 'Reads the profile from ENV' => sub {
            local $ENV{AWS_DEFAULT_PROFILE} = 'alternate';
            is Config::AWS::read( $input ),
                $profiles->{alternate}, 'Read alternate profile';

            $ENV{AWS_DEFAULT_PROFILE} = undef;
            is Config::AWS::read( $input ),
                $profiles->{default}, 'Read default profile if undef';
        };

        it 'Takes a profile argument' => sub {
            is Config::AWS::read( $input, 'alternate' ),
                $profiles->{alternate}, 'Read given profile';

            local $ENV{AWS_DEFAULT_PROFILE} = 'alternate';
            is Config::AWS::read( $input, 'default' ),
                $profiles->{default}, 'Given profile overrides ENV';
        };
    };
};

done_testing;
