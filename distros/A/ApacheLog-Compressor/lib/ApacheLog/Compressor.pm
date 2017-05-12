package ApacheLog::Compressor;
# ABSTRACT: Convert Apache/CLF data to binary format
use strict;
use warnings;

use Socket qw(inet_aton inet_ntoa);
use Date::Parse qw(str2time);
use List::Util qw(min);
use URI;
use URI::Escape qw(uri_unescape);
use DateTime;
use Encode qw(encode_utf8 decode_utf8 FB_DEFAULT is_utf8 FB_CROAK);
use POSIX qw{strftime};

our $VERSION = '0.005';

=head1 NAME

ApacheLog::Compressor - convert Apache / CLF log files into a binary format for transfer

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use ApacheLog::Compressor;
 use Sys::Hostname qw(hostname);

 # Write all data to bzip2-compressed output file
 open my $out_fh, '>', 'compressed.log.bz2' or die "Failed to create output file: $!";
 binmode $out_fh;
 my $zip = IO::Compress::Bzip2->new($out_fh, BlockSize100K => 9);

 # Provide a callback to send data through to the file
 my $alc = ApacheLog::Compressor->new(
	on_write	=> sub {
		my ($self, $pkt) = @_;
		$zip->write($pkt);
	}
 );

 # Input file - normally use whichever one's just been closed + rotated
 open my $fh, '<', '/var/log/apache2/access.log.1' or die "Failed to open log: $!";

 # Initial packet to identify which server this came from
 $alc->send_packet('server',
 	hostname	=> hostname(),
 );

 # Read and compress all the lines in the files
 while(my $line = <$fh>) {
	 $alc->compress($line);
 }
 close $fh or die $!;
 $zip->close;

 # Dump the stats in case anyone finds them useful
 $alc->stats;

=head1 DESCRIPTION

Converts data from standard Apache log format into a binary stream which is typically 20% - 60% the size of the original file.
Intended for cases where log data needs transferring from multiple high-volume servers for analysis (potentially in realtime
via tail -f).

The log format is a simple dictionary replacement algorithm: each field that cannot be represented in a fixed-width datatype
is replaced with an indexed value, allowing the basic log line packet to be fixed size with additional packets containing the
first instance of each variable-width data item.

Example:

 api.example.com 105327 123.15.16.108 - apiuser@example.com [19/Dec/2009:03:12:07 +0000] "POST /api/status.json HTTP/1.1" 200 80516 "-" "-" "-"

The duration, IP, timestamp, method, HTTP version, response and size can all be stored as 32-bit quantities (or smaller), without losing
any information. The vhost, user and URL are extracted to separate packets, since we expect to see them at least twice on a typical server.

This would be converted to:

=over 4

=item * vhost packet - api.example.com assigned index 0

=item * user packet - apiuser@example.com assigned index 0

=item * url packet - /api/status.json assigned index 0

=item * timestamp packet - since a busy server is likely to have several requests a second, there's a tiny saving to be had by sending this only when the value changes, so we push this into a separate packet as well.

=item * log packet - actual data, binary encoded.

=back

The following packet types are available:

=over 4

=item * 00 - Log entry

=item * 01 - Change server

=item * 02 - timestamp

=item * 03 - vhost

=item * 04 - user

=item * 05 - useragent

=item * 06 - referer

=item * 07 - url

=item * 80 - reset

=back

The log entry itself normally consists of the following fields:

 N vhost
 N time
 N IP
 N user
 N useragent
 N timestamp
 C method
 C version
 n response
 N bytes
 N url

The format of the log file can be customised, see the next section for details.

=head3 FORMAT SPECIFICATION

A custom format can be provided as the C<format> parameter when instantiating
a new L<ApacheLog::Compressor> object via ->L</new>. This format consists of an
arrayref of key/value pairs, each value holding the following information:

=over 4

=item * id - the ID to use when sending packets

=item * type - L<pack> format specifier used when storing and retrieving the data, such as N1 or n1. Without this there will be no entry for the item in the compressed log stream

