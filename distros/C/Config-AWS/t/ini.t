use Test2::V0;
use Test2::Tools::Spec;

use Config::AWS;
use Path::Tiny qw( path );
use File::Share qw( dist_dir );
use Ref::Util qw( is_globref );

describe 'Config::AWS in Config::INI compatibility mode' => sub {
    my ($function, $file, $profiles, $input);

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

        my $dir = path dist_dir('Config-AWS');
        $ENV{HOMEDIR} = $ENV{HOME} = $dir->child('config')->stringify;
        $file = $dir->child('config/.aws/config');
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
            $profiles,
            'Gets all profiles';
    };

    tests 'With a profile' => sub {
        my $profile = 'alternate';
        is $function->( $input, $profile ),
            $profiles->{$profile},
            'Gets a single profile';
    };
};

tests 'Undefined string in read_string' => sub {
    is warnings { Config::AWS::read_string(undef) },
        [ match qr/Reading config with only one line or less\. Faulty input\?/ ],
        'Warns about faulty input';
};

done_testing;
