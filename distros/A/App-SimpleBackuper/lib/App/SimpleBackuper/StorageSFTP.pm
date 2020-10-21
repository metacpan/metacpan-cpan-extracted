package App::SimpleBackuper::StorageSFTP;

use strict;
use warnings;
use Try::Tiny;
use Net::SFTP::Foreign;
use Net::SFTP::Foreign::Constants qw(SSH2_FX_CONNECTION_LOST);

sub new {
	my($class, $options) = @_;
	my(undef, $user, $host, $path) = $options =~ /^(([^@]+)@)?([^:]+):(.*)$/;
	
	my $self = bless {user => $user, host => $host, path => $path} => $class;
	$self->_connect();
	
	return $self;
}

sub _connect {
	my($self) = @_;
	
	$self->{sftp} = Net::SFTP::Foreign->new(host => $self->{host}, ($self->{user} ? (user => $self->{user}) : ()), timeout => 30);
	$self->{sftp}->die_on_error("SFTP connect error");
	$self->{sftp}->setcwd($self->{path}) or die "Can't setcwd to '$self->{path}': ".$self->{sftp}->error;
}

sub _do {
	my($self, $method, $params) = @_;
	my $attempts_left = 3;
	my @result;
	while(1) {
		@result = $self->{sftp}->$method(@$params);
		last if @result and defined $result[0];
		if($self->{sftp}->status == SSH2_FX_CONNECTION_LOST and $attempts_left--) {
			print " (".$self->{sftp}->error.", reconnecting)";
			sleep 30;
			try {
				$self->_connect()
			} catch {
				print " (attempt to reconnect failed: $_)";
			};
		} else {
			$self->{sftp}->die_on_error("Can't $method (status=".$self->{sftp}->status.")");
		}
	}
	return \@result;
}

sub put {
	my($self, $name, $content_ref) = @_;
	$self->_do(put_content => [ $$content_ref, $name ]);
	return $self;
}

sub get {
	my($self, $name) = @_;
	return $self->_do(get_content => [ $name ]);
}

sub remove {
	my($self, $name) = @_;
	$self->_do(remove => [ $name ]);
	return $self;
}

sub listing {
	my($self) = @_;
	my $files = $self->_do(ls => [ '' ])->[0];
	return { map {$_->{filename} => $_->{a}->size} grep {$_->{filename} ne '..' and $_->{filename} ne '.'} @$files };
}

1;
