use strict;
use warnings;
package Dancer2::Plugin::RootURIFor;
{
    $Dancer2::Plugin::RootURIFor::VERSION = '0.03';
}
# ABSTRACT: Mountpoint-agnostic uri builder for Dancer2

use URI::Escape;
use Dancer2::Plugin 0.15;

register root_uri_for => sub {
    my ( $dsl, $part, $params, $dont_escape ) = @_;
    my $uri = $dsl->app->request->base;

    $part =~ s{^/*}{/};
    $uri->path("$part");

    $uri->query_form($params) if $params;

    return $dont_escape
      ? uri_unescape( ${ $uri->canonical } )
      : ${ $uri->canonical };
};

register_plugin;

1;

__END__
=pod

=head1 NAME

Dancer2::Plugin::RootURIFor - Mountpoint-agnostic uri builder for Dancer2

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

In your PSGI runner, you have multiple apps:

    builder {
        mount '/app1' => App1->to_app;
        mount '/app2' => App2->to_app;
    }

In your app, you would like to redirect or link between them:

    package App1;

    use Dancer2;
    use Dancer2::Plugin::RootURIFor;

    get '/redir' => sub {
        redirect root_uri_for('/app2');
    };

=head1 DESCRIPTION

Dancer2::Plugin::RootURIFor provides a way to link to resources on your service
which reside outside your application's mount point. This is useful as we can
retain URI scheme, server name, port etc. without resorting to querying request
parameters.

It should act exactly like uri_for, except it simply ignores the application's
base uri.

=head1 FUNCTIONS

=head2 root_uri_for

Returns a URI with the server's root URI as its base.

    root_uri_for '/hello';
    # Returns something like 'https://yourservice/hello'

You can also pass a hashref to generate URI parameters:

    root_uri_for '/hello', { looking_for => 'me' };
    # Returns something like 'https://yourservice/hello?looking_for=me'

=head1 AUTHOR

John Barrett, <john@jbrt.org>

=head1 CONTRIBUTING

L<http://github.com/jbarrett/Dancer2-Plugin-RootURIFor>


=head1 BUGS AND SUPPORT

Please direct all requests to L<http://github.com/jbarrett/Dancer2-Plugin-RootURIFor/issues>
or email <john@jbrt.org>.

=head1 COPYRIGHT

Copyright 2015 John Barrett.

=head1 LICENSE

This application is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

Thanks to Sawyer X for sanity check and feedback.

=head1 SEE ALSO

L<Dancer2>

L<Dancer2::Manual/"uri_for">

=cut
