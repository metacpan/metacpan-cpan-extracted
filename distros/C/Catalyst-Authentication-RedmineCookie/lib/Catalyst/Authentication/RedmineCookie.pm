package Catalyst::Authentication::RedmineCookie;

=encoding utf8

=head1 NAME

Catalyst::Authentication::RedmineCookie - Decode the redmine cookie _redmine_session

=head1 SYNOPSIS

    package TestApp;
    use base qw(Catalyst);
    __PACKAGE__->config(
        'Plugin::Authentication' => {
            default_realm => 'redmine_cookie',
            realms => {
                redmine_cookie => {
                    credential => {
                        class => 'RedmineCookie',
                        # examples
                        cmd   => [qw(ssh redmine.server rails4_cookie_to_json.rb)],
                        cmd   => [qw(sudo jexec redmine rails4_cookie_to_json.rb)],
                    },
                    # It does not specify a store, it works with NullStore.
                    store => {
                        class => 'DBIx::Class',
                        user_model => 'DBIC::Users',
                    }
                },
            },
        },
        # Not required for NullStore.
        'Model::DBIC' => {
            schema_class => "Catalyst::Authentication::RedmineCookie::Schema",
            compose_namespaces => 0,
            connect_info => [
                "DBI:mysql:database=redmine", 'user', 'pass',
                {
                    RaiseError        => 1,
                    PrintError        => 0,
                    AutoCommit        => 1,
                    pg_enable_utf8    => 1, # for pg
                    mysql_enable_utf8 => 1, # for mysql
                    quote_names       => 1,
                }
            ],
        },
    );
    __PACKAGE__->setup(
        'Authentication',
    );

    package TestApp::Controller::Root;
    use base qw(Catalyst::Controller);
    sub index :Path('/') {
        my ($self, $c) = @_;

        $c->authenticate;

        # If the store is Null
        if ($c->user) {
            ref $c->user;             # Catalyst::Authentication::User::Hash
            ref YAML::Syck::Dump($c->user);
            # --- !!perl/hash:Catalyst::Authentication::User::Hash
            # _redmine_cookie:
            #   _csrf_token: 7fwDk6DF6aCWepctbBGvawotX2tQBDSXZJ7CXcUtD7o=
            #   session_id: 422c2d4f6ad5ee804d54c73946d35802
            #   sudo_timestamp: '1578451011'
            #   tk: addd76728a211c7124e4f4bf90455ecfa6b039e6
            #   user_id: 1
            # auth_realm: redmine_cookie
            # id: 1
        }

        # If the store is DBIx::Class
        if ($c->user) {
            ref $c->user;             # Catalyst::Authentication::Store::DBIx::Class::User
            ref $c->user->get_object; # TestApp::Model::DBIC::Users
        }
    }

    1;

=head1 AUTHOR

Tomohiro Hosaka, E<lt>bokutin@bokut.inE<gt>

=head1 COPYRIGHT AND LICENSE

The Catalyst::Authentication::RedmineCookie module is

Copyright (C) 2020 by Tomohiro Hosaka

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
