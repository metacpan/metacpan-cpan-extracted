use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Test::Request;
use base 'HTML::Tested::Test::Request';
use Carp;

sub unparsed_uri { return shift()->uri; }
sub pool { return shift; }
sub prev { return shift; }
sub headers_in { return { Referer => 'hihi.haha' } }

sub cleanup_register {
	my ($self, $func) = @_;
	push @{ $self->{cleanups} }, $func;
}

sub run_cleanups {
	my $self = shift;
	$_->() for @{ $self->{cleanups} };
}

sub get_server_port { return 80; }
sub get_server_name { return "some.host"; }

sub log_error {
	my ($self, $err) = @_;
	confess $err;
}

1;
