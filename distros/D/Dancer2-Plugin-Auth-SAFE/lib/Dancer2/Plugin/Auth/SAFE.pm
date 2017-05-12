package Dancer2::Plugin::Auth::SAFE;

use strict;
use warnings;

our $VERSION = '0.002';

use Dancer2::Plugin;
use Dancer2::Core::Types qw( Str );
use Digest::MD5 qw( md5_hex );
use HTTP::Status qw( :constants );
use DateTime;
use Const::Fast;
use namespace::autoclean;

const my $MAX_TIMESTAMP_DEVIANCE => 5;

has safe_url => (
    is          => 'ro',
    isa         => Str,
    from_config => 1,
);

has shared_secret => (
    is          => 'ro',
    isa         => Str,
    from_config => 1,
);

plugin_keywords qw( require_login logged_in_user );

sub BUILD {
    my ($plugin) = @_;

    return $plugin->app->add_route(
        method => 'post',
        regexp => '/safe',
        code   => _authenticate_user($plugin),
    );
}

sub require_login {
    my ( $plugin, $coderef ) = @_;

    return sub {
        my $session   = $plugin->app->session;
        my $user_info = $session->read('user_info');

        if ($user_info) {
            return $coderef->( $plugin->app );
        }
        else {
            _store_original_route( $session, $plugin->app->request );
            return $plugin->app->redirect( $plugin->safe_url );
        }
      }
}

sub logged_in_user {
    my ( $plugin, $coderef ) = @_;

    my $user_info = $plugin->app->session->read('user_info');

    return $user_info;
}

sub _authenticate_user {
    my ($plugin) = @_;

    return sub {
        my ($self) = @_;

        my $params = $self->app->request->params;

        my ( $uid, $timestamp, $digest ) = @{$params}{qw( uid time digest )};

        if (
               defined $uid
            && defined $timestamp
            && defined $digest

            && $digest eq md5_hex( $uid . $timestamp . $plugin->shared_secret )
            && _timestamp_deviance($timestamp) < $MAX_TIMESTAMP_DEVIANCE
          )
        {
            my $user_info = {
                map { $_ => $params->{$_} }
                  grep { defined $params->{$_} }
                  qw( uid firstname lastname company costcenter
                  email marketgroup paygroup thomslocation )
            };

            my $session = $self->app->session;

            $session->write( user_info => $user_info );

            $self->app->forward( _extract_original_route($session) );
        }

        return $self->app->send_error( 'Authentication error',
            HTTP_UNAUTHORIZED );
      }
}

sub _timestamp_deviance {
    my ($timestamp) = @_;

    my %date_time;
    @date_time{qw( year month day hour minute second )} =
      split /:/xms, $timestamp;

    my $current_time = DateTime->now;
    my $digest_time  = DateTime->new(%date_time);

    return $current_time->delta_ms($digest_time)->{minutes};
}

sub _store_original_route {
    my ( $session, $request ) = @_;

    $session->write( '__auth_safe_path'   => $request->path );
    $session->write( '__auth_safe_method' => lc $request->method );
    $session->write( '__auth_safe_params' => \%{ $request->params } );

    return;
}

sub _extract_original_route {
    my ($session) = @_;

    my @route = (
        $session->read('__auth_safe_path'),
        $session->read('__auth_safe_params'),
        { method => $session->read('__auth_safe_method') },
    );

    for (qw( __auth_safe_path __auth_safe_params __auth_safe_method )) {
        $session->delete($_);
    }

    return @route;
}

1;

__END__

=head1 NAME

Dancer2::Plugin::Auth::SAFE - Thomson Reuters SAFE SSO authentication plugin for Dancer2

=head1 VERSION

version 0.002

=head1 DESCRIPTION

With this plugin you can easily integrate Thomson Reuters SAFE SSO authentication
into your application.

=head1 SYNOPSIS

Add plugin configuration into your F<config.yml>

  plugins:
      Auth::SAFE:
          safe_url: "https://safe-test.thomson.com/login/sso/SSOService?app=app"
          shared_secret: "fklsjf5GlkKJ!gs/skf"

Define that a user must be logged in to access a route - and find out who is
logged in with the C<logged_in_user> keyword:

    use Dancer2::Plugin::Auth::SAFE;

    get '/users' => require_login sub {
        my $user = logged_in_user;
        return "Hi there, $user->{firstname}";
    };

=head1 ATTRIBUTES

=head2 safe_url

=head2 shared_secret

=head1 SUBROUTINES/METHODS

=head2 require_login

Used to wrap a route which requires a user to be logged in order to access
it.

    get '/profile' => require_login sub { .... };

=head2 logged_in_user

Returns a hashref of details of the currently logged-in user, if there is one.

=head1 AUTHOR

Konstantin Matyukhin E<lt>kmatyukhin@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016 by Konstantin Matyukhin

This is a free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
