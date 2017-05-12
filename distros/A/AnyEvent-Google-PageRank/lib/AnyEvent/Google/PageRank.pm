package AnyEvent::Google::PageRank;

=head1 NAME

AnyEvent::Google::PageRank - Non-blocking wrapper for WWW::Google::PageRank

=cut

use AnyEvent::HTTP;
use URI::Escape;
use Carp;
use base 'Exporter';
use strict;
{
	# we really do not need LWP, but WWW::Google::PageRank uses it
	# let's lie that LWP::UserAgent already loaded
	local $INC{'LWP/UserAgent.pm'} = 1;
	require WWW::Google::PageRank;
}

=head1 SYNOPSIS

=over

=item Object-oriented interface

	use AnyEvent::Google::PageRank;
	use AnyEvent;
	
	my @urls = qw(http://perl.org http://cpan.org http://perlmonks.org);
	my $rank = AnyEvent::Google::PageRank->new(
		timeout => 10,
		proxy   => 'localhost:3128'
	);

	my $cv = AnyEvent->condvar;
	$cv->begin for @urls;

	foreach my $url (@urls) {
		$rank->get($url, sub {
			my ($rank, $headers) = @_;
			print "$url - ", defined($rank) ? $rank : "fail: $headers->{Status} - $headers->{Reason}", "\n";
			$cv->end;
		});
	}

	$cv->recv;

=item Procedural interface

	use AnyEvent::Google::PageRank qw(rank_get);
	use AnyEvent;

	my @urls = qw(http://perl.org http://cpan.org http://perlmonks.org);
	my $cv = AnyEvent->condvar;
	$cv->begin for @urls;

	foreach my $url (@urls) {
		rank_get $url, timeout => 10, proxy => 'localhost:3128', sub {
			my ($rank, $headers) = @_;
			print "$url - ", defined($rank) ? $rank : "fail: $headers->{Status} - $headers->{Reason}", "\n";
			$cv->end;
		};
	}

	$cv->recv;

=back

=cut

=head1 DESCRIPTION

AnyEvent::Google::PageRank helps to get google pagerank for specified url, like WWW::Google::PageRank
does. But in contrast to WWW::Google::PageRank you can perform many requests in parallel. This module
uses AnyEvent::HTTP as HTTP client.

=head1 EXPORT

=over

=item rank_get() - on request

=back

=cut

our $VERSION = '0.04';
our @EXPORT_OK = qw(rank_get);

use constant {
	DEFAULT_AGENT => 'Mozilla/4.0 (compatible; GoogleToolbar 2.0.111-big; Windows XP 5.1)',
	DEFAULT_HOST  => 'toolbarqueries.google.com',
};

=head1 METHODS

=head2 new(%opts)

Creates new AnyEvent::Google::PageRank object. The following options available (all are optional):

  KEY       DESCRIPTION                                DEFAULT
  ------------------------------------------------------------------
  agent     User-Agent value in the headers            Mozilla/4.0 (compatible; GoogleToolbar 2.0.111-big; Windows XP 5.1)
  proxy     http proxy as address:port                 undef
  timeout   timeout for network operations             AnyEvent::HTTP default timeout
  host      host for query                             toolbarqueries.google.com
  ae_http   AnyEvent::HTTP request options as hashref  undef

=cut

sub new {
	my ($class, %opts) = @_;
	
	my $self = {};
	$self->{agent}   = delete($opts{agent}) || DEFAULT_AGENT;
	$self->{timeout} = delete($opts{timeout});
	$self->{proxy}   = delete($opts{proxy});
	$self->{host}    = delete($opts{host});
	$self->{ae_http} = delete($opts{ae_http});
	
	if (%opts) {
		croak 'Unrecognized options specified: ', join(', ', keys %opts);
	}
	
	bless $self, $class;
}

=head2 get($url, $cb->($rank, $headers))

Get rank for specified url and call specified callback on finish. Parameters for callback are:
rank and headers. On fail rank will be undef and reason could be found in $headers->{Reason},
code in $headers->{Status}. Special codes provided by this module are:

	695 - malformed url

For other codes see L<AnyEvent::HTTP>

=cut

sub get {
	my ($self, $url, $cb) = @_;
	
	croak 'Not a code reference in $cb'
		if ref($cb) ne 'CODE';
	
	return $cb->(undef, {Status => 695, Reason => 'malformed url'}) if $url !~ m[^https?://]i;
	
	my $ch = '6' . WWW::Google::PageRank::_compute_ch_new('info:' . $url);
	my $query = 'http://' . ($self->{host}||DEFAULT_HOST) . '/tbr?client=navclient-auto&ch=' . $ch .
		'&ie=UTF-8&oe=UTF-8&features=Rank&q=info:' . uri_escape($url);
	
	my $opts = {};
	if (ref($self) eq 'HASH') {
		# call from rank_get
		$opts = $self;
		$opts->{proxy}                 = [split /:/, $opts->{proxy}] if defined $opts->{proxy} && index($opts->{proxy}, ':') != -1;
		$opts->{headers}{'User-Agent'} = exists($opts->{agent}) ? $opts->{agent} : DEFAULT_AGENT;
	}
	else {
		# object call
		%$opts = %{$self->{ae_http}} if ref($self->{ae_http}) eq 'HASH';
		$opts->{timeout}               = $self->{timeout} if defined $self->{timeout};
		$opts->{proxy}                 = [split /:/, $self->{proxy}] if defined $self->{proxy};
		$opts->{headers}{'User-Agent'} = $self->{agent} if defined $self->{agent};
	}
	
	http_get $query, %$opts, sub {
		my ($data, $headers) = @_;
		
		if ($headers->{Status} =~ /^2/ && $data =~ /Rank_\d+:\d+:(\d+)/) {
			$cb->($1, $headers);
		}
		else {
			$cb->(undef, $headers);
		}
	};
}

=head1 FUNCTIONS

=head2 rank_get($url, key => val, ..., $cb->($rank, $headers))

Get rank for specified url and call specified callback on finish. Key/value pairs
are options understanded by AnyEvent::HTTP::http_request() and new() method of this
module (except ae_http option). For $cb description see get() method.

=cut

sub rank_get {
	my $cb = pop @_;
	my ($url, %opts) = @_;
	get(\%opts, $url, $cb);
}

1;

=head1 BUGS

Not a bug: don't forget to set $AnyEvent::HTTP::MAX_PER_HOST to proper value.
See L<AnyEvent::HTTP> for details.

If you find any bug, please report.

=head1 SEE ALSO

L<WWW::Google::PageRank>, L<AnyEvent::HTTP>

=head1 COPYRIGHT

Copyright Oleg G <oleg@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