=item * regex - the regular expression used for matching this part of the log file. The
final regex will be the concatenation of all regex entries for the format, joined
using \s+ as the delimiter.

=item * process_in - coderef for converting incoming values from a plain text log source into compressed values, will receive $self (the current L<ApacheLog::Compressor> instance) and $data (the current hashref containing the raw data).

=item * process_out - coderef for converting values from a compressed source back to plain text, will receive $self (the current L<ApacheLog::Compressor> instance) and $data (the current hashref containing the raw data).

=back

=cut

our %HTTP_METHOD;
our @HTTP_METHOD_LIST = qw(GET PUT HEAD POST OPTIONS DELETE TRACE CONNECT MKCOL PATCH PROPFIND PROPPATCH FILEPATCH COPY MOVE LOCK UNLOCK SIGNATURE DELTA);
{ my $idx = 0; %HTTP_METHOD = map { $_ => $idx++ } @HTTP_METHOD_LIST; }

=head1 METHODS

=cut

=head2 new

Instantiate the class.

Takes the following named parameters:

=over 4

=item * on_write - coderef to call with packet data for each outgoing packet

=back

=cut


sub new {
	my $class = shift;
	my %args = @_;
	my $format = delete $args{format};
	my $self = bless {
		%args,
		entry_index	=> {},
		entry_cache	=> {},
		log_packet_count => 0,
		timestamp	=> undef,
		server		=> undef,
	}, $class;
	$self->{format} = $format || $self->default_format;
	$self->update_mapping;
	return $self;
}

=head2 default_format

Returns the default format used for parsing log lines.

This is an arrayref containing key => value pairs, see L</FORMAT SPECIFICATION> for
more details.

=cut

