package App::FonBot::Plugin::Config;

our $VERSION = '0.001';

use v5.14;
use strict;
use warnings;

use parent qw/Exporter/;

use Apache2::Authen::Passphrase;
use Log::Log4perl qw//;

our @EXPORT_OK=qw/$oftc_enabled $oftc_nick @oftc_channels $oftc_nickserv_password $bitlbee_enabled $bitlbee_nick $bitlbee_server $bitlbee_port $bitlbee_password $dir $user $group @supplementary_groups $httpd_port $email_batch_seconds $email_from $email_subject/;

##################################################

our ($oftc_enabled, $oftc_nick, @oftc_channels, $oftc_nickserv_password);
our ($bitlbee_enabled, $bitlbee_nick, $bitlbee_server, $bitlbee_port, $bitlbee_password);
our ($dir, $user, $group, @supplementary_groups);
our ($httpd_port);
our ($email_batch_seconds, $email_from, $email_subject);

##################################################

my $log=Log::Log4perl->get_logger(__PACKAGE__);

sub init{
	$log->info('reading config file');
	unless (my $ret = do '/etc/fonbotd/config.pl') {
		die "Cannot parse config file: $@" if $@;
		die "Cannot run config file: $!" unless $ret;
	}
}

sub fini{
	#no-op
}

1;

__END__

=encoding utf-8

=head1 NAME

App::FonBot::Plugin::Config - FonBot plugin for reading configuration files

=head1 SYNOPSIS

  use App::FonBot::Plugin::Config qw/$oftc_enabled $oftc_nick @oftc_channels $oftc_nickserv_password $bitlbee_enabled $bitlbee_nick $bitlbee_server $bitlbee_port $bitlbee_password $user $group @supplementary_groups $httpd_port/;
  App::FonBot::Plugin::Config->init;

  # Variables used in App::FonBot:Plugin::OFTC
  say "The OFTC plugin is ".($oftc_enabled ? 'enabled' : 'disabled');
  say "The OFTC NickServ password is $oftc_nickserv_password";
  say "The OFTC nickname is $oftc_nick";
  say "The OFTC channels are @oftc_channels";

  # Variables used in App::FonBot::Plugin::BitlBee
  say "The BitlBee plugin is ".($bitlbee_enabled ? 'enabled' : 'disabled');
  say "The BitlBee server runs on port $bitlbee_port of host $bitlbee_server"
  say "The BitlBee nickname is $bitlbee_nick";
  say "The BitlBee password is $bitlbee_password";

  # Variables used in App::FonBot::Plugin::Common
  say "The storage directory is $dir";
  say "The user is $user";
  say "The primary group is $group";
  say "The supplementary groups are @supplementary_groups";

  # Variables used in App::FonBot::Plugin::HTTPD
  say "The HTTPD listens on port $httpd_port"

  # Variables used in App::FonBot::Plugin::Email
  say "The email batch delay is $email_batch_seconds";
  say "The email plugin sends emails from $email_from";
  say "The email plugin sends emails with subject $email_subject";

=head1 DESCRIPTION

This FonBot plugin reads a configuration file (hardcoded to F</etc/fonbot/config.pl>) and provides configuration variables to the other plugins. It is a required plugin, since all other plugins depend on it.

The configuration variables are described in detail in the plugins that use it.

=head1 METHODS

=over

=item C<App::FonBot::Plugin::Config-E<gt>init>

(Re-)reads the configuration file, populating the configuration variables. The configuration file is a regular perl script, hardcoded to F</etc/fonbot/config.pl>.

=item C<App::FonBot::Plugin::Config-E<gt>fini>

Currently a no-op. It is recommended to call this after finishing using this module, since it might do something in a future release.

=back

=head1 AUTHOR

Marius Gavrilescu C<< <marius@ieval.ro> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2015 Marius Gavrilescu

This file is part of fonbotd.

fonbotd is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

fonbotd is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with fonbotd.  If not, see <http://www.gnu.org/licenses/>


=cut
