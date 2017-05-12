package #hide
	AnyEvent::Memcached::Buckets;

use common::sense 2;m{
use strict;
use warnings;
}x;
use Carp;

sub new {
	my $self = bless {}, shift;
	my %args = @_;
	$self->set_servers(delete $args{servers});
	$self;
}

sub set_servers {
	my $self = shift;
	my $list = shift or return;
	$list = [$list] unless ref $list eq 'ARRAY';
	$self->{servers} = $list || [];
	$self->_init_buckets;
	return $self;
}

sub peers {
	my $self = shift;
	@{$self->{servers}} or croak "servers not set during peers";
	$self->{peers};
}

sub _init_buckets {
	my $self = shift;
	@{$self->{servers}} or croak "servers not set during _init_buckets";
	if ($self->{buckets}) {
		@{ $self->{buckets} } = ();
	} else {
		$self->{buckets} = [];
	}
	my $bu = $self->{buckets};
	my $i = 0;
	foreach my $v (@{$self->{servers}}) {
		my $peer;
		my $buck = [ 0+@$bu ];
		if (ref $v eq "ARRAY") {
			$peer = $v->[0];
			for (1..$v->[1]) {
				push @$bu, $v->[0];
			}
			push @$buck, $buck->[0]+1 .. $#$bu;
		} else {
			push @$bu, $peer = $v;
		}
		my ($host,$port) = $peer =~ /^(.+?)(?:|:(\d+))$/;
		if ( exists $self->{peers}{$peer} ) {
			push @{ $self->{peers}{$peer}{bucks} }, @$buck;
		} else {
			push @{ $self->{srv} ||= [] }, $peer;
			$self->{peers}{$peer} = {
				index => $#{ $self->{srv} },
				bucks => $buck,
				host  => $host,
				port  => $port,
			};
		}
	}
	return;
}


sub peer {
	my $self = shift;
	my $hash = shift;
	@{$self->{servers}} or croak "servers not set during peer";
	return $self->{buckets}[ $hash % @{ $self->{buckets} } ];
}

sub next {
	my $self = shift;
	my $srv  = shift;
	@{$self->{servers}} or croak "servers not set during next";
	my $peer = $self->{peers}{$srv} or croak "No such server in buckets: $srv";
	my %args = @_;
	my $by = $args{by} || 1;
	my $next = ( $peer->{index} + $by ) % @{$self->{srv}};
	my $nsrv = $self->{srv}[$next] or die "Cant find next server by index $next";
	$nsrv = $nsrv->[0] if ref $nsrv;
	#warn R::Dump($nsrv);
	if ( ( my @bucks = @{ $self->{peers}{$nsrv}{bucks} } ) > 1 ) {
		my $which = $bucks[ ( $args{hash} || 0 ) % @bucks ];
		#warn "many buckets (@bucks) for $nsrv. using $which ($self->{buckets}[ $which ])";
		return $self->{buckets}[ $which ];
	} else {
		return $nsrv;
	}
}
sub prev {
	my $self = shift;
	my $srv  = shift;
	my %args = @_;
	my $by = $args{by} || 1;
	$self->next( $srv, %args, by => @{$self->{srv}}-$by );
}

1;
