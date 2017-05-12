package Amethyst::Brain::Infobot::Module::Statement;

use strict;
use vars qw(@ISA
		$RE_VERB $RE_QUESTION $RE_IGNORE $RE_PREAMBLE
		$RE_RMKPREFIX $RE_RMKSUFFIX
		$RE_RMVPREFIX $RE_RMVSUFFIX
		);
use Amethyst::Message;
use Amethyst::Store;
use Amethyst::Brain::Infobot;
use Amethyst::Brain::Infobot::Module;

@ISA = qw(Amethyst::Brain::Infobot::Module);
$RE_VERB = "is|are|has";
$RE_QUESTION = "what|who|where|which|when|wot|wtf";
$RE_IGNORE = "if|this|that|there|so|some|someone" .
				"|he|she|we|it|they|you|i" .
				"|$RE_QUESTION";
$RE_PREAMBLE = "think|thinks|note|notes|said|say|says|that";
$RE_RMKPREFIX = "but|and|or|btw|actually|well"; # |a|the
$RE_RMKSUFFIX = "really|actually";
$RE_RMVSUFFIX = "too|also|as well";

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(
					Name		=> 'Statement',
					# Regex		=> qr/(?:karma|\+\+|--)/i,
					Usage		=> 'Make a statement. Ask a question.',
					Description	=> "Statement handler",
					@_
						);

	die "No FactoidWrite store in Infobot config"
					unless $self->{Infobot}->{FactoidWrite};

	$self->{WriteStore} = new Amethyst::Store(
					Source	=> $self->{Infobot}->{FactoidWrite},
						);

	my @stores = ($self->{WriteStore});
	foreach (@{ $self->{Infobot}->{FactoidRead} }) {
		my $store = new Amethyst::Store(
					Source	=> $_,
						);
		push(@stores, $store);
	}

	$self->{Stores} = \@stores;

	return bless $self, $class;
}

sub forget {
	my ($self, $message, $key) = @_;

	my $filter = qr/./;
	my $msg = undef;
	my $data = undef;

	print STDERR "Forget: $key\n";

	if ($key =~ m,^\s*(.*?)\s+/(.*)/\s*$,) {
		$key = $1;
		$filter = $2;
		print STDERR "Forget: key $key, filter $filter\n";
		eval { "x" =~ m/$filter/ };
		if ($@) {
			my $reply = $self->reply_to($message,
							"Invalid regexp $filter: $@");
			$reply->send;
			return 1;
		}
	}

	my $skey = $self->normalise($key);

	my $store = $self->{WriteStore};

	if ($data = $store->get($skey)) {
		foreach (keys %$data) {
			if (/$filter/) {
				# delete $data->{$_};
				$msg = "I forgot $skey.";
			}
		}
		if (%$data) {
			# $store->set($skey, $data);
		}
		else {
			# $store->unset($skey);
		}
	}

	foreach my $store (@{ $self->{Stores} }) {
		if ($data = $store->get($skey)) {
			foreach (keys %$data) {
				if (/$filter/) {
					$msg ="I have been instructed not to forget " .
							"$skey. It is in readonly store " .
							"$store->{Source}."
									unless $msg;
				}
			}
		}
	}

	unless ($msg) {
		if ($filter) {
			$msg = "I knew nothing about $skey matching $filter.";
		}
		else {
			$msg = "I didn't know about $skey.";
		}
	}

	my $reply = $self->reply_to($message, $msg);
	$reply->send;

	return 1;
}

sub question {
	my ($self, $message, $key) = @_;

	print STDERR "Question: $key\n";

	my $skey = $self->normalise($key);

	my @out;

	foreach my $store (@{ $self->{Stores} }) {

		my $data = $store->get($skey);
		foreach my $sval (keys %$data) {
			my $href = $data->{$sval};
			my $key = $href->{key} || $skey;
			my $val = $href->{val} || $sval;

			my $msg;
			if ($val =~ s/^\s*<reply>\s*//) {
				$msg = $val;
			}
			else {
				$msg = "$key $href->{verb} $val";
			}
			$msg =~ s/\$who\b/$message->user/gex;
			push(@out, ucfirst $msg);
		}
	}

	if (@out) {
		# XXX FIXME better.
		@out = @out[0..9] if @out > 10;
		my $reply = $self->reply_to($message, join(' or ', @out));
		$reply->send;
		return 1;
	}

	return undef;
}

