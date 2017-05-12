package TestApp;

use strict;
use warnings;

use Catalyst::Runtime '5.70';

use Catalyst qw(
                -Debug
                ConfigLoader
                Authentication
                Session
                Session::Store::FastMmap
                Session::State::Cookie
                );

our $VERSION = '0.00001';

__PACKAGE__->config
    ( name => "TestApp",
      session => {
          storage => "/tmp/" . __PACKAGE__ . "-" . $VERSION,
      },
      startup_time => time(),
      "Plugin::Authentication" => {
          default_realm => "members",
          realms => {
              members => {
                  credential => {
                      class => "Password",
                      password_field => "password",
                      password_type => "clear"
                      },
                          store => {
                              class => "Minimal",
                              users => {
                                  paco => {
                                      password => "l4s4v3n7ur45",
                                  },
                              }
                          }
              },
              openid => {
                  credential => {
                      class => "OpenID",
#DOES NOTHING                      use_session => 1,
                      store => {
                          class => "OpenID",
                      },
                      errors_are_fatal => 1,
                      # ua_class => "LWPx::ParanoidAgent",
                      ua_class => "LWP::UserAgent",
                      ua_args => {
                          whitelisted_hosts => [qw/ 127.0.0.1 localhost /],
                          timeout => 10,
                      },
                      extensions => [
                          'http://openid.net/extensions/sreg/1.1',
                          {
                           required => 'email',
                           optional => 'fullname,nickname,timezone',
                          },
                      ],
                      debug => 1,
                  },
              },
          },
      },
      );

__PACKAGE__->setup();

1;

__END__
