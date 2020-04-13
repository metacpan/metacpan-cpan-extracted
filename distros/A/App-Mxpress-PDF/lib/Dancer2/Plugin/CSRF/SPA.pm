package Dancer2::Plugin::CSRF::SPA;
use 5.010;
use strict;
use warnings;

our $VERSION = '1.01';
use Data::Dumper;
use Dancer2::Plugin;
use Crypt::SaltedHash;
use Data::UUID;

my $HASHER = Crypt::SaltedHash->new( algorithm => 'SHA-1' );
my $UUID = Data::UUID->new();

has session_key_name => (
	is      => 'ro',
	default => sub {
		$_[0]->config->{session_key_name} || 'plugin.csrf';
	}
);

plugin_keywords qw( get_csrf_token validate_csrf_token );

sub get_csrf_token {
	my ($self) = @_;
	my $config = $self->dsl->session( $self->session_key_name() );
	unless ($config) {
		$config = { token => $UUID->create_str(), };
		$self->dsl->session( $self->session_key_name() => $config );
	}
	my $form_url = $self->dsl->request->base;
	my $token = $HASHER->add( $config->{token}, $form_url )->generate();
	$HASHER->clear();
	return $token;
}

sub validate_csrf_token {
	my ( $self, $got_token ) = @_;
	my $form_url = $self->dsl->request->base;
	my $config = $self->dsl->session( $self->session_key_name() ) // return;
	my $expected_token
		= $HASHER->add( $config->{token}, $form_url )->generate();
	$HASHER->clear();
	return $expected_token eq $got_token;
}

1;

__END__
