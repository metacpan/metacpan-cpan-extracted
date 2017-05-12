package Amethyst::Brain::Infobot::Module::Google;

use strict;
use vars qw(@ISA);
use Data::Dumper;
use POE;
use POE::Component::Client::UserAgent;
use HTTP::Request::Common;
use HTTP::Response;
use WWW::Search;
use WWW::SearchResult;
use Amethyst::Message;
use Amethyst::Brain::Infobot;
use Amethyst::Brain::Infobot::Module;

@ISA = qw(Amethyst::Brain::Infobot::Module);

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(
					Name		=> 'Google',
					Regex		=> qr/^(?:google|search)\s+for\s+(.*)$/i,
					Usage		=> '(google|search) for .*',
					Description	=> "Search Google",
					@_
						);

	return bless $self, $class;
}

sub init {
	my $self = shift;

	eval {
		spawn POE::Component::Client::UserAgent(
						agent	=> 'Lynx/2.8rel.1 libwww-FM/2.14',
							);
	};
	if ($@) {
		die $@ unless $@ =~ /^alias is in use by another session/;
	}
}

sub action {
    my ($self, $message, $query) = @_;

	my %states = map { $_ => "handler_$_" } qw(
					_start response
						);

	print STDERR "Creating child session for google\n";

	POE::Session->create(
		package_states	=> [ ref($self) => \%states ],
		args			=> [ $self, $message, $query ],
			);

	return 1;
}


sub parse_response {
	my ($self, $response) = @_;

	$self->{_debug} = 10;

	print STDERR "Self is $self\n";

	# parse the output
	my ($HEADER, $HITS, $TRAILER, $POST_NEXT) = (1..10);

	my @hits = ();
	my $hit = undef;

	my $approx_count = -1;

	my $state = $HEADER;

	my @lines = split(/\n/, $response->content);

	foreach (@lines) {
		next unless /\S/; # short circuit for blank lines

		# print STDERR substr($_, 0, 70) . "\n" if $self->{_debug};
		print STDERR $_ . "\n" if $self->{_debug};

		if ($state == $HEADER && m/about <b>([\d,]+)<\/b>/) {
			$approx_count = $1;
			print STDERR "Found Total: $approx_count\n" ;
			$state = $HITS;
		}
		elsif ($state == $HITS &&
			m|<p><a href=[^\s]*(http[^&>]*)[^>]*>(.*?)</a>|i) {
			my ($url, $title) = ($1, $2);
			$hit = new WWW::SearchResult();
			push(@hits, $hit);

			print STDERR "**Found HIT Line**\n" if ($self->{_debug});
			$url =~ s/(>.*)//g;
			$hit->add_url(WWW::Search::strip_tags($url));
			$title = "No Title" if ($title =~ /^\s+/);

			$hit->title(WWW::Search::strip_tags($title));
			$state = $HITS;
		} 
		elsif ($state == $HITS && m|Description:</font></span>\s*(.*)<br>|i) {
			print STDERR "**Parsing Description Line**\n" if ($self->{_debug});
			if ($hit) {
				my $desc = $1;
				$desc =~ s/<.*?>//g;
				$desc =~ s/Category.*//;
				$hit->description($desc);
				$state = $HITS;
			}
			else {
				print STDERR "ERROR: No hit when parsing description\n";
			}
		} 
		elsif ($state == $HITS && m@<div class=nav>@i) {
			print STDERR "**Found Last Line**\n" if ($self->{_debug});
			# end of hits
			$state = $TRAILER;
		}
		else {
			print STDERR "**No match**\n" if ($self->{_debug});
		}
	}

	return @hits;
}

sub handler_response {
	my ($kernel, $heap, $session, $pbargs) =
					@_[KERNEL, HEAP, SESSION, ARG1];
	my ($request, $response, $entry) = @$pbargs;

	unless ($response->is_success) {
		my $reply = $heap->{Module}->reply_to($heap->{Message},
						"HTTP Request failed");
		$reply->send;
		print STDERR $response->error_as_HTML;
		return;
	}

	if (0) {
		local *LOGFILE;
		open(LOGFILE, ">google.log") or die "Can't open file: $!";
		print LOGFILE $response->content;
		print LOGFILE "\n\n\n";
		close(LOGFILE);
	}

	# What we want here is a WWW::Search with a _separate_ parser
	# for pages which we have alrady retrieved.

	my @hits = parse_response($heap->{Module}, $response);

	my $module = $heap->{Module};

	# print STDERR Dumper(\@hits);

	if (@hits) {
		@hits = @hits[0..3] if @hits > 4;
		foreach my $hit (@hits) {
			my $url = $hit->url;
			my $title = $hit->title;
			my $description = $hit->description || '';
			my $reply = $module->reply_to($heap->{Message},
							$url . ": " . $title);
			$reply->send;
		}
	}
	else {
		my $reply = $module->reply_to($heap->{Message}, 'No results');
		$reply->send;
	}
}

sub handler__start {
	my ($kernel, $heap, $session, $module, $message, $query) =
					@_[KERNEL, HEAP, SESSION, ARG0, ARG1, ARG2];

	$heap->{Module} = $module;
	$heap->{Message} = $message;
	$heap->{Query} = $query;

	my $uri = new URI('http://www.google.com:80/search');
	$uri->query_form(q => $query);
	$uri = $uri->canonical;
	print STDERR "Searching for " . $uri->as_string . "\n";
	my $request = new HTTP::Request(GET => $uri);
	my $postback = $session->postback('response');

	$kernel->post('useragent', 'request',
					request		=> $request,
					response	=> $postback,
						);
}

1;
