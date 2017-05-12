package App::FonBot::Plugin::Common;

our $VERSION = '0.001';

use v5.14;
use strict;
use warnings;

use parent qw/Exporter/;

use JSON qw/encode_json/;
use Log::Log4perl qw//;

use DB_File qw//;
use Storable qw/freeze thaw/;

use App::FonBot::Plugin::Config qw/$dir $user $group @supplementary_groups/;

##################################################

our (%ok_user_addresses, %commands, %waiting_requests);
our @EXPORT = qw/%ok_user_addresses %commands %waiting_requests sendmsg/;

my $log=Log::Log4perl->get_logger(__PACKAGE__);

sub init{
	$log->info('setting user and group');
	$)=join ' ', scalar getgrnam $group, map {scalar getgrnam $_} @supplementary_groups;
	$(=scalar getgrnam $group;
	$<=$>=scalar getpwnam $user;
	chdir $dir;

	$log->info('initializing '.__PACKAGE__);
	tie %ok_user_addresses, DB_File => 'ok_user_addresses.db';
	tie %commands, DB_File => 'commands.db';
}

sub fini{
	$log->info('finishing '.__PACKAGE__);
	untie %ok_user_addresses;
	untie %commands;
}

##################################################

sub sendmsg{
	my ($touser,$requestid,$replyto,$command,@args)=@_;

	my $data={command=>$command, replyto=>$replyto, args => \@args };
	$data->{requestid} = $requestid if defined $requestid;

	if (exists $commands{$touser}) {
		my $temp = thaw $commands{$touser};
		push @$temp, $data;
		$commands{$touser} = freeze $temp
	} else {
		$commands{$touser} = freeze [$data]
	}

	if (exists $waiting_requests{$touser}) {
		$waiting_requests{$touser}->continue;
		delete $waiting_requests{$touser}
	}
}

1;
__END__

=encoding utf-8

=head1 NAME

App::FonBot::Plugin::Common - FonBot plugin that provides global variables and functions

=head1 SYNOPSIS

	use App::FonBot::Plugin::Common;
	App::FonBot::Plugin::Common->init;

	$ok_user_addresses{'marius OFTC mgvx'}=1; # Let user marius send messages to mgvx via the OFTC plugin
	sendmsg 'marius', 'OFTC mgvx', 'echo', 'Hello', 'world!';

	App::FonBot::Plugin::Common->fini;

=head1 DESCRIPTION

This FonBot plugin provides global variables and functions to the other plugins. It also sets the user and group according to the configuration file. It is a required plugin, since most other plugins depend on it.

=head1 CONFIGURATION VARIABLES

These are the L<App::FonBot::Plugin::Config> configuration variables used in this module

=over

=item C<$dir>

Directory to chdir to.

=item C<$user>

User to change to.

=item C<$group>

Group to change to.

=item C<@supplementary_groups>

Supplementary groups list to set.

=back

=head1 EXPORTED SYMBOLS

=over

=item B<%ok_user_addresses>

Hash that records combinations of username, driver and address that have sent commands to us. The key format is C<"$username $drivername $address">. B<fonbotd> will never send a message to an address which is not found in this hash.

Example entry: C<$ok_user_address{"nobody EMAIL nobody@mailinator.com"}>.

=item B<%commands>

Hash from usernames to a C<Storable::freeze>d array of pending commands for the user.

=item B<%waiting_requests>

Hash from usernames to a waiting HTTP::Response, as defined by the POE::Component::Server::HTTP documentation.

=item B<sendmsg>(I<$touser>, I<$requestid>, I<$replyto>, I<$command>, I<@args>)

Sends a command to C<$touser>'s phone. The command includes a command name (C<$command>), a list of arguments (C<@args>) and a reply address (C<$replyto>). If I<$requestid> is defined, the command will also include that request ID.

=back

=head1 METHODS

=over

=item C<App::FonBot::Plugin::Common-E<gt>init>

Sets the user and group according to the configuration variables and reads the exported variables from the disk.

=item C<App::FonBot::Plugin::Common-E<gt>fini>

Writes the exported variables to the disk.

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
