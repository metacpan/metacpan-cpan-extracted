package DataDog::DogStatsd;

# ABSTRACT: A Perl client for DogStatsd

use strict;
use warnings;

our $VERSION = '0.04';

use IO::Socket::INET;

sub new {
	my $classname = shift;
	my $class = ref( $classname ) || $classname;
	my %p = @_ % 2 ? %{$_[0]} : @_;

	$p{host} ||= '127.0.0.1';
	$p{port} ||= 8125;
	$p{namespace} ||= '';

	return bless \%p, $class;
}

sub _socket {
	my $self = shift;
	return $self->{_socket} if $self->{_socket};
	$self->{_socket} = IO::Socket::INET->new(
		PeerAddr => $self->{'host'},
		PeerPort => $self->{'port'},
		Proto    => 'udp'
	);
	return $self->{_socket};
}

sub namespace {
	my $self = shift;
	$self->{'namespace'} = shift;
}

sub increment {
	my $self = shift;
	my $stat = shift;
	my $opts = shift || {};
	$self->count( $stat, 1, $opts );
}

sub decrement {
	my $self = shift;
	my $stat = shift;
	my $opts = shift || {};
	$self->count( $stat, -1, $opts );
}

sub count {
	my $self  = shift;
	my $stat  = shift;
	my $count = shift;
	my $opts  = shift || {};
	$self->send_stats( $stat, $count, 'c', $opts );
}

sub gauge {
	my $self  = shift;
	my $stat  = shift;
	my $value = shift;
	my $opts  = shift || {};
	$self->send_stats( $stat, $value, 'g', $opts );
}

sub histogram {
	my $self  = shift;
	my $stat  = shift;
	my $value = shift;
	my $opts  = shift || {};
	$self->send_stats( $stat, $value, 'h', $opts );
}

sub timing {
	my $self = shift;
	my $stat = shift;
	my $ms   = shift;
	my $opts = shift || {};
	$self->send_stats( $stat, sprintf("%d", $ms), 'ms', $opts );
}

# Reports execution time of the provided block using {#timing}.
#
# @param [String] stat stat name
# @param [Hash] opts the options to create the metric with
# @option opts [Numeric] :sample_rate sample rate, 1 for always
# @option opts [Array<String>] :tags An array of tags
# @yield The operation to be timed
# @see #timing
# @example Report the time (in ms) taken to activate an account
#   $statsd.time('account.activate') { @account.activate! }
##def time(stat, opts={})
##	start = Time.now
##	result = yield
##	timing(stat, ((Time.now - start) * 1000).round, opts)
##	result
##end

sub set {
	my $self  = shift;
	my $stat  = shift;
	my $value = shift;
	my $opts  = shift || {};
	$self->send_stats( $stat, $value, 's', $opts );
}

sub send_stats {
	my $self  = shift;
	my $stat  = shift;
	my $delta = shift;
	my $type  = shift;
	my $opts  = shift || {};

	my $sample_rate = defined $opts->{'sample_rate'} ? $opts->{'sample_rate'} : 1;
	if( $sample_rate == 1 || rand() <= $sample_rate ) {
		$stat =~ s/::/./g;
		$stat =~ s/[:|@]/_/g;
		my $rate = '';
		$rate = "|\@${sample_rate}" unless $sample_rate == 1;
		my $tags = '';
		$tags = "|#".join(',',@{$opts->{'tags'}}) if $opts->{'tags'};
		my $message = $self->{'namespace'}."${stat}:${delta}|${type}${rate}${tags}";
		return $self->send_to_socket( $message );
	}
}

sub send_to_socket {
	my ($self, $message) = @_;

	my $r = send($self->_socket(), $message, 0);
	if (! defined $r) {
		return 0;
	} elsif ($r != length($message)) {
		return 0;
	}

	return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

DataDog::DogStatsd - A Perl client for DogStatsd

=head1 SYNOPSIS

	use DataDog::DogStatsd;

	my $statsd = DataDog::DogStatsd->new;
	$statsd->increment( 'user.login', { tags => [ $s->cs->param( 'loginName' ) ] } );
	$statsd->timing('page.load', 320);
	$statsd->gauge('users.online', 100);

	# namespace version
	my $statsd = DataDog::DogStatsd->new(namespace => 'account.'); # note the '.' at the ending
	$statsd->increment('activate'); # actually as account.activate

=head1 DESCRIPTION

Statsd: A DogStatsd client (https://www.datadoghq.com)

The difference between L<Net::Statsd> and this is that it supports tags and namespace.

=head1 METHODS

=head2 new

=over 4

=item * host

default to 127.0.0.1

=item * port

default to 8125

=item * namespace

default to ''

=back

=head2 increment

	$statsd->increment( 'page.views' );
	$statsd->increment( 'test.stats', { sample_rate => 0.5 } );
	$statsd->increment( 'user.login', { tags => [ $s->cs->param( 'loginName' ) ] } );

Sends an increment (count = 1) for the given stat to the statsd server.

=head2 decrement

	$statsd->decrement( 'products.available' );

Sends a decrement (count = -1) for the given stat to the statsd server.

=head2 count

	$statsd->count( 'test.stats', 2 );

Sends an arbitrary count for the given stat to the statsd server.

=head2 gauge

	$statsd->gauge('users.online', 100);
	$statsd->gauge('users.online', 100, { tags => ['tag1', 'tag2'] });

Sends an arbitary gauge value for the given stat to the statsd server.

This is useful for recording things like available disk space, memory usage, and the like, which have different semantics than counters.

=head2 histogram

	$statsd->histogram($stats, $value);

Sends a value to be tracked as a histogram to the statsd server.

=head2 timing

	$statsd->timing('page.load', 320);
	$statsd->timing('page.load', 320, { sample_rate => 0.5, tags => ['tag1', 'tag2'] });

Sends a timing (in ms) for the given stat to the statsd server. The sample_rate determines what percentage of the time this report is sent. The statsd server then uses the sample_rate to correctly track the average timing for the stat.

=head2 set

	$statsd->set('visitors.uniques', $user_id);

Sends a value to be tracked as a set to the statsd server.

=head1 AUTHORS

Stefan Goethals <stefan@zipkid.eu>