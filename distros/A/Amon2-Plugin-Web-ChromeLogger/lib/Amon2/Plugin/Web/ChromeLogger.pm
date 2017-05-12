package Amon2::Plugin::Web::ChromeLogger;
use strict;
use warnings;
use Web::ChromeLogger;

our $VERSION = '0.03';

sub init {
    my ($class, $c, $conf) = @_;

    return if $conf->{disabled};

    return if $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'production'
                    && !$conf->{enable_in_production};

    $c->add_trigger('BEFORE_DISPATCH' => sub {
        $_[0]->{chrome_logger} = Web::ChromeLogger->new(
            json_encoder => $conf->{json_encoder},
        );
    });

    $c->add_trigger('AFTER_DISPATCH' => sub {
        $_[1]->header('X-ChromeLogger-Data' => $_[0]->{chrome_logger}->finalize);
    });

    Amon2::Util::add_method(
        $c => 'chrome_logger',
        sub {
            $_[0]->{chrome_logger};
        },
    );

    Amon2::Util::add_method(
        $c => 'chrome',
        sub {
            $_[0]->{chrome_logger}->info($_[1]);
        },
    );
}

1;

__END__

=head1 NAME

Amon2::Plugin::Web::ChromeLogger - The Chrome Logger Plugin for Amon2


=head1 SYNOPSIS

in your app

    __PACKAGE__->load_plugins('Web::ChromeLogger');

then in a controller

    $c->chrome('aloha!');

or to access raw C<Web::ChromeLogger> instance.

    $c->chrome_logger->warn('mahalo!');


=head1 DESCRIPTION

Amon2::Plugin::Web::ChromeLogger is the Chrome Plugin for Amon2.

See L<Web::ChromeLogger>, L<http://craig.is/writing/chrome-logger> for detail

This plugin added below methods for context($c) in Amon2.

=head2 chrome($log_message)

To put info log to chrome console.

    $c->chrome('mahalo!');

=head2 chrome_logger

To get C<Web::ChromeLogger> instance.

    $c->chrome_logger->info('kai!');
    $c->chrome_logger->warn('nalu!');

NOTE that this plugin is disabled under PLACK_ENV:production environment by default.
If you want to enable this plugin under production environment, you should set TRUE value to the C<enable_in_production> option.


=head1 METHODS

=head2 init

initialized this plugin


=head1 PLUGIN OPTION

=head2 disabled

If you set TRUE value to this option, then the plugin will be disabled.

=head2 enable_in_production

To set TRUE value to this option, then the plugin will be enabled even if environment is under PLACK_ENV:production.
By default, this plugin is disabled under PLACK_ENV:production environment.

=head2 json_encoder

You can pass C<json_encoder> to L<WEB::ChromeLogger>.


=head1 REPOSITORY

Amon2::Plugin::Web::ChromeLogger is hosted on github
<http://github.com/bayashi/Amon2-Plugin-Web-ChromeLogger>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Amon2>, L<Web::ChromeLogger>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
