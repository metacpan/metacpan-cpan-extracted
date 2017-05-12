package App::FonBot::Daemon;

our $VERSION = '0.001';

use 5.014000;
use strict;
use warnings;

use Log::Log4perl qw//;
use POE;

use App::FonBot::Plugin::Config;
use App::FonBot::Plugin::Common;
use App::FonBot::Plugin::OFTC;
use App::FonBot::Plugin::BitlBee;
use App::FonBot::Plugin::HTTPD;
use App::FonBot::Plugin::Email;

use sigtrap qw/die normal-signals/;

use constant PLUGINS => map { "App::FonBot::Plugin::$_" } qw/Config Common OFTC BitlBee HTTPD Email/;

##################################################

sub run{
	Log::Log4perl->init('/etc/fonbotd/log4perl.conf');
	chdir '/var/lib/fonbot';
	$_->init for PLUGINS;
	POE::Kernel->run;
}

sub finish{
	$_->fini for reverse PLUGINS
}

1;

__END__

=head1 NAME

App::FonBot::Daemon - FonBot daemon

=head1 SYNOPSIS

    use App::FonBot::Daemon;
    App::FonBot::Daemon::run;
    END { App::FonBot::Daemon::finish }

=head1 DESCRIPTION

This module is the entry point of the FonBot Daemon

=head1 FUNCTIONS

=over

=item B<run>

Runs the FonBot daemon

=item B<finish>

Runs the plugin finalizers

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