sub statement {
	my ($self, $message, $key, $verb, $val) = @_;

	print STDERR "Statement: $key\n";

	my $store = $self->{WriteStore};

	my $skey = $self->normalise($key);
	my $sval = $self->normalise($val);

	my $data = $store->get($skey);
	if ($data) {
		if ($data->{$sval}) {
			print STDERR "I already knew $key => $val\n";
			return undef;
		}
		print STDERR "I also knew $key as something else\n";
		if ($sval !~ s/^\s*also\s+//) {
			my @ovals = keys %$data;
			my $oval = $ovals[int(rand(@ovals))];
			my $href = $data->{$oval};

			my $okey = $href->{key} || $skey;
			   $oval = $href->{val} || $oval;

			my $msg = "$okey $href->{verb} $oval";
			my $reply = $self->reply_to($message, "But " . $msg);
			$reply->send;
			return 1;
		}
		$val =~ s/^\s*also\s+//i;
	}

	$data->{$sval} = {
		verb	=> $verb,
		user	=> $message->user,
		time	=> time(),
			};
	$data->{$sval}->{key} = $key if $key ne $skey;
	$data->{$sval}->{val} = $val if $val ne $sval;

	$store->set($skey, $data);

	return undef;
}

sub normalise {
	my ($self, $text) = @_;

	$text = lc $text;
	$text =~ s/\s+/ /g;
	$text =~ s/^\s*//;
	$text =~ s/[[:punct:]\s]*$//;

	return $text;
}

sub tidy_key {
	my ($self, $key) = @_;

	print STDERR "K = $key\n";

	$key =~ s/\s+/ /g;

	$key =~ s/^.* that //i;			# $N verbs that X is Y
	$key =~ s/^.* notes? //i;		# $N notes X is Y
	1 while $key =~ s/^\s+(?:$RE_RMKPREFIX)\s+//i;
	1 while $key =~ s/\s+(?:$RE_RMKSUFFIX)\s+$//i;

	$key =~ s/^.*,//;
	$key =~ s/^\s*//;
	$key =~ s/[[:punct:]\s]*$//;

	print STDERR "M = $key\n";

	return $key;
}

sub process {
    my ($self, $message) = @_;

	my $content = $message->content;
	my $who = $message->user;

	$content =~ s/\s+/ /g;

	$content =~ s/\bi am /$1$who is /i; 
	$content =~ s/\bmy /$1$who\'s /ig;
	$content =~ s/\bour /$1$who\'s /ig;
	# $content =~ s/\byour /$1$name\'s /ig;

	$content =~ s/\bisn't /is not /ig;
	$content =~ s/\baren't /are not /ig;

	# if ($content =~ /^forget\s+(?:(?:a|an|the)\s+)?(.*)/i) {
	if ($content =~ /^forget\s+(.*)/i) {
		return $self->forget($message, $1);
	}

	# Modification ignored for now
	if ($content =~ /^($RE_QUESTION)\s+($RE_VERB)\s+(.*)/io){
		return $self->question($message, $1);
	}
	elsif ($content =~ /^(.*?)\s*\?\s*$/) {
		return $self->question($message, $1);
	}

	foreach (split(/(?:[?!:;]|\.\s)/, $content)) {
		s/^\s*\b(?:$RE_RMKPREFIX)\b\s+//i;
		if (/^\s*(.*?)\s+($RE_VERB)\s+(.*)/io) {
			print STDERR "Considering: $_\n";
			my ($key, $verb, $val) = ($1, lc $2, $3);

			$key = $self->tidy_key($key);

			next if length $key > 20;
			next unless $key =~ /\S/;
			next if $key =~ /\b(?:$RE_IGNORE)\b/io;

			$self->statement($message, $key, $verb, $val);
		}
	}

	# forget X
	# X is Y
	# I/you/we am/is/are Y
	# who/what/which/where am/is/are Y

	return undef;
}

1;
