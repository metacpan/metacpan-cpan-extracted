package App::Lastmsg;

use 5.014000;
use strict;
use warnings;

use Config::Auto;
$Config::Auto::DisablePerl = 1;
use Date::Parse;
use Email::Folder;
use List::Util qw/max/;
use POSIX qw/strftime/;

our $OUTPUT_FILEHANDLE = \*STDOUT;
our $VERSION = '0.002001';

our @DEFAULT_INBOX;
push @DEFAULT_INBOX, "/var/mail/$ENV{USER}" if exists $ENV{USER};
push @DEFAULT_INBOX, "$ENV{HOME}/Maildir"   if exists $ENV{HOME};

sub format_time { strftime '%c', localtime shift }

sub run {
	my $config = Config::Auto->new(format => 'yaml')->parse;
	die "No configuration file found\n" unless $config;
	die "No addresses to track listed in config\n" unless $config->{track};

	$config->{inbox} //= [];
	$config->{sent}  //= [];
	$config->{inbox} = [$config->{inbox}] unless ref $config->{inbox};
	$config->{sent}  = [$config->{sent}]  unless ref $config->{sent};
	$config->{inbox} = \@DEFAULT_INBOX unless @{$config->{inbox}};

	my %track = %{$config->{track}};
	my %addr_to_id = map {
		my $id = $_;
		my $track = $track{$id};
		$track = [$track] unless ref $track;
		map { $_ => $id } @$track
	} keys %track;

	my (%lastmsg, %lastaddr);

	my $process_message = sub {
		my ($msg, @people) = @_;
		for my $addr (@people) {
			($addr) = $addr =~ /<\s*(.+)\s*>/ if $addr =~ /</;
			$addr =~ s/^\s+//;
			$addr =~ s/\s+$//;
			my $id = $addr_to_id{$addr};
			next unless $id;
			my $date = str2time $msg->header_raw('Date');
			if (!exists $lastmsg{$id} || $lastmsg{$id} < $date) {
				$lastmsg{$id} = $date;
				$lastaddr{$id} = $addr;
			}
		}
	};

	for my $folder (@{$config->{inbox}}) {
		next unless -e $folder;
		say STDERR "Scanning $folder (inbox)" if $ENV{LASTMSG_DEBUG};
		my $folder = Email::Folder->new($folder);
		while (my $msg = $folder->next_message) {
			my ($from) = grep { /^from$/i } $msg->header_names;
			$from = $msg->header_raw($from);
			if ($ENV{LASTMSG_DEBUG}) {
				my ($mid) = grep { /^message-id$/i } $msg->header_names;
				say STDERR 'Processing ', $msg->header_raw($mid), " from $from";
			}
			$process_message->($msg, $from);
		}
	}

	for my $folder (@{$config->{sent}}) {
		next unless -e $folder;
		say STDERR "Scanning $folder (sent)" if $ENV{LASTMSG_DEBUG};
		my $folder = Email::Folder->new($folder);
		while (my $msg = $folder->next_message) {
			my @hdrs = grep { /^(?:to|cc|bcc)$/i } $msg->header_names;
			my @people;
			for my $hdr (@hdrs) {
				@people = (@people, split /,/, $msg->header_raw($hdr));
			}
			if ($ENV{LASTMSG_DEBUG}) {
				my ($mid) = grep { /^message-id$/i } $msg->header_names;
				say STDERR 'Processing ', $msg->header_raw($mid),
				  ' sent to ', join ',', @people;
			}
			$process_message->($msg, @people);
		}
	}

	my $idlen   = max map { length } keys %track;
	my $addrlen = max map { length } values %lastaddr;

	for (sort { $lastmsg{$b} <=> $lastmsg{$a} } keys %lastmsg) {
		my $time = format_time $lastmsg{$_};
		printf $OUTPUT_FILEHANDLE "%-${idlen}s %-${addrlen}s %s\n", $_, $lastaddr{$_}, $time;
	}

	for (grep { !exists $lastmsg{$_} } sort keys %track) {
		printf $OUTPUT_FILEHANDLE "%-${idlen}s %-${addrlen}s NOT FOUND\n", $_, ''
	}
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Lastmsg - last(1) semblance for your inbox

=head1 SYNOPSIS

  use App::Lastmsg;
  App::Lastmsg::run

=head1 DESCRIPTION

This module contains the implementation of the L<lastmsg(1)> script.
See that script's documentation for information on what it does.

=head1 SEE ALSO

L<lastmsg>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
