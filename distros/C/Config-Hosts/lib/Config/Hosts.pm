package Config::Hosts;

use warnings;
use strict;

use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Config::Hosts - Interface to /etc/hosts file

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.03';

our $DEFAULT_FILE = '/etc/hosts';

our $TYPE_IP   =  1;
our $TYPE_HOST = -1;

=head1 SYNOPSIS

Config::Hosts - Interface to /etc/hosts file. A tool that manages the
hosts list on a machine, is able to query/insert/delete/update the
entries by IP or by a hostname, and also maintains the original
comments and some sanity checks on IP and hostname values.

    use Config::Hosts;

    my $hosts = Config::Hosts->new();
	$hosts->read_hosts(); # reads default /etc/hosts
	$hosts->query_host($host_or_ip);
	$hosts->insert_host(ip => $ip, hosts => [qw(host1 host2)]);
	$hosts->update_host($ip, hosts=> [qw(host1 host3)]);
	$hosts->delete_host('host3');
	$hosts->write_hosts("/tmp/hosts");

=head1 EXPORT

The interface is entirely object-oriented. The following methods have
been defined:

=head1 SUBROUTINES/METHODS

=head2 new ($;%)

The constructor. Accepts optional hash with one key only: file - the
name of the file as alternative to default /etc/hosts.

Returns the newly blessed object.

=cut

sub new ($;@) {

	my $class = shift;
	my %params = @_;

	my $self = {};
	$self->{_file} = $params{file} || $DEFAULT_FILE;
	bless $self, $class;

	return $self;
}

=head2 is_valid_ip ($)

internal utility function to check whether the IP given is a valid
IPv4 or IPv6 address. Returns 1 or 0, naturally.

=cut

sub is_valid_ip ($) {

	my $ip = shift;
	if ($ip =~ /^$IPv6_re$/) {
		return 1;
	}
	return $ip =~
		/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ && ($1+0 | $2+0 | $3+0 | $4+0) < 0x100 ?
		1 : 0;
}

=head2 is_valid_host($)

Internal utility to determine whether the host name is a valid
hostname as required by /etc/hosts manual.

=cut

sub is_valid_host ($) {

	my $host = shift;
	return $host =~
		/^[a-z]([a-z]|[0-9]|\-|\.)*([a-z]|[0-9])$/i ?
		1 : 0;
}

=head2 read_hosts($;$)

Read the host file into a data structure to later be used by the other
methods. Optional argument may be the file to read hosts table from.

=cut

