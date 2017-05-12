package Dancer::Plugin::Cerberus;
{
  $Dancer::Plugin::Cerberus::VERSION = '0.03';
}

use strict;
use warnings;

use Dancer qw(:syntax);
use Dancer::Plugin;
use App::Cerberus::Client();

our %Loggers = (
    core     => \&Dancer::Logger::core,
    debug    => \&Dancer::Logger::debug,
    info     => \&Dancer::Logger::info,
    warnings => \&Dancer::Logger::warning,
    error    => \&Dancer::Logger::error
);

#===================================
hook 'before' => sub {
#===================================
    my $settings = plugin_setting;
    my $client = $settings->{'_client'} ||= _setup_client();

    my $request = request;
    my $ip      = $request->remote_address;
    my $info    = $client->request(
        ip => $ip,
        ua => $request->user_agent
    );

    var 'cerberus' => $info;
    return unless $info->{throttle};

    my $sleep = $info->{throttle}{sleep} or return;
    my $range = $info->{throttle}{range};

    my $enforce = $settings->{throttle}{enforce};
    if ( my $logger = $Loggers{ $settings->{throttle}{log_as} } ) {
        $logger->( ( $enforce ? "[Throttle]" : "[Throttle - Unenforced]" )
            . " Reason: $info->{throttle}{reason}, "
                . "Range: $range, "
                . "IP: $ip, "
                . "Sleep: $sleep" )

    }
    return unless $enforce;

    halt( Dancer::Error->new( code => 403, message => 'Forbidden' )->render )
        if $sleep < 0;
    halt( Dancer::Error->new( code => 503, message => 'Service unavailable' )
            ->render );
};

#===================================
hook 'after_error_render' => sub {
#===================================
    my $response = shift;
    if ( $response->status eq 503 ) {
        if ( my $sleep = vars->{cerberus}{throttle}{sleep} ) {
            $response->header( 'Retry-After' => $sleep );
        }
    }
};
#===================================
sub _setup_client {
#===================================
    my $settings = plugin_setting;
    my $client   = App::Cerberus::Client->new(
        servers => $settings->{servers},
        timeout => $settings->{timeout}
    );
}

register_plugin;

true;

# ABSTRACT: Include geo, time zone, user-agent and throttling from App::Cerberus


__END__
=pod

=head1 NAME

Dancer::Plugin::Cerberus - Include geo, time zone, user-agent and throttling from App::Cerberus

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Dancer::Plugin::Cerberus;

    get '/' => sub {
        my $time_zone = vars->{cerberus}{tz}{name};
    };

=head1 DESCRIPTION

This plugin adds metadata from an L<App::Cerberus> server to the
L<vars|Dancer/vars> before your route handlers are called.

For instance:

=over

=item *

Geo-location

=item *

Time zone

=item *

User-agent info

=item *

Are they a spider?

=item *

Are they making too many requests? Should we throttle them?

=back

It can also be configured to throttle or ban IP address ranges with
L<App::Cerberus::Plugin::Throttle>.

=head1 CONFIG

The basic configuration (C<servers> and C<timeout>) are passed to
L<App::Cerberus::Client/new()>.

    plugins:
        Cerberus:
            servers:        http://localhost:5001/

Or

    plugins:
        Cerberus:
            servers:
             -              http://host1:5001/
             -              http://host2:5001/
            timeout:        0.1

If you are using the L<App::Cerberus::Plugin::Throttle> plugin, then you can
also configure:

    plugins:
        Cerberus:
            servers:        http://localhost:5001/
            throttle:
                log_as:     info
                enforce:    0 | 1

If C<log_as> is one of C<core>, C<info>, C<warn>, C<debug> or C<error>, then
Throttle messages will be logged at that level.

If C<enforce> is true, then banned IP addresses will receive a C<403 Forbidden>
response and throttled users a C<503 Service Unavailable> response, with a
C<Retry-After: $seconds> header.

=head1 ACCESSING CERBERUS INFO

The C<vars> available in any route handler will contain a key C<cerberus>
with any data that L<App::Cerberus> has returned, for instance:

    get '/' => sub {
        my $geo_info   = vars->{cerberus}{geo};
        my $time_zone  = vars->{cerberus}{tz};
        my $user_agent = vars->{cerberus}{ua};
        my $throttle   = vars->{cerberus}{throttle};
    };

=head1 SEE ALSO

=over

=item *

L<App::Cerberus>

=item *

L<Plack::Middleware::Cerberus>

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Cerberus

You can also look for information at:

=over

=item * GitHub

L<http://github.com/clintongormley/Dancer-Plugin-Cerberus>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-Cerberus>

=item * Search MetaCPAN

L<https://metacpan.org/module/Dancer::Plugin::Cerberus>

=back

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

