use strict;
use warnings;

use Test::More;

BEGIN {
    $ENV{DANCER_ENVDIR}              = 't/environments';
    $ENV{DANCER_ENVIRONMENT}         = 'provider-imap';
    $ENV{D2PAE_TEST_NO_ROLES}        = 1;
    $ENV{D2PAE_TEST_NO_USER_DETAILS} = 1;

    {

        package Net::IMAP::Simple;
        use Moo;
        use namespace::clean;

        sub BUILDARGS {
            my $class = shift;
            return +{ realm => shift };
        }

        my $users = {
            config1 => {
                dave => 'beer',
                bob  => 'cider',
                mark => 'wantscider',
            },
            config2 => {
                burt           => 'bacharach',
                hashedpassword => 'password',
                mark           => 'wantscider',
            },
            config3 => {
                bananarepublic => 'whatever',
            },
        };

        has realm => (
            is       => 'ro',
            required => 1,
        );
        has return => (
            is      => 'rw',
            default => 1,
        );

        our $errstr;

        sub login {
            my ( $self, $user, $given ) = @_;
            if ( my $password = $users->{ $self->realm }->{$user} ) {
                if ( $password eq $given ) {
                    return 1;
                }
                else {
                    $errstr = "bad password for user \"$user\"";
                }
            }
            $errstr = "no such user \"$user\"";
            return 0;
        }
        sub logout { return }
    }
}

use Dancer2::Plugin::Auth::Extensible::Test;
{

    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::Auth::Extensible::Test::App;
}

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

Dancer2::Plugin::Auth::Extensible::Test::runtests($app);

done_testing;
