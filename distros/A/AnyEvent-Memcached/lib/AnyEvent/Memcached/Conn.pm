package #hide
	AnyEvent::Memcached::Conn;

use common::sense 2;m{
use strict;
use warnings;
}x;
use base 'AnyEvent::Connection::Raw';
use AnyEvent::Memcached;
use AnyEvent::Connection::Util;

our $NL = "\015\012";
our $QRNL = qr<\015?\012>;
our $VERSION = $AnyEvent::Memcached::VERSION;

sub reader {
	my ($self,%args) = @_;
	$args{cb} or return $self->event( error => "no cb for command at @{[ (caller)[1,2] ]}" );
	$self->{h} or return $args{cb}->(undef,"Not connected");
	my $result = $args{res} || {};
	my $ar = ref $result eq 'ARRAY' ? 1 : 0;
	my $cut = exists $args{namespace} ? length $args{namespace} : 0;
	my $reader;$reader = sub {
		shift;
		defined( local $_ = shift ) or return $args{cb}(undef,@_);
		warn "<<$args{id} $_" if $self->{debug};
		if ($_ eq "END") {
			undef $reader;
			$args{cb}( $result );
		}
		elsif (substr($_,0,5) eq 'ERROR') {
			undef $reader;
			$args{cb}( undef, $_ );
		}
		elsif (!length) {
			warn "Skip empty line";
			$self->{h}->unshift_read( line => $reader);
		}
		elsif( /^VALUE (\S+) (\d+) (\d+)(?:| (.+))$/ ) {
			my ($key,$flags,$len,$cas) = ($1,$2,$3,$4);
			#warn "have to read $1 $2 $3 $4";
			$self->recv( $3+2 => cb => sub {
				#shift;
				my $data = shift;
				substr($data,$len) = ''; # trim out data outside length
				#$data = substr($data,0,length($data)-2);
				$key = substr($key, $cut) if substr($key, 0, $cut) eq $args{namespace};
				warn "+ received data $key: $data" if $self->{debug};
				my $v = {
					data => $data,
					flags => $flags,
					defined $cas ? (cas => $cas) : (),
				};
				if ($ar) {
					push @$result, $key, $v;
				} else {
					$result->{$key} = $v;#{ data => $data, $cas ? (cas => $cas) : () };
				}
				
				$self->{h}->unshift_read( line => $reader);
			});
		}
		else {
			die "Wrong data received: ".dumper($_)."($!)";
			#$args{cb}(undef,$_);
			#$self->handle_errors($_);
		}
	};
	$self->{h}->push_read( line => $reader );
}


1;

1;
