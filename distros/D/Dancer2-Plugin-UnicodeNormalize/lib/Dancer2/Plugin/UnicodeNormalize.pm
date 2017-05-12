use strict;
use warnings;

package Dancer2::Plugin::UnicodeNormalize;
{
    $Dancer2::Plugin::UnicodeNormalize::VERSION = '0.04';
}

use Dancer2::Plugin 0.202000;
use Unicode::Normalize;

on_plugin_import {
    my $dsl = shift;

    # pre Plugin2 we need to get settings here
    my $settings = plugin_setting;
    $dsl->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub {
                my $app = shift;
                # perhaps better ways to check for Plugin2 but this works
                if ( $dsl->can('execute_plugin_hook')) {
                    # Plugin2  - fetch fresh config on each run
                    $settings = plugin_setting;
                }
                for (@{$settings->{'exclude'}}) { return if $app->request->path =~ /$_/ }

                my $form = $settings->{'form'} || 'NFC';
                my $normalizer = Unicode::Normalize->can($form);

                unless ($normalizer) {
                    require Carp;
                    Carp::croak( "Invalid normalization form '$form' requested" );
                }

                for (qw/query body route/) {
                    my $p = $app->request->params($_);
                    next unless $p;
                    %{$p} = map { $_ => $normalizer->($p->{$_}) } grep { $p->{$_} } keys %{$p};
                }
                $app->request->_build_params;

                if ( $app->request->can("body_parameters") ) {
                    for (qw/query_parameters body_parameters route_parameters/) {
                        my $p = $app->request->$_;
                        for my $key ( $p->keys ) {
                            $p->set( $key, map { $_ ? $normalizer->($_) : $_} $p->get_all($key) );
                        }
                    }
                }
            },
        ),
    );
};

register_plugin for_versions => [2];

1;

__END__
=pod

=head1 NAME

Dancer2::Plugin::UnicodeNormalize - Normalize incoming Unicode parameters

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

    use Dancer2::Plugin::UnicodeNormalize;

=head1 DESCRIPTION

Dancer2::Plugin::UnicodeNormalize normalizes all incoming parameters to a given
normalization form. This is achieved with a before hook, which should run
silently before processing each route. By default, we use Unicode Normalization
Form C - this is usually what you want. Other forms can be selected, see:
L</"CONFIGURATION">.

This plugin was inspired by L<Mojolicious::Plugin::UnicodeNormalize>. For
information on why Unicode Normalization is important, please see:

L<http://www.perl.com/pub/2012/05/perlunicookbook-unicode-normalization.html>

L<http://www.modernperlbooks.com/mt/2013/11/mojolicious-unicode-normalization-plugin-released.html>

=head1 CONFIGURATION

    plugins:
        UnicodeNormalize:
            form: NFC
            exclude:
                - '^/(css|javascripts|images)'

The C<form> parameter is described in L<Unicode::Normalize>. Default is NFC.

The C<exclude> parameter consists of a list of regular expressions to match
routes we do not wish to process parameters for.

=head1 AUTHOR

John Barrett, <john@jbrt.org>

=head1 CONTRIBUTING

L<http://github.com/jbarrett/Dancer2-Plugin-UnicodeNormalize>

All comments and contributions welcome.

=head1 BUGS AND SUPPORT

Please direct all requests to L<http://github.com/jbarrett/Dancer2-Plugin-UnicodeNormalize/issues>
or email <john@jbrt.org>.

=head1 COPYRIGHT

Copyright 2013 John Barrett.

=head1 LICENSE

This application is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Dancer2>

L<Unicode::Normalize>

L<Mojolicious::Plugin::UnicodeNormalize>

=cut

