use Test2::V0;
use Test2::Tools::Spec;

use Config::AWS;
use Path::Tiny qw( path tempdir );
use Ref::Util qw( is_globref );

my $DIR = tempdir 'ConfigAWS-XXXXXXXXX';

$DIR->child('config/.aws')->mkpath;
$DIR->child('credentials/.aws')->mkpath;

$DIR->child('config/.aws/config')->touch->spew(<<'CONFIG');
[alternate]
root_key = alternate root value
parent =
  child = alternate value for child
another_root_key = alternate another root value
another_parent =
  another_child = alternate value for another child
[default]
root_key = root value
another_root_key = another root value
parent =
  child = value for child
[bad]
 = ignored
empty_value =
parent =
  child = bad child
false_parent = 0
  child = ignored
trailing_empty =
CONFIG

$DIR->child('credentials/.aws/credentials')->touch->spew(<<'CREDENTIALS');
[profile default]
root_key = credentials root value
another_root_key = another credentials root value
parent =
  child = value for credentials child
[profile with-hyphens]
key = key-with-hyphens
CREDENTIALS

my %PROFILES = (
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
        false_parent => 0,
        trailing_empty => '',
    },
);

describe 'Config::AWS read tests' => sub {
    describe 'Read tests' => sub {
        my $file;

        before_all 'Prepare data' => sub {
            $ENV{HOMEDIR} = $ENV{HOME} = $DIR->child('config')->stringify;
            $file = $DIR->child('config/.aws/config');
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
            local $ENV{AWS_CONFIG_FILE} = $DIR->child('config/.aws/config')->stringify;
            like Config::AWS::read( undef, 'default' ),
                { parent => { child => 'value for child' } },
                'Read default config file from ENV';

            local $ENV{AWS_SHARED_CREDENTIALS_FILE}
                = $DIR->child('credentials/.aws/credentials')->stringify;

            like Config::AWS::read( undef, 'default' ),
                { parent => { child => 'value for credentials child' } },
                'Read default credentials file from ENV';
        };

        it 'Reads profile with hyphens' => sub {
            my $file = $DIR->child('credentials/.aws/credentials');
            like Config::AWS::read( $file, 'with-hyphens' ),
                { key => 'key-with-hyphens' },
                'Read default credentials file from ENV';
        };

        it 'Does not die on bad config data' => sub {
            is Config::AWS::read( $DIR->child('config/.aws/config'), 'bad' ),
                $PROFILES{bad},
                'Reads a bad profile';
        };

        it 'Reads all profiles' => sub {
            is Config::AWS::read_all( $DIR->child('config/.aws/config') ),
                \%PROFILES,
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

            case 'Read handle' => sub {
                $input = $file->openr_utf8;
            };

            before_each 'Reset handles' => sub {
                seek $input, 0, 0 if is_globref $input;
            };

            it 'Uses the default profile' => sub {
                is Config::AWS::read( $input ),
                    $PROFILES{default}, 'Read default profile';
            };

            it 'Reads the profile from ENV' => sub {
                local $ENV{AWS_DEFAULT_PROFILE} = 'alternate';
                is Config::AWS::read( $input ),
                    $PROFILES{alternate}, 'Read alternate profile';
            };

            it 'Reads the profile from undef ENV' => sub {
                $ENV{AWS_DEFAULT_PROFILE} = undef;
                is Config::AWS::read( $input ),
                    $PROFILES{default}, 'Read default profile if undef';
            };

            it 'Takes a profile argument' => sub {
                is Config::AWS::read( $input, 'alternate' ),
                    $PROFILES{alternate}, 'Read given profile';
            };

            it 'Takes a profile argument over ENV' => sub {
                local $ENV{AWS_DEFAULT_PROFILE} = 'alternate';
                is Config::AWS::read( $input, 'default' ),
                    $PROFILES{default}, 'Given profile overrides ENV';
            };
        };
    };

    tests 'Unreadable file' => sub {
        like dies {
                local $ENV{AWS_CONFIG_FILE}             = '' . {};
                local $ENV{AWS_SHARED_CREDENTIALS_FILE} = '' . {};
                Config::AWS::read;
            },
            qr/Cannot read from .*: .*/,
            'read() dies when reading missing file';

        like dies {
                Config::AWS::read_file( '' . {} );
            },
            qr/Cannot read from .*: .*/,
            'read_file() dies when reading missing file';
    };
};

describe 'Config::AWS in Config::INI compatibility mode' => sub {
    describe 'Read tests' => sub {
        my ($function, $file, $input);

        before_all 'Prepare data' => sub {
            $ENV{HOMEDIR} = $ENV{HOME} = $DIR->child('config')->stringify;
            $file = $DIR->child('config/.aws/config');
        };

        case 'read_file()' => sub {
            $function = \&Config::AWS::read_file;
            $input = $file->stringify;
        };
        case 'read_string()' => sub {
            $function = \&Config::AWS::read_string;
            $input = $file->slurp;
        };
        case 'read_handle()' => sub {
            $function = \&Config::AWS::read_handle;
            $input = $file->openr_utf8;
        };

        before_each 'Reset handles' => sub {
            seek $input, 0, 0 if is_globref $input;
        };

        it 'Dies with unparseable arguments' => sub {
            like dies { $function->() },
                qr/\w+ is missing/i,
                'Requires an argument';

            like dies { $function->( {} ) },
                qr/argument was not a/i,
                'Plain hash ref';

            like dies { $function->( bless( {}, 'Some::Package' ) ) },
                qr/argument was not a/i,
                'Unrecognised object type';
        };

        tests 'With no profile' => sub {
            is $function->( $input ),
                \%PROFILES,
                'Gets all profiles';
        };

        tests 'With a profile' => sub {
            my $profile = 'alternate';
            is $function->( $input, $profile ),
                $PROFILES{$profile},
                'Gets a single profile';
        };
    };

    tests 'Undefined string in read_string' => sub {
        is warnings { Config::AWS::read_string(undef) },
            [ match qr/Reading config with only one line or less\. Faulty input\?/ ],
            'Warns about faulty input';
    };
};

done_testing;
