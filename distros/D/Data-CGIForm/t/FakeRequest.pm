package t::FakeRequest;

use strict;
use warnings;

sub new {
	my ($class, $data) = @_;
	
	return bless({ %{$data} }, $class);
}

sub param {
	my ($self, $key) = @_;
	
	return unless $self->{$key};
	
	my @ret = ref $self->{$key} ? @{ $self->{$key} } : ($self->{$key});
	
	return wantarray ? @ret : $ret[0];
}

1;
__END__
