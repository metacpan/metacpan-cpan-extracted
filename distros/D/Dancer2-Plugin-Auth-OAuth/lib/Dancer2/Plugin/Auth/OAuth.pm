package Dancer2::Plugin::Auth::OAuth;

use strict;
use 5.008_005;
our $VERSION = '0.15';

use Dancer2::Plugin;
use Module::Load;

# setup the plugin
on_plugin_import {
    my $dsl      = shift;
    my $settings = plugin_setting;

    $settings->{prefix} ||= '/auth';

    for my $provider ( keys %{$settings->{providers} || {}} ) {

        # load the provider plugin
        my $provider_class = __PACKAGE__."::Provider::".$provider;
        eval { load $provider_class; 1; } or do {
            $dsl->app->log(debug => "Couldn't load $provider_class");
            next;
        };
        $dsl->app->{_oauth}{$provider} ||= $provider_class->new($settings);

        # add the routes
        $dsl->app->add_route(
            method => 'get',
            regexp => sprintf( "%s/%s", $settings->{prefix}, lc($provider) ),
            code   => sub {
                $dsl->app->redirect(
                    $dsl->app->{_oauth}{$provider}->authentication_url(
                        $dsl->app->request->uri_base
                    )
                )
            },
        );
        $dsl->app->add_route(
            method => 'get',
            regexp => sprintf( "%s/%s/callback", $settings->{prefix}, lc($provider) ),
            code   => sub {
                my $redirect;
                if( $dsl->app->{_oauth}{$provider}->callback($dsl->app->request, $dsl->app->session) ) {
                    $redirect = $settings->{success_url} || '/';
                } else {
                    $redirect = $settings->{error_url}   || '/';
                }

                $dsl->app->redirect( $redirect );
            },
        );
    }
};

register_plugin;

1;
__END__

=encoding utf-8

=head1 NAME

Dancer2::Plugin::Auth::OAuth - OAuth for your Dancer2 app

=head1 SYNOPSIS

  # just 'use' the plugin, that's all.
  use Dancer2::Plugin::Auth::OAuth;

=head1 DESCRIPTION

Dancer2::Plugin::Auth::OAuth is a Dancer2 plugin which tries to make OAuth
authentication easy.

The module is highly influenced by L<Plack::Middleware::OAuth> and Dancer 1
OAuth modules, but unlike the Dancer 1 versions, this plugin only needs
configuration (look mom, no code needed!). It automatically sets up the
needed routes (defaults to C</auth/$provider> and C</auth/$provider/callback>).
So if you define the Twitter provider in your config, you should automatically
get C</auth/twitter> and C</auth/twitter/callback>.

After a successful OAuth dance, the user info is stored in the session. What
you do with it afterwards is up to you.

=head1 CONFIGURATION

The plugin comes with support for Facebook, Google, Twitter, GitHub, Stack
Exchange and LinkedIn (other providers aren't hard to add, send me a pull
request when you add more!)

All it takes to use OAuth authentication for a given provider, is to add
the configuration for it.

The YAML below shows all available options.

  plugins:
    "Auth::OAuth":
      prefix: /auth [*]
      success_url: / [*]
      error_url: / [*]
      providers:
        Facebook:
          tokens:
            client_id: your_client_id
            client_secret: your_client_secret
          fields: id,email,name,gender,picture
        Google:
          tokens:
            client_id: your_client_id
            client_secret: your_client_secret
        Twitter:
          tokens:
            consumer_key: your_consumer_token
            consumer_secret: your_consumer_secret
        Github:
          tokens:
            client_id: your_client_id
            client_secret: your_client_secret
        Stackexchange:
          tokens:
            client_id: your_client_id
            client_secret: your_client_secret
            key: your_key
          site: stackoverflow
        Linkedin:
          tokens:
            client_id: your_client_id
            client_secret: your_client_secret
          fields: id,num-connections,picture-url,email-address
        VKontakte: # https://vk.com
          tokens:
            client_id: '...'
            client_secret: '...'
          fields: 'first_name,last_name,about,bdate,city,country,photo_max_orig,sex,site'
          api_version: '5.8'
        Odnoklassniki: # https://ok.ru
          tokens:
            client_id: your_client_id
            client_secret: your_client_secret
            application_key: your_application_key
          method: 'users.getCurrentUser'
          format: 'json'
          fields: 'email,name,gender,birthday,location,uid,pic_full'
        MailRU:
          tokens:
            client_id: your_client_id
            client_private: your_client_private
            client_secret: your_client_secret
          method: 'users.getInfo'
          format: 'json'
          secure: 1
        Yandex:
          tokens:
            client_id: your_client_id
            client_secret: your_client_secret
          format: 'json'

[*] default value, may be omitted.

=head1 AUTHOR

Menno Blom E<lt>blom@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014- Menno Blom

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
