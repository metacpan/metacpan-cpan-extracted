use strict;
use warnings;

use Test::More;

plan tests => 9;

package My::Application;

use base 'Common::CLI';

package main;

{
    local @ARGV = qw( --help );

    my $app = My::Application->new(
        profile => {
            'optional' => [
                [ 'help', 'Display this help' ],
            ],
        },
    );

    {
        #
        # Check profile created
        #
        my $wanted_profile = {
            'optional' => [ 'help' ],
        };
        my ( $profile ) = $app->profile();
        is_deeply( $profile, $wanted_profile );
    }

    {
        #
        # Check help information created
        #
        my $wanted_help = [
            [ 'help', 'Display this help', 'help' ]
        ];
        my ( $help ) = $app->help();
        is_deeply( $help, $wanted_help );
    }

    {
        #
        # Check expected options
        #
        my $wanted_options = [ 'help' ];
        my ( $options ) = $app->options();
        is_deeply( $options, $wanted_options );
    }

    {
        #
        # Check validated options
        #
        my $wanted_options = { help => 1, };
        my ( $options ) = $app->validate_options();
        is_deeply( $options, $wanted_options );
    }

}

{
    local @ARGV = qw();

    my $app = My::Application->new(
        profile => {
            'required' => [
                [ 'import=s', 'File to import' ],
            ],
        },
    );

    {
        #
        # Check profile created
        #
        my $wanted_missing = [ 'import' ];
        my ( undef, undef, $missing ) = $app->validate_options();
        is_deeply( $missing, $wanted_missing );
    }
}

{
    local @ARGV = qw();

    my $app = My::Application->new(
        profile => {
            'optional' => [
                [ 'import=s', 'File to import' ],
            ],
            'defaults' => {
                'import' => '/tmp/import.csv',
            },
        },
    );

    {
        #
        # Check profile created
        #
        my $wanted_options = { 'import' => '/tmp/import.csv' };
        my $options = $app->validate_options();
        is_deeply( $options, $wanted_options );
    }
}

{
    local @ARGV = qw( --import /tmp/non-existent-file.csv );

    my $app = My::Application->new(
        profile => {
            'required' => [
                [ 'import=s', 'File to import' ],
            ],
            'constraint_methods' => {
                'import' => sub {
                    return;
                },
            },
        },
    );

    {
        #
        # Check profile created
        #
        my $wanted_invalid = [ 'import' ];
        my ( undef, $invalid, undef ) = $app->validate_options();
        is_deeply( [ sort @$invalid ], [ sort @$wanted_invalid ] );
    }
}

package My::Other::Application;

use base 'Common::CLI';

sub arguments {
    return (
        profile => {
            'required' => [
                [ 'import=s', 'File to import' ],
            ],
            'constraint_methods' => {
                'import' => sub {
                    return;
                },
            },
        },
    );
}

package main;

{
    local @ARGV = qw( --import /tmp/non-existent-file.csv );

    #
    # Check profile created
    #
    my $app = My::Other::Application->new();
    my $wanted_invalid = [ 'import' ];
    my ( undef, $invalid, undef ) = $app->validate_options();
    is_deeply( [ sort @$invalid ], [ sort @$wanted_invalid ] );
}

package My::Other::Yet::Application;

use base 'My::Other::Application';

sub arguments {
    my $self = shift;
    $self->merge_arguments( { $self->SUPER::arguments }, {
        profile => {
            'required' => [
                [ 'export=s', 'File to export' ],
            ],
            'constraint_methods' => {
                'export' => sub { return },
            }
        },
    } );
}

package main;

{
    local @ARGV = qw( --import /tmp/non-existent-file.csv  --export /tmp/file );

    #
    # Check profile created
    #
    my $app = My::Other::Yet::Application->new();
    my $wanted_invalid = [ 'import', 'export' ];
    my ( undef, $invalid, undef ) = $app->validate_options();
    is_deeply( [ sort @$invalid ], [ sort @$wanted_invalid ] );
}
