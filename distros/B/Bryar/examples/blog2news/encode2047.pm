package Template::Plugin::encode2047;

use warnings;
use strict;

use Template::Plugin::Filter;
use base 'Template::Plugin::Filter';

use Encode;

sub filter {
	return Encode::encode('MIME-Q', $_[1]);
}

sub init {
	my $self = shift;
	my $name = $self->{_CONFIG}->{name} || 'encode2047';
	$self->install_filter($name);
	return $self;
}

1;
