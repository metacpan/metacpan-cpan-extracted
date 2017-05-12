package Amethyst::Message;

use strict;
use vars qw(@ISA @EXPORT $AUTOLOAD %VALID);
use Carp;
use Exporter;
use POE;
use Amethyst;

@ISA = qw(Exporter);
@EXPORT = qw(ACT_SAY ACT_EMOTE CHAN_PRIVATE);
%VALID = map { $_ => 1 } qw(
		connection class
		channel user action
		content
			);

sub ACT_SAY		() { 0; }
sub ACT_EMOTE	() { 1; }

sub CHAN_PRIVATE	() { '_tell' }

sub DESTROY { }		# Don't autoload

sub new {
	my $class = shift;
	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };
	$self->{Hints} = { } unless exists $self->{Hints};
	return bless $self, $class;
}

sub AUTOLOAD {
	my $func = $AUTOLOAD;
	$func =~ s/.*:://;
	if ($VALID{$func}) {
		my $key = ucfirst $func;
		eval qq {
			sub $func {
				my \$self = shift;
				\$self->{$key} = \$_[0] if defined \$_[0];
				return \$self->{$key};
			}
		};
		die $@ if $@;
		goto &$AUTOLOAD;
	}
	croak "Could not autoload $AUTOLOAD ($func)";
}

sub action {
	my $self = shift;
	$self->{Action} = $_[0] if defined $_[0];
	return $self->{Action};
}

sub hint {
	my $self = shift;
	$self->{Hints}->{$_[0]} = $_[1] if defined $_[1];
	return $self->{Hints}->{$_[0]};
}

sub send {
	my $self = shift;
	# print STDERR "Sending message to $self->{Connection}\n";
	$poe_kernel->post($self->{Connection}, 'send', $self);
}

sub reply {
	my $self = shift;
	my $content = shift;

	return new Amethyst::Message(
					Connection	=> $self->{Connection},
					Channel		=> $self->{Channel},
					User		=> $self->{User},
					Action		=> ACT_SAY,
					Content		=> $content,
						);
}

1;
