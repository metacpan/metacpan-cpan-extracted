package CatalystX::OAuth2::Provider;
use Moose::Role;
use CatalystX::InjectComponent;
use namespace::autoclean;

our $VERSION = '0.0005';

after 'setup_components' => sub {
    my $class = shift;
    CatalystX::InjectComponent->inject(
        into      => $class,
        component => 'CatalystX::OAuth2::Provider::Controller::OAuth',
        as        => 'Controller::OAuth',
    );

};

=head1 NAME

CatalystX::OAuth2::Provider -

=head1 VERSION
    Version 0.0005

=head1 SYNOPSIS

    package MyApp;
    use Moose;
    use namespace::autoclean;

    use Catalyst qw/
        +CatalystX::OAuth2::Provider
        Authentication
        Session
        Session::Store::File
        Session::State::Cookie
        Session::State::URI
        Session::State::Auth
    /;

    extends 'Catalyst';

    __PACKAGE__->config(
        'Plugin::Authentication' => { # Auth config here }
    );

    __PACKAGE__->config(
       'Plugin::Session' => { param => 'code', rewrite_body => 0 }, #Handle authorization code
    );

    __PACKAGE__->config(
        'Controller::OAuth' => {
            login_form => {
               template => 'user/login.tt',
               field_names => {
                   username => 'mail',
                   password => 'userPassword'
               }
            },
            authorize_form => {
                template => 'oauth/authorize.tt',
            },
            auth_info => {
                client_1 => {
                    client_id      => q{THIS_IS_ID},
                    client_secret  => q{THIS_IS_SECRET},
                    redirect_uri   => q{CLIENT_REDIRECT_URI},
                },
            },
            protected_resource => {
               secret_key => 'secret',
            }
        }
    );


=head1 DESCRIPTION

CatalystX::OAuth2::Provider is an application class provides a OAuth2 Provider in only
your Catalyst application configuration.

=head1 REQUIREMENTS

=over

=item A Catalyst application

=item A working Authentication configuration

=item A working Session configuration

=item A View

=back

=head1 METHODS

=head1 BUGS

=head1 AUTHOR

zdk (Warachet Samtalee)

=head1 COPYRIGHT & LICENSE

Copyright 2011 the above author(s).

This sofware is free software, and is licensed under the same terms as perl itself.

=cut

1;
