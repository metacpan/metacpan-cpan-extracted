package Bracket;
use Moose;

our $VERSION = '1.16';
use Catalyst::Runtime '5.80';

use Catalyst qw/
  ConfigLoader
  Static::Simple
  Authentication
  Session
  Session::Store::DBIC
  Session::State::Cookie
  /;
extends 'Catalyst';

__PACKAGE__->config(
    authentication => {
        default_realm => 'members',
        realms        => {
            members => {
                credential => {
                    class          => 'Password',
                    password_field => 'password',
                    password_type  => 'self_check',
                },
                store => {
                    class                     => 'DBIx::Class',
                    user_model                => 'DBIC::Player',
                    role_relation             => 'roles',
                    role_field                => 'role',
                    use_userdata_from_session => 1,
                },
            },
        }
    }
);

# Session::Store
__PACKAGE__->config(
    'Plugin::Session' => {
        dbic_class     => 'DBIC::Session',
        expires        => 604800,
        cookie_expires => 1814400,
    },
);

# Start the application
__PACKAGE__->setup;

=head1 NAME

Bracket - College Basketball Tournament Bracket Web Application

=head1 SYNOPSIS

    Run your own bracket software.  Simple, effective and ad free.

=head1 DESCRIPTION

College Basketball Tournament Bracket Web application using the Catalyst framework.
Deploy an instance of this bracket software to run your own bracket system.
It requires a data store such as MySQL, PostgreSQL or SQLite.

Simple admin interface to build the perfect bracket as the tournament unfolds.
Player brackets are compared to the perfect bracket for scoring purposes.

=head1 AUTHOR

Mateu X. Hunter 2008-2022
hunter@missoula.org

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 COPYRIGHT

Mateu X. Hunter 2008-2022

=head1 LIMITATIONS

* Currently only supports one group of players.
* If you want to give more scoring weight to lower seeded wins
  you have to edit the lower_seed column of the game table.

=cut

1;
