package MyApp::Schema::ResultSet::User;
use namespace::autoclean;

use utf8;
use Moose;
extends 'DBIx::Class::ResultSet';
with 'MyApp::Role::Verification';
with 'MyApp::Role::Verification::TransactionalActions::DBIC';
with 'MyApp::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use MooseX::Types::Email qw/EmailAddress/;

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {

                name => {
                    required => 1,
                    type     => 'Str',
                },

                password => {
                    required => 1,
                    type     => 'Str',
                },

                role => {
                    required => 1,
                    type     => 'Str',
                },

                email => {
                    required   => 1,
                    type       => EmailAddress,
                    post_check => sub {
                        my $r = shift;
                        return 0 if ( $self->find( { email => $r->get_value('email') } ) );
                        return 1;
                      }
                },

            },
        ),

        login => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                email => {
                    required   => 1,
                    type       => EmailAddress,
                    post_check => sub {
                        my $r = shift;
                        return defined $self->find( { email => $r->get_value('email') } );
                      }
                },
                password => {
                    required => 1,
                    type     => 'Str',
                },
            }
        ),

    };
}

sub action_specs {
    my $self = shift;
    return {
        login => sub { 1 },

        create => sub {
            my %values = shift->valid_values;
            delete $values{password_confirm};

            my $role = delete $values{role};

            my $types = {
                'user' => 'user',
                'superadmin' => 'superadmin'
            };
            $values{type} = $role && exists $types->{$role} ? $types->{$role} : 'unknown';

            my $user = $self->create( \%values, active => 1 );
            if ($role) {
                $user->set_roles( { name => $role } );
            }

            return $user;
          }

    };
}

1;

