use strict;
use warnings;

package Dancer2::Plugin::Auth::HTTP::Basic::DWIW;
# ABSTRACT: HTTP Basic authentication plugin for Dancer2 that does what I want.
$Dancer2::Plugin::Auth::HTTP::Basic::DWIW::VERSION = '0.05';
use MIME::Base64;
use Dancer2::Plugin;

our $CHECK_LOGIN_HANDLER = undef;

register http_basic_auth => sub {
    my ($dsl, $stuff, $sub, @other_stuff) = @_;

    my $realm = plugin_setting->{'realm'} // 'Please login';

    return sub {
        local $@ = undef;
        eval {
            my $header = $dsl->app->request->header('Authorization') || die \401;

            my ($auth_method, $auth_string) = split(' ', $header);

            $auth_method ne 'Basic' || $auth_string || die \400;

            my ($username, $password) = split(':', decode_base64($auth_string), 2);

            $username || $password || die \401;

            if (ref($CHECK_LOGIN_HANDLER) eq 'CODE') {
                my $check_result = eval { $CHECK_LOGIN_HANDLER->($username, $password); };

                if($@) {
                    die \500;
                }

                if(!$check_result) {
                    die \401;
                }
            }
        };

        unless ($@) {
            return $sub->($dsl, @other_stuff);
        }
        else {
            my $error_code = ${$@};

            $dsl->header('WWW-Authenticate' => 'Basic realm="' . $realm . '"');
            $dsl->status($error_code);
            return;
        }
    };
};

register http_basic_auth_login => sub {
    my ($dsl) = @_;
    my $app = $dsl->app;

    my @auth_header = split(' ', $dsl->app->request->header('Authorization'));
    my $auth_string = $auth_header[1];
    my @auth_parts  = split(':', decode_base64($auth_string), 2);

    return @auth_parts;
},
{
    is_global => 0
};

register http_basic_auth_set_check_handler => sub {
    my ($dsl, $handler) = @_;
    $CHECK_LOGIN_HANDLER = $handler;
};

register_plugin for_versions => [2];
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::Auth::HTTP::Basic::DWIW - HTTP Basic authentication plugin for Dancer2 that does what I want.

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    package test;

    use Dancer2;
    use Dancer2::Plugin::Auth::HTTP::Basic::DWIW;

    http_basic_auth_set_check_handler sub {
        my ( $user, $pass ) = @_;

        # you probably want to check the user in a better way
        return $user eq 'test' && $pass eq 'bla';
    };

    get '/' => http_basic_auth required => sub {
        my ( $user, $pass ) = http_basic_auth_login;

        return $user;
    };
    1;

=head1 DESCRIPTION

This plugin gives you the option to use HTTP Basic authentication with Dancer2.

You can set a handler to check the supplied credentials. If you don't set a handler, every username/password combination will work.

=head1 CAUTION

Don't ever use HTTP Basic authentication over clear-text connections! Always use HTTPS!

The only case were using HTTP is ok is while developing an application. Don't use HTTP because you think it is ok in corporate networks or something alike, you can always have bad bad people in your network..

=head1 CONFIGURATION

=over 4

=item realm

The realm presented by browsers in the login dialog.

Defaults to "Please login".

=back

=head1 OTHER

This is my first perl module published on CPAN. Please don't hurt me when it is bad and feel free to make suggestions or to fork it on GitHub.

=head1 BUGS

Please report any bugs or feature requests to C<littlefox at fsfe.org>, or through
the web interface at L<https://github.com/LittleFox94/Dancer2-Plugin-Auth-HTTP-Basic-DWIW/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

After installation you can find documentation for this module with the perldoc command:

    perldoc Dancer2::Plugin::Auth::HTTP::Basic::DWIW

=head1 AUTHOR

Moritz Grosch (LittleFox) <littlefox@fsfe.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Moritz Grosch (LittleFox).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