sub read_hosts ($;$) {

	my $self = shift;
	my $hosts_file = shift || $self->{_file};

	my $contents = [];
	open(H, $hosts_file) or die "Couldn't open hosts file $hosts_file: $!";
	my $i = 0; my $l = 0;
	my $hosts = {};
	while (<H>) {
		chomp;
		$l++;
		if (! /\S/) {
			$contents->[$i] = $_;
		}
		elsif (/^\s*\#/) {
			$contents->[$i] = $_;
		}
		elsif (
			/^\s*(\d+\.\d+\.\d+\.\d+)\s+(\S.*)/ ||
			/^\s*(\S*\:\S*\:\S*)\s+(\S.*)/
		) {
			$_ = lc $_;
			$contents->[$i] = $_;
			my $ip = $1;
			my ($hosts_list, $comment) = split(/\#/, $2);
			$comment ||= "";
			if (!is_valid_ip($ip)) {
				print STDERR "Line $l: Warning: IP $ip is invalid\n";
			} 
			my @hosts = split(/\s+/, $hosts_list);
			$contents->[$i] = $_;
			if ($hosts->{$ip}) {
				print STDERR "Line $l: Warning: duplicate IP entry $ip, the last one will be used\n";
			}
			$hosts->{$ip} = {
				hosts => [ @hosts ],
				comment => $comment,
				line => $i,
			};
			for my $host (@hosts) {
				if (! is_valid_host($host)) {
					print STDERR "Line $l: Warning: Host $host is invalid\n";
				}
				if ($hosts->{$host}) {
					print STDERR "Line $l: Warning: duplicate Host entry $host, the last one will be used\n";
				}
				$hosts->{$host} = {
					ip => $ip,
					comment => $comment,
					line => $i,
				}
			}
		}
		else {
			die "Invalid entry: $_\nBailing out.\n";
		}
		$i++;
	}
	$self->{_contents} = $contents;
	$self->{_hosts}    = $hosts;
}

=head2 determine_ip_or_host ($$)

Check whether the given argument is an IP, a HOST or neither. Returns
1, -1 or 0 correspondingly.

=cut

sub determine_ip_or_host ($$) {

	my $self      = shift;
	my $candidate = shift;

	return $TYPE_IP   if is_valid_ip($candidate);
	return $TYPE_HOST if is_valid_host($candidate);
	return  0;
}

=head2 query_host ($$)

Queries the read hosts table to find specified argument that may be IP
address or host name.

Returns hash containing the relevant entry if found or undef if not.

=cut

sub query_host ($$) {

	my $self = shift;
	my $host = shift;

	my $type = $self->determine_ip_or_host($host);
	if ($type) {
		return $self->{_hosts}{$host};
	}
	else {
		return undef;
	}
}

=head2 insert_host ($%)

Inserts a host. Both IP and hostnames must be specified as a hash.
Hostname may be a single scalar or arrayref of hostnames.

=cut

sub insert_host ($%) {

	my $self = shift;
	my %params = @_;

	if (! $params{ip} || ! $params{hosts}) {
		print STDERR "No ip or host supplied to insert_host, ignoring\n";
		return 0;
	}
	my $ip = $params{ip};
	if (! is_valid_ip($ip)) {
		print STDERR "Invalid IP $ip, ignoring\n";
		return 0;
	}
	my $hosts;
	if (! ref $params{hosts}) {
		$hosts = [ $params{hosts} ];
	}
	else {
		$hosts = $params{hosts};
	}
	if (ref $hosts ne 'ARRAY') {
		print STDERR "Host names must be scalar value or ARRAY ref, ignoring\n";
		return 0;
	}
	if (grep {
		!is_valid_host($_) &&
		print STDERR "Invalid host $_ passed, ignoring insert\n"
	} @{$hosts}) {
		return 0;
	}
	my $hosts_line = join(" ", @{$hosts});
	my $comment = $params{comment} ? " $params{comment}" : "";
	push(@{$self->{_contents}}, "$ip\t$hosts_line$comment");
	if ($self->{_hosts}{$ip}) {
		print STDERR "INSERT: Warning:duplicate IP $ip, the last one will be used\n";
		for my $h_host (@{$self->{_hosts}{$ip}{hosts}}) {
			delete $self->{_hosts}{$h_host}
		}
		my $index = $self->{_hosts}{$ip}{line};
		splice(@{$self->{_contents}}, $index, 1);
	}
	$self->{_hosts}{$ip} = {
		hosts => $hosts,
		comment => $comment,
		line => scalar @{$self->{_contents}},
	};
	for my $host (@{$hosts}) {
		if ($self->{_hosts}{$host}) {
			print STDERR "INSERT: Warning:duplicate Host entry $host, the last one will be used\n";
		}
		$self->{_hosts}{$host} = {
			ip => $ip,
			comment => $comment,
			line => scalar @{$self->{_contents}},
		}
	}
	return 1;
}

=head2 delete_host ($$)

Deletes an entry in hosts table. The entry is determined either by IP
or by hostname, all entries related to this host or IP are wiped out.

=cut

sub delete_host ($$) {

	my $self = shift;
	my $host = shift;

	my $type = $self->determine_ip_or_host($host);
	if (! $type) {
		print STDERR "Invalid host $host supplied\n";
		return 0;
	}
	if (! $self->{_hosts}{$host}) {
		print STDERR "No such host $host\n";
		return 0;
	}
	my $index = $self->{_hosts}{$host}{line};
	splice(@{$self->{_contents}}, $index, 1);
	if ($type == $TYPE_IP) {
		for my $h_host (@{$self->{_hosts}{$host}{hosts}}) {
			delete $self->{_hosts}{$h_host}
		}
		delete $self->{_hosts}{$host};
	}
	else {
		my $ip = $self->{_hosts}{$host}{ip};
		my $ip_hosts = $self->{_hosts}{$ip}{hosts};
		for my $h_host (@{$ip_hosts}) {
			delete $self->{_hosts}{$h_host}
		}
		delete $self->{_hosts}{$ip};
	}
	return 1;
}

=head2 update_host ($$)

Updates an entry in hosts table. Arguments should be of the following
format: $self->update_host($ip_or_host, ip => $new_ip, hosts => [
@new_hosts ]);

New hosts' argument may be a single scalar instead of arrayref.

=cut

sub update_host ($$%) {

	my $self   = shift;
	my $host   = shift;
	my %params = @_;

	my $type = $self->determine_ip_or_host($host);
	if (! $type) {
		print STDERR "Invalid host $host supplied\n";
		return 0;
	}
	if (! $self->{_hosts}{$host}) {
		print STDERR "No such host $host\n";
		return 0;
	}
	my $index = $self->{_hosts}{$host}{line};
	my $comment = $params{comment} ? " $params{comment}" : "";
	my $new_ip = $host;
	if ($params{ip} && !is_valid_ip($params{ip})) {
		print STDERR "Invalid argument IP given\n";
		return 0;
	}
	if ($params{hosts}) {
		if (! ref $params{hosts}) {
			$params{hosts} = [ $params{hosts} ];
		}
		if (ref $params{hosts} ne 'ARRAY') {
			print STDERR "New host names should be scalar value or array ref\n";
			return 0;
		}
		if (grep {
			!is_valid_host($_) &&
			print STDERR "Invalid host $_ passed, ignoring insert\n"
		} @{$params{hosts}}) {
			return 0;
		}
	}
	if ($type == $TYPE_IP && $params{ip}) {
		$new_ip = $params{ip};
		$self->{_hosts}{$new_ip} = delete $self->{_hosts}{$host};
		for my $h_host (@{$self->{_hosts}{$new_ip}{hosts}}) {
			$self->{_hosts}{$h_host}{ip} = $new_ip;
		}
	}
	if ($type == $TYPE_IP && $params{hosts}) {
		my @old_hosts = @{$self->{_hosts}{$new_ip}{hosts}};
		$self->{_hosts}{$new_ip}{hosts} = $params{hosts};
		for my $old_host (@old_hosts) {
			delete $self->{_hosts}{$old_host};
		}
		for my $new_host (@{$self->{_hosts}{$new_ip}{hosts}}) {
			$self->{_hosts}{$new_host} = {
				ip => $new_ip,
				comment => $comment,
				line => $self->{_hosts}{$new_ip}{line},
			}
		}
	}
	if ($type == $TYPE_HOST && $params{ip}) {
		my $old_ip = $self->{_hosts}{$host}{ip};
		$new_ip = $params{ip};
		for my $h_host (@{$self->{_hosts}{$old_ip}{hosts}}) {
			$self->{_hosts}{$h_host}{ip} = $new_ip;
		}
		$self->{_hosts}{$new_ip} = delete $self->{_hosts}{$old_ip};
	}
	if ($type == $TYPE_HOST && $params{hosts}) {
		$new_ip = $self->{_hosts}{$host}{ip};
		my @old_hosts = @{$self->{_hosts}{$new_ip}{hosts}};
		$self->{_hosts}{$new_ip}{hosts} = $params{hosts};
		for my $old_host (@old_hosts) {
			delete $self->{_hosts}{$old_host};
		}
		for my $new_host (@{$self->{_hosts}{$new_ip}{hosts}}) {
			$self->{_hosts}{$new_host} = {
				ip => $new_ip,
				comment => $comment,
				line => $self->{_hosts}{$new_ip}{line},
			}
		}
	}
	my $hosts_line = join(" ", @{$self->{_hosts}{$new_ip}{hosts}});
	my $new_line = "$new_ip\t$hosts_line$comment";
	splice(@{$self->{_contents}}, $index, 1, $new_line);

	return 1;
}

=head2 write_hosts($;$)

Writes the hosts table either to the default or to a specified (via
parameter) file.

=cut

sub write_hosts ($;$) {

	my $self = shift;
	my $hosts_file = shift || $self->{_file};

	open(F, ">$hosts_file") or die "Cannot write hosts file $hosts_file: $!";
	local $, = "\n";
	local $\ = "\n";
	print F @{$self->{_contents}};
	close F;
}

=head1 AUTHOR

Roman M. Parparov, C<< <roman at parparov.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-config-hosts at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Hosts>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

CAVEAT: the changes in host table are not committed unless you
explicitly write_hosts() them.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::Hosts


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-Hosts>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-Hosts>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-Hosts>

=item * Search CPAN

L<http://search.cpan.org/dist/Config-Hosts/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Vicente Gavara C<< <vicente.gavara at tcomm.es> >> for
providing a fix for editing/deleting routines.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Roman M. Parparov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Config::Hosts
