use strict;
use warnings;

use Test::More;

BEGIN {
    $ENV{DANCER_ENVDIR}              = 't/environments';
    $ENV{DANCER_ENVIRONMENT}         = 'provider-imap-with-roles';
    $ENV{D2PAE_TEST_NO_ROLES}        = 1;
    $ENV{D2PAE_TEST_NO_USER_DETAILS} = 1;

    {
        package Provider::IMAP::WithRoles;
        use Carp qw/croak/;
        use Dancer2::Core::Types qw/ArrayRef/;
        use Moo;
        extends 'Dancer2::Plugin::Auth::Extensible::Provider::IMAP';
        use namespace::clean;

        has users => (
            is      => 'ro',
            isa     => ArrayRef,
            default => sub { [] },
        );

        sub get_user_roles {
            my ( $self, $username ) = @_;
            croak "username must be defined"
              unless defined $username;
            my ($user) = grep { $username eq $_->{user} } @{$self->users};

            return $user ? $user->{roles} : undef;
        }
    }


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
