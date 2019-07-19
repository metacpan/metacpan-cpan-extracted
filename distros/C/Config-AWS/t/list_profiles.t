use Test2::V0;
use Test2::Tools::Spec;

use Config::AWS;
use Path::Tiny qw( path );
use File::Share qw( dist_dir );

describe 'Config::AWS list_profiles tests' => sub {

    it 'Dies with unparseable arguments' => sub {
        like dies { Config::AWS::list_profiles( {} ) },
            qr/could not use .* as source/i,
            'Plain hash ref';

        like dies { Config::AWS::list_profiles( bless( {}, 'Some::Package' ) ) },
            qr/cannot read from objects of type/i,
            'Object which is not a Path::Tiny';
    };

    describe 'List config profiles' => sub {
        my ($input, $result);
        my $dir = path dist_dir('Config-AWS');

        after_case 'Clear input' => sub { undef $input };

        case 'Credentials from ENV' => sub {
            $ENV{AWS_SHARED_CREDENTIALS_FILE} = $dir->child('credentials/.aws/credentials');
            $ENV{AWS_CONFIG_FILE} = {}; # Not a file that exists
            undef $input;
            $result = [qw( default with-hyphens  )];
        };

        case 'Config from ENV' => sub {
            $ENV{AWS_SHARED_CREDENTIALS_FILE} = {}; # Not a file that exists
            $ENV{AWS_CONFIG_FILE} = $dir->child('config/.aws/config');
            undef $input;
            $result = [qw( alternate bad default )];
        };

        case 'Credentials as argument' => sub {
            $input = $dir->child('credentials/.aws/credentials');
            $result = [qw( default with-hyphens  )];
        };

        case 'Config as argument' => sub {
            $input = $dir->child('config/.aws/config')->stringify;
            $result = [qw( alternate bad default )];
        };

        case 'Slurped contents' => sub {
            my $string = $dir->child('config/.aws/config')->slurp;
            $input = \$string;
            $result = [qw( alternate bad default )];
        };

        case 'Path::Tiny object' => sub {
            $input = $dir->child('config/.aws/config');
            $result = [qw( alternate bad default )];
        };

        it 'Reads a list of profiles' => sub {
            is [ sort( Config::AWS::list_profiles( $input ) ) ], $result;
        };
    };
};

done_testing;
