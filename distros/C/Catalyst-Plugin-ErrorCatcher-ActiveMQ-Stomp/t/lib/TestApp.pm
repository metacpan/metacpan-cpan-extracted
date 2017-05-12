package TestApp;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;
use Catalyst;

our $VERSION = '0.0.2';

# hide debug output at startup
{
    no strict 'refs';
    no warnings;
    *{"Catalyst\::Log\::debug"} = sub { };
    *{"Catalyst\::Log\::info"}  = sub { };
}

TestApp->config(
    name => 'TestApp',

    'Plugin::Authentication' => {
        default => {
            credential => {
                class => 'Password',
                password_field => 'password',
                password_type => 'clear'
            },
            store => {
                class => 'Minimal',
                users => {
                    buffy => {
                        password => 'stake',
                    }
                }
            }
        }
    }
);

VERSION_MADNESS: {
    use version;
    my $vstring = version->new($VERSION)->normal;
    __PACKAGE__->config(
        version => $vstring
    );
}

TestApp->setup(
    qw<
        -Debug
        StackTrace
        ErrorCatcher
        ConfigLoader
        Authentication
    >
);

1;

