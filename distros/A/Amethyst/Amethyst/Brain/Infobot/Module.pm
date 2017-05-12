package Amethyst::Brain::Infobot::Module;

use strict;
use Amethyst::Message;

sub new {
	my $class = shift;
	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };

	die "No Name in $class" unless $self->{Name};
	warn "No Description in $class" unless $self->{Description};
	warn "No Usage in $class" unless $self->{Usage};

	if ($class->can('process') ne __PACKAGE__) {
		# Custom process sub;
	}
	elsif ($class->can('action') ne __PACKAGE__) {
		die "No Regex or process subroutine in $class"
						unless $self->{Regex};
	}
	else {
		die "No action subroutine in $class";
	}

	return bless $self, $class;
}

sub init {
	my $self = shift;
}

sub reply_to {
	my ($self, $message, $text) = @_;
	my $reply = $message->reply($text);
	# Unless it's a tell
	# $reply->channel('spam') unless $reply->channel eq CHAN_PRIVATE;
	return $reply;
}

sub action {
	my ($self, $message, @args) = @_;
	print STDERR ref($self) . " does not define 'action'\n";
	return undef;
}

sub process {
	my $self = shift;
	my $message = shift;

	my $re = $self->{Regex};
	unless (defined $re) {
		print STDERR ref($self) ." defines neither Regex nor process\n";
		return undef;
	}

	return undef unless $message->content =~ /$re/;
	print STDERR "Executing brain " . ref($self) . "\n";
	return $self->action($message,
					$1, $2, $3, $4, $5, $6, $7, $8, $9);
}

1;
