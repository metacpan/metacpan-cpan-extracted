package Dancer2::Plugin::Sixpack;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Dancer2::Plugin;
use WWW::Sixpack;

our $VERSION = '0.03';

my $conf;

=head1 NAME

Dancer2::Plugin::Sixpack - Dancer2's plugin for WWW::Sixpack

=head1 DESCRIPTION

This plugin gives you the ability to do A/B testing within Dancer2 easily,
using L<http://sixpack.seatgeek.com/>.

It handles the client_id transparantly through Dancer2's Session plugin.

=head1 SYNOPSIS

    use Dancer2;
    use Dancer2::Plugin::Sixpack;

    get '/route' => sub {
        my $variant = experiment 'decimal_dot_comma', [ 'comma', 'dot' ];

        $price =~ s/\.(?=[0-9]{2})$/,/
           if( $variant eq 'comma' );
        # ...
    };

    get '/some_click' => sub {
        convert 'decimal_dot_comma', 'click';
        redirect $somewhere;
    };

    get '/confirmation' => sub {
        convert 'decimal_dot_comma';
        # ...
    };


=head1 CONFIGURATION

There are no mandatory settings.

    plugins:
      Sixpack:
        host: http://localhost:5000
        experiments:
          decimal_dot_comma:
            - comma
            - dot
          beer:
            - duvel
            - budweiser

The experiments can be generated on the fly without defining them. See below
for more information.

=head1 KEYWORDS

=head2 experiment

Fetch the alternative used for the experiment name passed in.

The experiment and its' alternatives may be defined in the configuration. If
they're not defined, the experiment will be created (if you provided the
alternatives arrayref).

Examples:

    # experiment defined in config:
    my $variant = exeriment 'known-experiment';

    # experiment not defined
    my $variant = experiment 'on-the-fly', [ 'alt-1', 'alt-2' ];

The client_id will be fetched from session, or generated if needed.

The client's IP address and user agent string are automatically
added to the request for bot detection.

Alternatives can be forced by params like "sixpack-force-$experiment=$alt"

Returns the alternative name chosen.

=cut

register experiment => sub {
    my ($dsl, $name, $alternatives) = @_;

    my $sixpack = $dsl->get_sixpack();

    # stored alternatives?
    if( !$alternatives && defined $conf->{experiments}{$name} ) {
        $alternatives = $conf->{experiments}{$name};
    }

    # user info
    my %options = ();
       $options{ip_address} = $dsl->app->request->address
           if $dsl->app->request->address;
       $options{user_agent} = $dsl->app->request->agent
           if $dsl->app->request->agent;

    # force if requested
    $options{force} = $dsl->app->request->param("sixpack-force-$name")
        if $dsl->app->request->param("sixpack-force-$name");

    my $alt = $sixpack
        ->participate( $name, $alternatives, \%options );

    my $experiments = $dsl->app->session->read('sixpack_experiments') || { };
       $experiments->{$name} = $alt->{alternative}{name};

    $dsl->app->session->write('sixpack_id', $alt->{client_id});
    $dsl->app->session->write('sixpack_experiments', $experiments);

    return $alt->{alternative}{name};
};

=head2 convert

Convert a user.

Provide the experiment and (optional) a KPI to track conversion on.
If the KPI doesn't exist yet, it will be created.

When no experiment name is given, we try to fetch the experiments
from the user's session and convert on all of the found experiments.

Returns a hashref with { 'experiment' => 'status' }

=cut

register convert => sub {
    my ($dsl, $experiment, $kpi) = @_;

    my %return;
    my $sixpack = $dsl->get_sixpack();

    if( $experiment ) {
        # specific experiment given
        my $res = $sixpack->convert($experiment, $kpi);
        $return{$experiment} = $res->{status};
    } else {
        # no experiments given, look them up
        my $experiments = $dsl->app->session->read('sixpack_experiments') || { };
        for my $exp (keys %{$experiments}) {
            my $res = $sixpack->convert($exp);
            $return{$exp} = $res->{status};
        }
    }

    return \%return;
};

=head2 get_sixpack

Internal method to construct the L<WWW::Sixpack> object.

=cut

sub get_sixpack {
    my $dsl = shift;

    $conf ||= plugin_setting();

    my %options;
    my $client_id = $dsl->app->session->read('sixpack_id');

    # need to pass info on to the sixpack object?
    $options{host}      = $conf->{host} if( defined $conf->{host} );
    $options{client_id} = $client_id    if( defined $client_id    );
    $options{ua}        = $conf->{ua}   if( defined $conf->{ua}   );

    return WWW::Sixpack->new(%options);
}

=head1 AUTHOR

Menno Blom, C<< <blom at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer2-plugin-sixpack at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer2-Plugin-Sixpack>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2014- Menno Blom

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

register_plugin for_versions => [ 2 ] ;

1; # End of Dancer2::Plugin::Sixpack