sub default_format {
	my $self = shift;
	return [
		type		=> { type => 'C1' },
		vhost		=> { id => 0x03, type => 'n1', regex => qr{([^ ]+)} },
		duration	=> { type => 'N1', regex => qr{(\d+)} },
		ip		=> {
			type => 'N1',
			regex => qr{(\S+)\s+\S+},
			process_in => sub {
				my ($self, $data) = @_;
				$data->{ip} = unpack('N1', inet_aton($data->{ip}));
			},
			process_out => sub {
				my ($self, $data) = @_;
				$data->{ip} = inet_ntoa(pack('N1', $data->{ip}));
			}
		},
		user		=> { id => 0x04, type => 'n1', regex => qr{(\S+)} },
		timestamp	=> {
			id => 0x02,
			regex => qr{\[([^\]]+)\]},
			process_in => sub {
				my ($self, $data) = @_;
				$data->{timestamp} = str2time($data->{timestamp});
			}
		},
		method		=> {
			type => 'C1',
			regex => qr{"([^ ]+)},
			process_in => sub {
				my ($self, $data) = @_;
				$data->{method} = $HTTP_METHOD{$data->{method}};
			},
			process_out => sub {
				my ($self, $data) = @_;
				$data->{method} = $HTTP_METHOD_LIST[$data->{method}];
			}
		},
		url		=> {
			id => 0x07,
			type => 'N1',
			regex => qr{([^ ]+)},
			process_in => sub {
				my ($self, $data) = @_;
				return $data->{url} = '' unless defined $data->{url};

				($data->{url}, $data->{query}) = split /\?/, $data->{url}, 2;
# Dodgy UTF8 handling, currently disabled - no guarantee that URLs are UTF8 anyway
#				if(length $data->{url}) {
				# URI::Escape's uri_unescape but in byte mode so we can check utf8 decoding manually
#					my $txt = $data->{url};
#					$txt = encode_utf8($txt); # turn OFF utf8
#					$txt =~ s/%([0-9A-Fa-f]{2})/pack("C1", hex($1))/ge; # expand
#					$txt = decode_utf8($txt); # turn ON utf8 where applicable
#					$data->{url} = $txt;
#				}
#				if(defined $data->{query} && length $data->{query}) {
				# URI::Escape's uri_unescape but in byte mode so we can check utf8 decoding manually
#					(my $txt = $data->{query}) =~ s/%([0-9A-Fa-f]{2})/pack("C1", hex($1))/eg;
#					$data->{query} = decode_utf8($txt, FB_DEFAULT);
#				}
			}
		},
		query		=> { id => 0x0A, type => 'N1', },
		ver		=> {
			type => 'C1',
			regex => qr{HTTP/(\d+\.\d+)"},
			process_in => sub {
				my ($self, $data) = @_;
				$data->{ver} = ($data->{ver} eq '1.0' ? 0 : 1);
			}, process_out => sub {
				my ($self, $data) = @_;
				$data->{ver} = ($data->{ver} ? '1.1' : '1.0');
			}
		},
		result		=> { type => 'n1', regex => qr{(\d+)} },
		size		=> {
			type => 'N1',
			regex => qr{(\d+|-)},
			process_in => sub {
				my ($self, $data) = @_;
				$data->{size} = ($data->{size} eq '-') ? -1 : $data->{size};
			}, process_out => sub {
				my ($self, $data) = @_;
				$data->{size} = ($data->{size} == 4294967295) ? '-' : $data->{size};
			}
		},
		refer		=> { id => 0x06, type => 'n1', regex => qr{"([^"]*)"} },
		useragent	=> { id => 0x05, type => 'n1', regex => qr{"([^"]*)"} },
	];
}

=head2 update_mapping

Refresh the mapping from format keys and internal definitions.

=cut

sub update_mapping {
	my $self = shift;
	my %fmt = @{ $self->{format} };
	$self->{format_hash} = \%fmt;
	$self->{packet_handler} = {
		0x00 => 'log',
		0x01 => 'server',
		0x80 => 'reset',
		map { $fmt{$_}->{id} => $_ } grep { exists $fmt{$_}->{id} } keys %fmt
	};

# Extract information from format strings so that we know how big the packets are and where the data goes
	my @fmt = @{$self->{format}};
	my $pack_str = '';
	my $log_len = 0;
	my @format_keys;
	my @regex;
	ITEM:
	while(@fmt) {
		my $k = shift(@fmt);
		my $v = shift(@fmt);
		$v = { type => $v } unless ref $v;
		if(exists $v->{regex}) {
			push @regex, $v->{regex};
			push @{$self->{log_regex_keys}}, $k;
		}
		if(exists $v->{process_in}) {
			push @{$self->{log_process}}, $v->{process_in};
		}
		if(exists $v->{process_out}) {
			push @{$self->{log_process_out}}, $v->{process_out};
		}

		my $type = $v->{type};
		next ITEM unless $type;

		push @format_keys, $k;
		$pack_str .= $type;

# Obviously these will need updating if we use any other pack() datatypes
		if($type =~ /^C(\d+)/) {
			$log_len += $1;
		} elsif($type =~ /^n(\d+)/) {
			$log_len += 2 * $1;
		} elsif($type =~ /^N(\d+)/) {
			$log_len += 4 * $1;
		} else {
			die "no idea what $type is";
		}
	}
	my $regex = join(' ', @regex);
	$self->{log_regex} = qr{^$regex};
	$self->{log_format} = $pack_str;
	$self->{log_record_length} = $log_len;
	$self->{format_keys} = \@format_keys;
	return $self;
}

=head2 cached

Returns the index for the given type and value, generating a packet if no previous value was found.

=cut

sub cached {
	my $self = shift;
	my ($type, $v) = @_;
	$v = '' unless defined $v;
	my $id = $self->{entry_cache}->{$type}->{$v};
	unless(defined $id) {
		push @{ $self->{entry_index}->{$type} }, $v;
		++$self->{entry_count}->{$type};
		$id = $self->{entry_cache}->{$type}->{$v} = scalar(@{ $self->{entry_index}->{$type} }) - 1;
		$self->send_packet($type, id => $id, data => encode_utf8($v));
	}
	return $id;
}

=head2 from_cache

Read a value from the cache, for expanding compressed log format entries.

=cut

sub from_cache {
	my $self = shift;
	my ($type, $id) = @_;
	die "ID $id not found for $type\n" unless defined $self->{entry_index}->{$type}->[$id];
	return $self->{entry_index}->{$type}->[$id];
}

=head2 set_key

Set a cache index key to a value when expanding a packet stream.

=cut

sub set_key {
	my $self = shift;
	my $type = shift;
	my %args = @_;
	my $v = decode_utf8($args{data});
	$self->{entry_cache}->{$type}->{$v} = $args{id};
	$self->{entry_index}->{$type}->[$args{id}] = $v;
	$self->{"on_set_$type"}->($self, $args{id}, $v) if $self->{"on_set_$type"};
	$self->{"on_set_key"}->($self, $type, $args{id}, $v) if $self->{on_set_key};
	return $self;
}

=head2 compress

General compression function. Given a line of data, sends packets as required to transmit that information.

=cut

sub compress {
	my $self = shift;
	my $txt = shift;
	my %data;
	@data{@{$self->{log_regex_keys}}} = $txt =~ m!$self->{log_regex}!
		or return $self->invoke_event(bad_data => $txt);
	$data{type} = 0;
	$_->($self, \%data) for @{$self->{log_process}};
	return if exists($self->{filter}) && !$self->{filter}->($self, \%data);

	if(!defined($self->{timestamp}) || $data{timestamp} != $self->{timestamp}) {
		$self->{timestamp} = $data{timestamp};
		$self->send_packet('timestamp', timestamp => $self->{timestamp});
	}

	my @fmt = @{$self->{format}};
	my @data;
	while(@fmt) {
		my $k = shift(@fmt);
		my $v = shift(@fmt);
		if($v->{type}) {
			$data{$k} = $self->cached($k, $data{$k}) if exists $v->{id};
			push @data, $data{$k};
		}
	}
	$self->write_packet(pack($self->{log_format}, @data));

	# Recycle everything after 5m entries
	if($self->{log_packet_count}++ >= 5000000) {
		$self->send_packet('reset');
		$self->{log_packet_count} = 0;
	}
	return $self;
}

=head2 send_packet

Generate and send a packet for the given type.

=cut

sub send_packet {
	my $self = shift;
	my $type = shift;

# Try the specific method for this packet if we have one
	my $method = "packet_$type";
	return $self->write_packet($self->$method(@_)) if $self->can($method);

# Otherwise use the generic format for ASCIIZ mapping
	my %args = @_;
	return $self->write_packet(pack('C1N1Z*', $self->{format_hash}->{$type}->{id}, $args{id}, $args{data}));
}

=head2 packet_reset

Generate a reset packet and clear internal caches in the process.

=cut

sub packet_reset {
	my $self = shift;
	$self->{entry_cache} = {};
	$self->{entry_index} = {};
	return pack('C1', 0x80);
}

=head2 packet_server

Generate a server packet.

=cut

sub packet_server {
	my $self = shift;
	my %args = @_;
	return pack('C1Z*', 1, $args{hostname});
}

=head2 packet_timestamp

Generate the timestamp packet.

=cut

sub packet_timestamp {
	my $self = shift;
	my %args = @_;
	return pack('C1N1', 2, $args{timestamp});
}

=head2 write_packet

Write a packet to the output handler.

=cut

sub write_packet {
	my ($self, $pkt) = @_;
	$self->{on_write}->($self, $pkt);
	return $self;
}

=head2 expand

Expand incoming data.

=cut

sub expand {
	my $self = shift;
	my $pkt = shift;
	my $type = unpack('C1', $$pkt);
	unless($self->{packet_handler}->{$type}) {
		print substr $$pkt, 0, 16;
		die "what is $type?";
	}
	my $method = 'handle_' . $self->{packet_handler}->{$type};
	return $self->$method($pkt) if $self->can($method);

	return unless index($$pkt, "\0", 5) >= 0;

	(undef, my $id, my $data) = unpack('C1N1Z*', $$pkt);
	substr $$pkt, 0, 6 + length($data), '';
	$self->set_key($self->{packet_handler}->{$type}, data => $data, id => $id);
}

=head2 handle_reset

Handle an incoming reset packet.

=cut

sub handle_reset {
	my $self = shift;
	my $pkt = shift;
	# Clear cache for all items
	$self->{entry_cache} = { };
	$self->{entry_index} = { };
	substr $$pkt, 0, 1, '';
}

=head2 handle_log

Handle an incoming log packet.

=cut

sub handle_log {
	my $self = shift;
	my $pkt = shift;
	return unless length $$pkt >= $self->{log_record_length};

	my %data;
	@data{@{ $self->{format_keys} }} = unpack($self->{log_format}, $$pkt);
	$_->($self, \%data) for @{$self->{log_process_out}};

	die "No timestamp" unless $self->{timestamp};
	$self->{on_log_line}->($self, \%data) if exists $self->{on_log_line};
	substr $$pkt, 0, $self->{log_record_length}, '';
}

=head2 data_hashref

Convert logline data to a hashref.

=cut

sub data_hashref {
	my $self = shift;
	my $data = shift;
	my %info = %$data;

	$info{$_} = $self->from_cache($_, $info{$_}) for qw(vhost user url query useragent refer);
	$info{server} = $self->{server};
	undef $info{$_} for grep { $info{$_} eq '-' } qw(user refer size useragent);
	undef $info{query} unless defined $info{query} && length $info{query};
#DateTime->from_epoch(epoch => $self->{timestamp})->strftime("%d/%b/%Y:%H:%M:%S %z");
	$info{timestamp} = strftime("%d/%b/%Y:%H:%M:%S %z", gmtime($self->{timestamp}));
	return \%info;
}

=head2 data_to_text

Internal method for converting the current log entry to a text string in
something approaching the 'standard' Apache log format (almost, but not quite,
CLF).

=cut

sub data_to_text {
	my $self = shift;
	my $data = shift;
	my $q = $self->from_cache('query', $data->{query});
	$q = '' unless defined $q;
	return join(' ',
		$self->from_cache('vhost', $data->{vhost}),
		$data->{duration},
		$data->{ip},
		'-',
		$self->from_cache('user', $data->{user}),
		'[' . DateTime->from_epoch(epoch => $self->{timestamp})->strftime("%d/%b/%Y:%H:%M:%S %z") . ']',
		'"' . $data->{method} . ' ' . $self->from_cache('url', $data->{url}) . (length $q ? "?$q" : "") . ' HTTP/' . ($data->{ver} ? '1.1' : '1.0') . '"',
		$data->{result},
		$data->{size},
		'"' . $self->from_cache('useragent', $data->{useragent}) . '"',
		'"' . $self->from_cache('refer', $data->{refer}) . '"',
	);
}

=head2 handle_server

Internal method for processing a server record (used to indicate the server
name subsequent records apply to).

=cut

sub handle_server {
	my $self = shift;
	my $pkt = shift;
	return unless index($$pkt, "\0", 1) >= 0;
	(undef, my $server) = unpack('C1Z*', $$pkt);
	substr $$pkt, 0, 2 + length($server), '';
	$self->{server} = $server;
	$self;
}

=head2 handle_timestamp

Internal method for processing a timestamp entry.

=cut

sub handle_timestamp {
	my $self = shift;
	my $pkt = shift;
	return unless length $$pkt >= 5;
	(undef, my $hostname) = unpack('C1N1', $$pkt);
	substr $$pkt, 0, 5, '';
	$self->{timestamp} = $hostname;
	warn "Zero timestamp?" unless $self->{timestamp};
	$self;
}

=head2 invoke_event

Internal method for invoking an event.

=cut

sub invoke_event {
	my $self = shift;
	my $event = shift;
	my $code = $self->{"on_" . $event} || $self->can("on_" . $event) or return;
	return $code->(@_);
}

=head2 stats

Print current stats - not all that useful since we clear cached values regularly.

=cut

sub stats {
	my $self = shift;
	printf("%-64.64s saw total entries: %s\n", $_, $self->{entry_count}->{$_}) for sort keys %{$self->{entry_index}};
}

1;

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2009-2011. Licensed under the same terms as Perl itself.
